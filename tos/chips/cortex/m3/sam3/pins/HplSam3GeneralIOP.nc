/**
 * "Copyright (c) 2009 The Regents of the University of California.
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
