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
 * SAM3 TC capture interface.
 *
 * @author Thomas Schmid
 */

interface HplSam3TCCapture
{
    /**
     * Enable the capture event interrupt.
     */
    async command void enable();

    /**
     * Disable the capture event interrupt.
     */
    async command void disable();

    /**
     * Reads the value of the last capture event in RA 
     */
    async command uint16_t getEventRA();

    /**
     * Reads the value of the last capture event in RB 
     */
    async command uint16_t getEventRB();

    /**
     * Clear any pending event.
     */
    async command void clearPendingEvent();

    /**
     * Set the edge that the capture should occur
     *
     * @param cm Capture Mode for edge capture.
     * enums exist for:
     *   TC_CMR_ETRGEDG_NONE is no capture.
     *   TC_CMR_ETRGEDG_RISING is rising edge capture.
     *   TC_CMR_ETRGEDG_FALLING is a falling edge capture.
     *   TC_CMR_ETRGEDG_EACH captures on both rising and falling edges.
     */
    async command void setEdge(uint8_t cm);

    /**
     * Select the external trigger source. Allowed values:
     *   TC_CMR_ABETRG_TIOA
     *   TC_CMR_ABETRG_TIOB
     */
    async command void setExternalTrigger(uint8_t cm);

    /**
     * Set external trigger edge.
     */
    async command void setExternalTriggerEdge(uint8_t cm);

    /**
     * Determine if a capture load overrun is pending.
     *
     * @return TRUE if the capture register has was loaded twice since last read
     */
    async command bool isOverrunPending();

    /**
     * Clear the capture overrun flag for when multiple captures occur
     */
    async command void clearOverrun();

    /**
     * Signalled when an event is captured.
     *
     * @param time The time of the capture event
     */
    async event void captured(uint16_t time);

    /**
     * Signalled when an overrun occures.
     */
    async event void overrun();
}

