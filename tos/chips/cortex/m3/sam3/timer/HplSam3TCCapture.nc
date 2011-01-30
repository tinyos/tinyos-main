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

