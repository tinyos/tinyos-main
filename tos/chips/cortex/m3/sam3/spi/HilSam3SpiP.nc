/**
 * Copyright (c) 2009 The Regents of the University of California.
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
 */

/**
 * SPI implementation for the SAM3U chip. Does not use DMA (PDC) at this
 * point. Byte interface performs busy wait!
 *
 * @author Thomas Schmid
 * @author Kevin Klues
 */

#include "sam3spihardware.h"

module HilSam3SpiP
{
    provides
    {
        interface Init;
        interface SpiByte[uint8_t];
        interface SpiPacket[uint8_t];
    }
    uses
    {
        interface Init as SpiChipInit;
        interface ArbiterInfo;
        interface HplSam3SpiConfig;
        interface HplSam3SpiControl;
        interface HplSam3SpiInterrupts;
        interface HplSam3SpiStatus;
        interface HplNVICInterruptCntl as SpiIrqControl;
        interface HplSam3GeneralIOPin as SpiPinMiso;
        interface HplSam3GeneralIOPin as SpiPinMosi;
        interface HplSam3GeneralIOPin as SpiPinSpck;
    }
}
implementation
{

    void signalDone();
    task void signalDone_task();

    uint8_t* globalTxBuf;
    uint8_t* globalRxBuf;
    uint16_t globalLen;

    command error_t Init.init()
    {
        // turn off all interrupts
        call HplSam3SpiInterrupts.disableAllSpiIrqs();

        // configure NVIC
        call SpiIrqControl.configure(IRQ_PRIO_SPI);
        call SpiIrqControl.enable();

        // configure PIO
        call SpiPinMiso.disablePioControl();
        call SpiPinMiso.selectPeripheralA();
        call SpiPinMosi.disablePioControl();
        call SpiPinMosi.selectPeripheralA();
        call SpiPinSpck.disablePioControl();
        call SpiPinSpck.selectPeripheralA();

        // reset the SPI configuration
        call HplSam3SpiControl.resetSpi();

        // configure for master
        call HplSam3SpiConfig.setMaster();

        // chip select options
        call HplSam3SpiConfig.setFixedCS(); // CS needs to be configured for each message sent!
        //call HplSam3SpiConfig.setVariableCS(); // CS needs to be configured for each message sent!
        call HplSam3SpiConfig.setDirectCS(); // CS pins are not multiplexed

        call SpiChipInit.init();
        return SUCCESS;
    }

    async command uint8_t SpiByte.write[uint8_t device]( uint8_t tx)
    {
        uint8_t byte;
        if(!(call ArbiterInfo.userId() == device))
            return -1;
        
        //call HplSam3SpiChipSelConfig.enableCSActive();
        call HplSam3SpiStatus.setDataToTransmit(tx);
        while(!call HplSam3SpiStatus.isRxFull());
        byte = (uint8_t)call HplSam3SpiStatus.getReceivedData();

        return byte;
    }

    async command error_t SpiPacket.send[uint8_t device](uint8_t* txBuf, uint8_t* rxBuf, uint16_t len)
    {
        uint16_t m_len = len;
        uint16_t m_pos = 0;

        if(!(call ArbiterInfo.userId() == device))
            return -1;

        if(len)
        {
            while( m_pos < len) 
            {
                /**
                 * FIXME: in order to be compatible with the general TinyOS
                 * Spi Interface, we can't do automatic CS control!!!
                if(m_pos == len-1)
                    call HplSam3SpiStatus.setDataToTransmitCS(txBuf[m_pos], 3, TRUE);
                else
                    call HplSam3SpiStatus.setDataToTransmitCS(txBuf[m_pos], 3, FALSE);
                */
                /*
                call HplSam3SpiStatus.setDataToTransmitCS(txBuf[m_pos], device, FALSE);

                while(!call HplSam3SpiStatus.isRxFull());
                rxBuf[m_pos] = (uint8_t)call HplSam3SpiStatus.getReceivedData();
                */
                rxBuf[m_pos] = (uint8_t)call SpiByte.write[device](txBuf[m_pos]);
                m_pos += 1;
            }
        }
        atomic {
            globalRxBuf = rxBuf;
            globalTxBuf = txBuf;
            globalLen = m_len;
        }
        post signalDone_task();
        //atomic signal SpiPacket.sendDone(txBuf, rxBuf, m_len, SUCCESS);
        return SUCCESS;
    }

    task void signalDone_task() {
      atomic signalDone();
    }


    void signalDone() {
        uint8_t device = call ArbiterInfo.userId();
        signal SpiPacket.sendDone[device](globalTxBuf, globalRxBuf, globalLen, SUCCESS);
    }


    default async event void SpiPacket.sendDone[uint8_t device](uint8_t* tx_buf, 
                                    uint8_t* rx_buf, uint16_t len, error_t error) {}

    async event void HplSam3SpiInterrupts.receivedData(uint16_t data) {};
}

