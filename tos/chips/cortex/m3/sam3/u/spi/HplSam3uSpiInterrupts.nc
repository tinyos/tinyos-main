/**
 * "Copyright (c) 2009 The Regents of the University of California.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

/**
 * Interface to control and query the SAM3U SPI interrupts.
 *
 * @author Thomas Schmid
 */

interface HplSam3uSpiInterrupts
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

