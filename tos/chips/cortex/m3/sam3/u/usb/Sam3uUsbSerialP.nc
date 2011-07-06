/*
 * Copyright (c) 2010 CSIRO Australia
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without 
 * modification, are permitted provided that the following conditions 
 * are met: 
 * 
 * - Redistributions of source code must retain the above copyright 
 *   notice, this list of conditions and the following disclaimer. 
 * - Redistributions in binary form must reproduce the above copyright 
 *   notice, this list of conditions and the following disclaimer in the 
 *   documentation and/or other materials provided with the 
 *   distribution. 
 * - Neither the name of the copyright holders nor the names of 
 *   its contributors may be used to endorse or promote products derived 
 *   from this software without specific prior written permission. 
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL 
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES 
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR 
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, 
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED 
 * OF THE POSSIBILITY OF SUCH DAMAGE. 
 */

/**
 * High Speed USB to Serial implementation
 *
 * @author Kevin Klues
 */

#include <sam3uudphshardware.h>

module Sam3uUsbSerialP {
  provides {
    interface Init;
    interface StdControl;
    interface UartStream;
  } 
  uses {
    interface HplNVICInterruptCntl as UDPHSInterrupt;
    interface HplSam3PeripheralClockCntl as UDPHSClockControl;
    interface FunctionWrapper as UdphsInterruptWrapper;
  }
}
implementation {
  #include <board.h>
  #include <board_lowlevel.c>
  #include <peripherals/pio/pio_it.c>
  #include <peripherals/irq/nvic.c>
  #include <usb/common/cdc/CDCLineCoding.c>
  #include <usb/common/cdc/CDCSetControlLineStateRequest.c>
  #include <usb/common/core/USBInterfaceRequest.c>
  #include <usb/common/core/USBGetDescriptorRequest.c>
  #include <usb/common/core/USBSetAddressRequest.c>
  #include <usb/common/core/USBFeatureRequest.c>
  #include <usb/common/core/USBGenericRequest.c>
  #include <usb/common/core/USBEndpointDescriptor.c>
  #include <usb/common/core/USBSetConfigurationRequest.c>
  #include <usb/common/core/USBGenericDescriptor.c>
  #include <usb/common/core/USBConfigurationDescriptor.c>
  #include <usb/device/core/USBDCallbacks_Reset.c>
  #include <usb/device/core/USBDDriverCb_IfSettingChanged.c>
  #include <usb/device/core/USBD_OTGHS.c>
  #include <usb/device/core/USBDDriverCb_CfgChanged.c>
  #include <usb/device/core/USBD_UDPHS.c>
  #include <usb/device/core/USBDCallbacks_Initialized.c>
  #include <usb/device/core/USBD_UDP.c>
  #include <usb/device/core/USBDDriver.c>
  #include <usb/device/cdc-serial/CDCDSerialDriver.c>
  #include <usb/device/cdc-serial/CDCDSerialDriverDescriptors.c>

  norace struct {
    volatile bool rlock   : 1;
    volatile bool wlock   : 1;
  } flags;

  norace uint8_t* rbuf;
  norace uint8_t* wbuf;
  norace uint16_t rlen;
  norace uint16_t wlen;

  //------------------------------------------------------------------------------
  //         Callbacks re-implementation
  //------------------------------------------------------------------------------
  //------------------------------------------------------------------------------
  /// Invoked when the USB device leaves the Suspended state. By default,
  /// configures the LEDs.
  //------------------------------------------------------------------------------
  void USBDCallbacks_Resumed(void) @spontaneous()
  {
  }
  
  //------------------------------------------------------------------------------
  /// Invoked when the USB device gets suspended. By default, turns off all LEDs.
  //------------------------------------------------------------------------------
  void USBDCallbacks_Suspended(void) @spontaneous()
  {
  }

  //------------------------------------------------------------------------------
  /// Callback invoked when data has been received on the USB.
  //------------------------------------------------------------------------------
  void UsbDataReceived(unsigned int unused,
                       unsigned char status,
                       unsigned int received,
                       unsigned int remaining) @spontaneous()
  {
    int i;
    error_t e = (status == USBD_STATUS_SUCCESS) ? SUCCESS : FAIL;
    flags.rlock = 0;
    for(i=0; i<received; i++)
      signal UartStream.receivedByte(rbuf[i]);
    signal UartStream.receiveDone(rbuf, received, e);
  }
  
  //------------------------------------------------------------------------------
  /// Callback invoked when data has been written on the USB.
  //------------------------------------------------------------------------------
  void UsbDataWritten(unsigned int unused,
                      unsigned char status,
                      unsigned int written,
                      unsigned int remaining) @spontaneous()
  {
    error_t e = (status == USBD_STATUS_SUCCESS) ? SUCCESS : FAIL;
    flags.wlock = 0;
    signal UartStream.sendDone(wbuf, written, e);
  }

  command error_t Init.init() {
    // Set the Interrupt Priority
    call UDPHSInterrupt.configure(IRQ_PRIO_UDPHS);

    flags.rlock = 0;
    flags.wlock = 0;

    return SUCCESS;
  }

  command error_t StdControl.start() {
    // Enable the UDPHS clock in the PMC
    call UDPHSClockControl.enable();

    // Enable the UPLL
    PMC->uckr.bits.upllcount = 1; // Arbitrary for now...
    PMC->uckr.bits.upllen = 1;
    while(!PMC->sr.bits.locku);

    // Enable udphs
    UDPHS->ctrl.bits.en_udphs = 1;

    // BOT driver initialization
    CDCDSerialDriver_Initialize();
    // Connect pull-up, wait for configuration
    USBD_Connect();

    return SUCCESS;
  }

  command error_t StdControl.stop() {
    // Disable the UDPHS clock in the PMC
    call UDPHSClockControl.disable();

    // Disable the UPLL
    PMC->uckr.bits.upllen = 0;

    // Disabel udphs
    UDPHS->ctrl.bits.en_udphs = 0;
    return SUCCESS;
  }

  async command error_t UartStream.send( uint8_t* buf, uint16_t len ) {
    int e;
    if(flags.wlock)
      return EBUSY;

    flags.wlock = 1;
    wbuf = buf;
    wlen = len;
    e = CDCDSerialDriver_Write(wbuf, wlen, (TransferCallback) UsbDataWritten, 0);
    if (e != USBD_STATUS_SUCCESS) {
      flags.wlock = 0;
      return FAIL;
    }
    return SUCCESS;
  }

  async command error_t UartStream.receive( uint8_t* buf, uint16_t len ) {
    int e;
    if(flags.rlock)
      return EBUSY;

    flags.rlock = 1;
    rbuf = buf;
    rlen = len;
    e = CDCDSerialDriver_Read(rbuf, rlen, (TransferCallback) UsbDataReceived, 0);
    if (e != USBD_STATUS_SUCCESS) {
      flags.rlock = 0;
      return FAIL;
    }
    return SUCCESS;
  }

  async command error_t UartStream.enableReceiveInterrupt() {
    return SUCCESS;
  }

  async command error_t UartStream.disableReceiveInterrupt() {
    return FAIL;
  }
}

