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
 * SAM3U TC Event dispatcher.
 *
 * @author Thomas Schmid
 */

#include "sam3tchardware.h"

module HplSam3TCEventP @safe()
{
    provides {
        interface HplSam3TCEvent as TC0Event;
        interface HplSam3TCEvent as TC1Event;
        interface HplSam3TCEvent as TC2Event;
        interface HplSam3TCEvent as TC3Event;
        interface HplSam3TCEvent as TC4Event;
        interface HplSam3TCEvent as TC5Event;
    }
    uses {
      interface FunctionWrapper as TC0InterruptWrapper;
      interface FunctionWrapper as TC1InterruptWrapper;
      interface FunctionWrapper as TC2InterruptWrapper;
      interface FunctionWrapper as TC3InterruptWrapper;
      interface FunctionWrapper as TC4InterruptWrapper;
      interface FunctionWrapper as TC5InterruptWrapper;
    }
}
implementation
{

    void TC0IrqHandler() @C() @spontaneous() 
    {
        call TC0InterruptWrapper.preamble();
        signal TC0Event.fired();
        call TC0InterruptWrapper.postamble();
    }

    void TC1IrqHandler() @C() @spontaneous() 
    {
        call TC1InterruptWrapper.preamble();
        signal TC1Event.fired();
        call TC1InterruptWrapper.postamble();
    }

    void TC2IrqHandler() @C() @spontaneous() 
    {
        call TC2InterruptWrapper.preamble();
        signal TC2Event.fired();
        call TC2InterruptWrapper.postamble();
    }

    void TC3IrqHandler() @C() @spontaneous() 
    {
        call TC3InterruptWrapper.preamble();
        signal TC3Event.fired();
        call TC3InterruptWrapper.postamble();
    }

    void TC4IrqHandler() @C() @spontaneous() 
    {
        call TC4InterruptWrapper.preamble();
        signal TC4Event.fired();
        call TC4InterruptWrapper.postamble();
    }

    void TC5IrqHandler() @C() @spontaneous() 
    {
        call TC5InterruptWrapper.preamble();
        signal TC5Event.fired();
        call TC5InterruptWrapper.postamble();
    }

    default async event void TC0Event.fired() {}
    default async event void TC1Event.fired() {}
    default async event void TC2Event.fired() {}
    default async event void TC3Event.fired() {}
    default async event void TC4Event.fired() {}
    default async event void TC5Event.fired() {}
}

