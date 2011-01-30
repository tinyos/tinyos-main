/* ----------------------------------------------------------------------------
 *         ATMEL Microcontroller Software Support 
 * ----------------------------------------------------------------------------
 * Copyright (c) 2008, Atmel Corporation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holders nor the names of its
 *   contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
 * AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 * WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 * ----------------------------------------------------------------------------
 */

//------------------------------------------------------------------------------
/// \unit
///
/// !!!Purpose
/// 
/// Collection of methods for using the USB device controller on AT91
/// microcontrollers.
/// 
/// !!!Usage
/// 
/// Please refer to the corresponding application note.
/// - "AT91 USB device framework"
/// - "USBD API" . "USBD API Methods"
//------------------------------------------------------------------------------

#ifndef USBD_H
#define USBD_H

//------------------------------------------------------------------------------
//         Headers
//------------------------------------------------------------------------------

#include <usb/common/core/USBEndpointDescriptor.h>
#include <usb/common/core/USBGenericRequest.h>

//------------------------------------------------------------------------------
//      Definitions
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
/// \page "USB device API return values"
///
/// This page lists the return values of the USB %device driver API
///
/// !Return codes
/// - USBD_STATUS_SUCCESS
/// - USBD_STATUS_LOCKED
/// - USBD_STATUS_ABORTED
/// - USBD_STATUS_RESET
           
/// Indicates the operation was successful.
#define USBD_STATUS_SUCCESS             0
/// Endpoint/device is already busy.
#define USBD_STATUS_LOCKED              1
/// Operation has been aborted.
#define USBD_STATUS_ABORTED             2
/// Operation has been aborted because the device has been reset.
#define USBD_STATUS_RESET               3
/// Operation failed because parameter error
#define USBD_STATUS_INVALID_PARAMETER   4
/// Operation failed because HW not supported
#define USBD_STATUS_HW_NOT_SUPPORTED    5
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
/// \page "USB device states"
///
/// This page lists the %device states of the USB %device driver.
///
/// !States
/// - USBD_STATE_SUSPENDED
/// - USBD_STATE_ATTACHED
/// - USBD_STATE_POWERED
/// - USBD_STATE_DEFAULT
/// - USBD_STATE_ADDRESS
/// - USBD_STATE_CONFIGURED

/// The device is currently suspended.
#define USBD_STATE_SUSPENDED            0
/// USB cable is plugged into the device.
#define USBD_STATE_ATTACHED             1
/// Host is providing +5V through the USB cable.
#define USBD_STATE_POWERED              2
/// Device has been reset.
#define USBD_STATE_DEFAULT              3
/// The device has been given an address on the bus.
#define USBD_STATE_ADDRESS              4
/// A valid configuration has been selected.
#define USBD_STATE_CONFIGURED           5
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
/// \page "USB device LEDs"
///
/// This page lists the LEDs used in the USB %device driver.
///
/// !LEDs
/// - USBD_LEDPOWER
/// - USBD_LEDUSB
/// - USBD_LEDOTHER

/// LED for indicating that the device is powered.
#define USBD_LEDPOWER                   0
/// LED for indicating USB activity.
#define USBD_LEDUSB                     1
/// LED for custom usage.
#define USBD_LEDOTHER                   2
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//         Types
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
/// Callback used by transfer functions (USBD_Read & USBD_Write) to notify
/// that a transaction is complete.
//------------------------------------------------------------------------------
typedef void (*TransferCallback)(void *pArg,
                                 unsigned char status,
                                 unsigned int transferred,
                                 unsigned int remaining);

//------------------------------------------------------------------------------
//         Exported functions
//------------------------------------------------------------------------------

extern void UDPD_IrqHandler(void);

extern void USBD_Init(void);

extern void USBD_ConfigureSpeed(unsigned char forceFS);

extern void USBD_Connect(void);

extern void USBD_Disconnect(void);

extern char USBD_Write(
    unsigned char bEndpoint,
    const void *pData,
    unsigned int size,
    TransferCallback callback,
    void *pArg);

extern char USBD_Read(
    unsigned char bEndpoint,
    void *pData,
    unsigned int dLength,
    TransferCallback fCallback,
    void *pArg);

extern unsigned char USBD_Stall(unsigned char bEndpoint);

extern void USBD_Halt(unsigned char bEndpoint);

extern void USBD_Unhalt(unsigned char bEndpoint);

extern void USBD_ConfigureEndpoint(const USBEndpointDescriptor *pDescriptor);

extern unsigned char USBD_IsHalted(unsigned char bEndpoint);

extern void USBD_RemoteWakeUp(void);

extern void USBD_SetAddress(unsigned char address);

extern void USBD_SetConfiguration(unsigned char cfgnum);

extern unsigned char USBD_GetState(void);

extern unsigned char USBD_IsHighSpeed(void);

extern void USBD_Test(unsigned char bIndex);

#endif //#ifndef USBD_H

