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
