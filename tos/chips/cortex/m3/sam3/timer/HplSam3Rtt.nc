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
 * HPL interface for the SAM3 Real-Time Timer.
 *
 * @author Thomas Schmid
 */

interface HplSam3Rtt {

    /**
     * Sets the prescaler value of the RTT and restart it. This function
     * disables all interrupt sources!
     *
     * @par prescaler 16-bit prescaler for the counter. The RTT is fed by a
     * 32.768 Hz clock.
     */
    async command error_t setPrescaler(uint16_t prescaler);

    /**
     * Retrieves the current time of the timer.
     *
     * @return The 32-bit counter value.
     */
    async command uint32_t getTime();

    /**
     * Enables the alarm interrupt of the RTT.
     */
    async command error_t enableAlarmInterrupt();

    /**
     * Disables the alarm interrupt of the RTT.
     */
    async command error_t disableAlarmInterrupt();

    /**
     * Enables the incremental interrupt of the RTT. 
     */
    async command error_t enableIncrementalInterrupt();

    /**
     * Disables the incremental interrupt of the RTT.
     */
    async command error_t disableIncrementalInterrupt();

    /**
     * Restart the RTT and resets the counter value.
     */
    async command error_t restart();

    /**
     * Set the alarm for the RTT.
     *
     * @par time The 32-bit time value at which the alarm interrupt should
     * happen.
     */
    async command error_t setAlarm(uint32_t time);

    /**
     * Returns the current alarm time.
     */
    async command uint32_t getAlarm();

    /**
     * Event indicating that the increment interrupt fired.
     */
    async event void incrementFired();

    /**
     * Event indicating that the alarm interrupt fired.
     */
    async event void alarmFired();

}
