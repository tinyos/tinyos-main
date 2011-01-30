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
 * This is an interface to configure the master clock system
 *
 * @author Thomas Schmid
 */

interface HplSam3Clock
{
    /**
     * Select the external oscillator as the slow clock source.
     */
    async command error_t slckExternalOsc();

    /**
     * Select the internal RC oscillator as slow clock source.
     */
    async command error_t slckRCOsc();

    /**
     * Initialize the clock to MCK=48MHz sourced from external Oscillator
     */
    async command error_t mckInit48();

    /**
     * Initialize the clock to MCK=84MHz sourced from external Oscillator
     */
    async command error_t mckInit84();

    /**
     * Initialize the clock to MCK=96MHz sourced from external Oscillator
     */
    async command error_t mckInit96();

    /**
     * Initialize the clock to MCK=12MHz sourced from internal RC for fast
     * startup
     */
    async command error_t mckInit12RC();

    /**
     * Initialize the clock to MCK=4MHz sourced from internal RC for fast
     * startup
     */
    async command error_t mckInit4RC();

    /**
     * Returns the main clock speed in kHz.
     */
    async command uint32_t getMainClockSpeed();

    /**
     * Fires if the main clock has been changed.
     */
    async event void mainClockChanged();
}
