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
 * Interface to configure the SAM3 SPI.
 *
 * @author Thomas Schmid
 */

interface HplSam3SpiConfig
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
