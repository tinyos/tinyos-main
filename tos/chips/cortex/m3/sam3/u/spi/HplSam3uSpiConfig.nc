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
 * Interface to configure the SAM3U SPI.
 *
 * @author Thomas Schmid
 */

interface HplSam3uSpiConfig
{
    /**
     * Set the SPI interface to Master mode (default).
     */
    async command error_t setMaster();

    /**
     * Set the SPI interface to Slave mode.
     */
    async command error_t setSlave();

    /**
     * Set fixed peripherel select.
     */
    async command error_t setFixedCS();

    /**
     * Set variable peripheral select.
     */
    async command error_t setVariableCS();

    /**
     * Set the Chip Select pins to be directly connected to the chips
     * (default).
     */
    async command error_t setDirectCS();

    /**
     * Set the Chip Select pins to be connected to a 4- to 16-bit decoder
     */
    async command error_t setMultiplexedCS();

    /**
     * Enable mode fault detection (default).
     */
    async command error_t enableModeFault();

    /**
     * Disable mode fault detection.
     */
    async command error_t disableModeFault();

    /**
     * Disable suppression of transmit if receive register is not empty
     * (default).
     */
    async command error_t disableWaitTx();

    /**
     * Enable suppression of transmit if receive register is not empty.
     */
    async command error_t enableWaitTx();

    /**
     * Disable local loopback
     */
    async command error_t disableLoopBack();

    /**
     * Enable local loopback
     */
    async command error_t enableLoopBack();

    /**
     * Select peripheral chip
     */
    async command error_t selectChip(uint8_t pcs);

    /**
     * Set the delay between chip select changes in MCK clock ticks.
     */
    async command error_t setChipSelectDelay(uint8_t n);
}
