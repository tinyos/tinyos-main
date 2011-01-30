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
 * This module is only used to dispatch the IRQ to the correct module.
 * @author Thomas Schmid
 */

module HplSam3GeneralIOP
{
    provides
    {
        interface HplSam3GeneralIOPort as HplPortA;
        interface HplSam3GeneralIOPort as HplPortB;
        interface HplSam3GeneralIOPort as HplPortC;
    }
    uses 
    {
        interface FunctionWrapper as PioAInterruptWrapper;
        interface FunctionWrapper as PioBInterruptWrapper;
        interface FunctionWrapper as PioCInterruptWrapper;
    }
}
implementation
{
    __attribute__((interrupt)) void PioAIrqHandler() @C() @spontaneous()
    {
        uint32_t time = 0;
        call PioAInterruptWrapper.preamble();
        signal HplPortA.fired(time);
        call PioAInterruptWrapper.postamble();
    }

    __attribute__((interrupt)) void PioBIrqHandler() @C() @spontaneous()
    {
        uint32_t time = 0;
        call PioBInterruptWrapper.preamble();
        signal HplPortB.fired(time);
        call PioBInterruptWrapper.postamble();
    }

    __attribute__((interrupt)) void PioCIrqHandler() @C() @spontaneous()
    {
        uint32_t time = 0;
        call PioCInterruptWrapper.preamble();
        signal HplPortC.fired(time);
        call PioCInterruptWrapper.postamble();
    }

    /**
     * Does nothing!
     */
    async command void HplPortA.enableInterrupt()
    {
    }
    async command void HplPortA.disableInterrupt()
    {
    }
    async command void HplPortA.enableClock()
    {
    }
    async command void HplPortA.disableClock()
    {
    }

    /**
     * Does nothing!
     */
    async command void HplPortB.enableInterrupt()
    {
    }
    async command void HplPortB.disableInterrupt()
    {
    }
    async command void HplPortB.enableClock()
    {
    }
    async command void HplPortB.disableClock()
    {
    }

    /**
     * Does nothing!
     */
    async command void HplPortC.enableInterrupt()
    {
    }
    async command void HplPortC.disableInterrupt()
    {
    }
    async command void HplPortC.enableClock()
    {
    }
    async command void HplPortC.disableClock()
    {
    }

    default async event void HplPortA.fired(uint32_t time) {}
    default async event void HplPortB.fired(uint32_t time) {}
    default async event void HplPortC.fired(uint32_t time) {}
}
