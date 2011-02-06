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
 * Interface to control and query the SAM3 SPI interrupts.
 *
 * @author Thomas Schmid
 */

interface HplSam3SpiInterrupts
{
    async event void receivedData(uint16_t data);

    async command void disableAllSpiIrqs();

    async command void enableRxFullIrq();
    async command void disableRxFullIrq();
    async command bool isEnabledRxFullIrq();

    async command void enableTxDataEmptyIrq();
    async command void disableTxDataEmptyIrq();
    async command bool isEnabledTxDataEmptyIrq();

    async command void enableModeFaultIrq();
    async command void disableModeFaultIrq();
    async command bool isEnabledModeFaultIrq();

    async command void enableOverrunIrq();
    async command void disableOverrunIrq();
    async command bool isEnabledOverrunIrq();

    async command void enableNssRisingIrq();
    async command void disableNssRisingIrq();
    async command bool isEnabledNssRisingIrq();

    async command void enableTxEmptyIrq();
    async command void disableTxEmptyIrq();
    async command bool isEnabledTxEmptyIrq();

    async command void enableUnderrunIrq();
    async command void disableUnderrunIrq();
    async command bool isEnabledUnderrunIrq();
}

