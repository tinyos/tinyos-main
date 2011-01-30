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
 * Interface to control the SAM3U SPI.
 *
 * @author Thomas Schmid
 */

#include "sam3uspihardware.h"

generic module HplSam3uSpiChipSelP(uint32_t csrp)
{
    provides
    {
       interface HplSam3uSpiChipSelConfig;
    }
}
implementation
{
    volatile spi_csr_t *csr = (volatile spi_csr_t*)csrp;

    bool cs;

    /**
     * Set the Clock polarity
     * 0: inactive state is logic zero
     * 1: inactive state is logic one
     */
    async command error_t HplSam3uSpiChipSelConfig.setClockPolarity(uint8_t p)
    {
        spi_csr_t reg = *csr;
        if(p > 1)
            return FAIL;
        reg.bits.cpol = p;
        *csr = reg;
        return SUCCESS;
    }

    /**
     * Set the Clock Phase
     * 0: changed on leading edge, and captured on following edge
     * 1: captured on leading edge, and changed on following edge
     */
    async command error_t HplSam3uSpiChipSelConfig.setClockPhase(uint8_t p)
    {
        spi_csr_t reg = *csr;
        if(p > 1)
            return FAIL;
        reg.bits.ncpha = p;
        *csr = reg;
        return SUCCESS;
    }

    /**
     * Disable automatic Chip Select rising between consecutive transmits
     * (default)
     */
    async command error_t HplSam3uSpiChipSelConfig.disableAutoCS()
    {
        spi_csr_t reg = *csr;
        reg.bits.csnaat = 0;
        *csr = reg;
        return SUCCESS;
    }

    /**
     * enable automatic Chip Select rising between consecutive transmits.
     */
    async command error_t HplSam3uSpiChipSelConfig.enableAutoCS()
    {
        spi_csr_t reg = *csr;
        reg.bits.csnaat = 1;
        *csr = reg;
        return SUCCESS;
    }

    /**
     * Enable Chip Select active after transfer (default).
     */
    async command error_t HplSam3uSpiChipSelConfig.enableCSActive()
    {
        spi_csr_t reg = *csr;
        reg.bits.csaat= 0;
        *csr = reg;
        return SUCCESS;
    }

    /**
     * Disable Chip Select active after transfer.
     */
    async command error_t HplSam3uSpiChipSelConfig.disableCSActive()
    {
        spi_csr_t reg = *csr;
        reg.bits.csaat= 1;
        *csr = reg;
        return SUCCESS;
    }

    /**
     * Set the total amount of bits per transfer. Range is from 8 to 16.
     */
    async command error_t HplSam3uSpiChipSelConfig.setBitsPerTransfer(uint8_t b)
    {
        spi_csr_t reg = *csr;
        if(b > 8)
            return FAIL;
        reg.bits.bits = b;
        *csr = reg;
        return SUCCESS;
    }

    /**
     * Set the serial clock baud rate by defining the MCK devider, i.e., baud
     * rate = MCK/divider.
     * Acceptable values range from 1 to 255.
     */
    async command error_t HplSam3uSpiChipSelConfig.setBaud(uint8_t divider)
    {
        spi_csr_t tcsr = *csr;
        if(divider == 0)
            return FAIL;
        tcsr.bits.scbr = divider;
        *csr = tcsr;
        return SUCCESS;
    }

    /**
     * Set the delay between NPCS ready to first valid SPCK.
     */
    async command error_t HplSam3uSpiChipSelConfig.setClkDelay(uint8_t delay)
    {
        spi_csr_t tcsr = *csr;
        tcsr.bits.dlybs = delay;
        *csr = tcsr;
        return SUCCESS;
    }

    /**
     * Set the delay between consecutive transfers.
     */
    async command error_t HplSam3uSpiChipSelConfig.setTxDelay(uint8_t delay)
    {
        spi_csr_t tcsr = *csr;
        tcsr.bits.dlybct = delay;
        *csr = tcsr;
        return SUCCESS;
    }
}


