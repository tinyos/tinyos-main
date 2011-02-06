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
 * Interface to configure the Chip Selects of the SAM3U SPI.
 *
 * @author Thomas Schmid
 */

interface HplSam3SpiChipSelConfig
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
