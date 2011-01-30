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
    }
    uses {
      interface FunctionWrapper as TC0InterruptWrapper;
      interface FunctionWrapper as TC1InterruptWrapper;
      interface FunctionWrapper as TC2InterruptWrapper;
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

    default async event void TC0Event.fired() {}
    default async event void TC1Event.fired() {}
    default async event void TC2Event.fired() {}
}

