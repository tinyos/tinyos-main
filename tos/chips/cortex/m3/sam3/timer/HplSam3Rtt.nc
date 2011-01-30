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
