/*
 * Copyright (c) 2009 The Regents of the University of California.
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
 * - Neither the name of the University of California nor the names of
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
 * @author Thomas Schmid
 * @author Kevin Klues <kevin.klues@csiro.au>
 */

// Chip specific include that defines the RTT variable
#include "sam3rtthardware.h"

module HplSam3RttP @safe()
{
    provides {
        interface Init;
        interface HplSam3Rtt;
    }
    uses {
        interface HplNVICCntl;
        interface HplNVICInterruptCntl as NVICRTTInterrupt;
        interface FunctionWrapper as RttInterruptWrapper;
	interface Leds;
    }
}
implementation
{
    command error_t Init.init()
    {
        call NVICRTTInterrupt.configure(0);
        // now enable the IRQ
        call NVICRTTInterrupt.enable();
        return SUCCESS;
    }

    /**
     * Sets the prescaler value of the RTT and restart it. This function
     * disables all interrupt sources!
     */
    async command error_t HplSam3Rtt.setPrescaler(uint16_t prescaler)
    {
        rtt_mr_t mr = RTT->mr;
        // after changing the prescaler, we have to restart the RTT
        mr.bits.rtpres = prescaler;
        RTT->mr = mr;
        return call HplSam3Rtt.restart();
    }

    async command uint32_t HplSam3Rtt.getTime()
    {
        return RTT->vr;
    }

    async command error_t HplSam3Rtt.enableAlarmInterrupt()
    {
        rtt_mr_t mr = RTT->mr;
        mr.bits.almien = 1;;
        RTT->mr = mr;
        return SUCCESS;
    }

    async command error_t HplSam3Rtt.disableAlarmInterrupt()
    {
        rtt_mr_t mr = RTT->mr;
        mr.bits.almien = 0;
        RTT->mr = mr;
        return SUCCESS;
    }

    async command error_t HplSam3Rtt.enableIncrementalInterrupt()
    {
        rtt_mr_t mr = RTT->mr;
        mr.bits.rttincien = 1;
        RTT->mr = mr;
        return SUCCESS;
    }

    async command error_t HplSam3Rtt.disableIncrementalInterrupt()
    {
        rtt_mr_t mr = RTT->mr;
        mr.bits.rttincien = 0;
        RTT->mr = mr;
        return SUCCESS;
    }

    async command error_t HplSam3Rtt.restart()
    {
        rtt_mr_t mr = RTT->mr;
        mr.bits.rttrst = 1;
        RTT->mr = mr;
        return SUCCESS;
    }

    async command error_t HplSam3Rtt.setAlarm(uint32_t time)
    {
        if(time > 0)
        {
            RTT->ar = time - 1;
            return SUCCESS;
        } else {
            return FAIL;
        }
    }

    async command uint32_t HplSam3Rtt.getAlarm()
    {
        return RTT->ar;
    }

    void RttIrqHandler() @C() @spontaneous()
    {
        rtt_sr_t status;

        call RttInterruptWrapper.preamble();
        atomic {
            //PMC->pc.pcer.bits.tc2 = 1; // FIXME: what is this????
            // clear pending interrupt
            call NVICRTTInterrupt.clearPending();

            status = RTT->sr;

            if (status.bits.rttinc) {
                // we got an increment interrupt
                signal HplSam3Rtt.incrementFired();
            }

            if (status.bits.alms) {
                // we got an alarm
                //call Leds.led2Toggle();
                signal HplSam3Rtt.alarmFired();
            }
        }
        call RttInterruptWrapper.postamble();
    }

    default async event void HplSam3Rtt.incrementFired() {}
    default async event void HplSam3Rtt.alarmFired() {}

}

