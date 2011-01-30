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
 * Interface to configure the Chip Selects of the SAM3U SPI.
 *
 * @author Thomas Schmid
 */

interface HplSam3uSpiChipSelConfig
{
    /**
     * Set the Clock polarity
     * 0: inactive state is logic zero
     * 1: inactive state is logic one
     */
    async command error_t setClockPolarity(uint8_t p);

    /**
     * Set the Clock Phase
     * 0: changed on leading edge, and captured on following edge
     * 1: captured on leading edge, and changed on following edge
     */
    async command error_t setClockPhase(uint8_t p);

    /**
     * Disable automatic Chip Select rising between consecutive transmits
     * (default)
     */
    async command error_t disableAutoCS();

    /**
     * enable automatic Chip Select rising between consecutive transmits.
     */
    async command error_t enableAutoCS();

    /**
     * Enable Chip Select active after transfer (default).
     */
    async command error_t enableCSActive();

    /**
     * Disable Chip Select active after transfer.
     */
    async command error_t disableCSActive();

    /**
     * Set the total amount of bits per transfer. Range is from 8 to 16.
     */
    async command error_t setBitsPerTransfer(uint8_t b);

    /**
     * Set the serial clock baud rate by defining the MCK devider, i.e., baud
     * rate = MCK/divider.
     * Acceptable values range from 1 to 255.
     */
    async command error_t setBaud(uint8_t divider);

    /**
     * Set the delay between NPCS ready to first valid SPCK.
     */
    async command error_t setClkDelay(uint8_t delay);

    /**
     * Set the delay between consecutive transfers.
     */
    async command error_t setTxDelay(uint8_t delay);
}
