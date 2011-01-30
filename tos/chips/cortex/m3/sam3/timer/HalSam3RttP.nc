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
 * Provides an alarm, counter, and local time with TMilli resolution using the
 * SAM3's RTT.
 *
 * @author Thomas Schmid
 */

module HalSam3RttP @safe()
{
    provides {
        interface Init;
        interface Alarm<TMilli,uint32_t> as Alarm;
        interface LocalTime<TMilli> as LocalTime;
    }
    uses {
        interface HplSam3Rtt;
        interface Init as RttInit;
    }
}

implementation
{
    bool running;

    command error_t Init.init()
    {
        running = FALSE;

        call RttInit.init();
        // make the counter count in milliseconds. This restarts the RTT and
        // resets the counter.
        call HplSam3Rtt.setPrescaler(32);
        return SUCCESS;
    }

    async command void Alarm.start(uint32_t dt)
    {
        atomic running = TRUE;
        call Alarm.startAt(call Alarm.getNow(), dt);
    }

    async command void Alarm.stop()
    {
        atomic running = FALSE;
        call HplSam3Rtt.disableAlarmInterrupt();
    }

    async command bool Alarm.isRunning()
    {
        return running;
    }

    async command void Alarm.startAt( uint32_t t0, uint32_t dt)
    {
        atomic {
            uint32_t now = call Alarm.getNow();
            uint32_t elapsed = now-t0;
            if(elapsed >= dt )
            {
                // l.et the timer expire at the next tic of the RTT
                call HplSam3Rtt.setAlarm(now+1);
            } else {
                uint32_t remaining = dt - elapsed;
                if(remaining <= 1)
                {
                    call HplSam3Rtt.setAlarm(now + 1);
                } else {
                    call HplSam3Rtt.setAlarm(now + remaining);
                }
            }
            call HplSam3Rtt.enableAlarmInterrupt();
        }
    }

    async command uint32_t Alarm.getNow()
    {
        uint32_t c;
        c = call HplSam3Rtt.getTime();
        return c;
    }

    async command uint32_t Alarm.getAlarm()
    {
        uint32_t c;
        c = call HplSam3Rtt.getAlarm();
        return c;
    }

    async command uint32_t LocalTime.get()
    {
        return call Alarm.getNow();
    }

    async event void HplSam3Rtt.alarmFired() 
    {
        call Alarm.stop();
	call HplSam3Rtt.disableAlarmInterrupt();
        signal Alarm.fired();
    }

    async event void HplSam3Rtt.incrementFired()
    {
    }

}
