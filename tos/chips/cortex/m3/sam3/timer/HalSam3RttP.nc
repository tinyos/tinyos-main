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
