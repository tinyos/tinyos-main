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
 * SAM3U TC Channel interface.
 *
 * @author Thomas Schmid
 */

interface HplSam3TCChannel
{
    async command uint16_t get();
    async command bool isOverflowPending();
    async command void clearOverflow();
    async event void overflow();

    /**
     * FIXME: this currently only selects between wave mode or non-wave mode.
     * This should be extended to all the different posibilities of modes!
     *
     * allowed arguments:
     *   TC_CMR_WAVE: selects wave mode. Allows compare on A, B, and C or wave
     *                generation
     *   TC_CMR_CAPTURE: selects capture mode (disables wave mode!). Allows
     *                   capture on A, B, and compare on C. (DEFAULT)
     */
    async command void setMode(uint8_t mode);

    async command uint8_t getMode();

    async command void enableEvents();
    async command void disableEvents();
    async command void enableClock();
    async command void disableClock();

    /**
     * Allowed clock sources:
     * TC_CMR_CLK_TC1: selects MCK/2 
     * TC_CMR_CLK_TC2: selects MCK/8
     * TC_CMR_CLK_TC3: selects MCK/32
     * TC_CMR_CLK_TC4: selects MCK/128
     * TC_CMR_CLK_SLOW: selects SLCK. if MCK=SLCK, then this clock will be
     *                  modified by PRES and MDIV!
     * TC_CMR_CLK_XC0: selects external clock input 0
     * TC_CMR_CLK_XC1: selects external clock input 1
     * TC_CMR_CLK_XC2: selects external clock input 2
     */
    async command void setClockSource(uint8_t clockSource);

    /**
     * Returns the current timer frequency in kHz.
     */
    async command uint32_t getTimerFrequency();
}
