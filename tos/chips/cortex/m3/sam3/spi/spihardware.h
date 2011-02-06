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
 * Serial Peripheral Interface (SPI) register definitions.
 *
 * @author Thomas Schmid
 */

#ifndef _SPIHARDWARE_H
#define _SPIHARDWARE_H

#define SAM3_HPLSPI_RESOURCE "Sam3HplSpi.Resource"
#define SAM3_SPI_BUS "Sam3Spi.Bus"

/**
 *  SPI Control Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary 9/1/09, p. 621
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint8_t spien        : 1; // spi enable
        uint8_t spidis       : 1; // spi disable
        uint8_t reserved0    : 5;
        uint8_t swrst        : 1; // spi software reset
        uint8_t reserved1    : 8;
        uint8_t reserved2    : 8;
        uint8_t lastxfer     : 1; // last transfer
        uint8_t reserved3    : 7;
    } __attribute__((__packed__)) bits;
} spi_cr_t; 

/**
 *  SPI Mode Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary 9/1/09, p. 622
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint8_t mstr        : 1; // master/slave mode
        uint8_t ps          : 1; // peripheral select
        uint8_t pcsdec      : 1; // chip select decode
        uint8_t reserved0   : 1;
        uint8_t modfdis     : 1; // mode fault detection
        uint8_t wdrbt       : 1; // wait data ready before transfer
        uint8_t reserved1   : 1;
        uint8_t llb         : 1; // local loopback enable
        uint8_t reserved2   : 8;
        uint8_t pcs         : 4; // peripheral chip select
        uint8_t reserved3   : 4;
        uint8_t dlybcs      : 8; // delay between chip selects
    } __attribute__((__packed__)) bits;
} spi_mr_t;


/**
 *  SPI Receive Data Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary 9/1/09, p. 624
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint16_t rd        : 16; // receive data
        uint8_t  pcs       :  4; // peripheral chip select
        uint8_t reserved0  :  4;
        uint8_t reserved1  :  8;
    } __attribute__((__packed__)) bits;
} spi_rdr_t;


/**
 *  SPI Transmit Data Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary 9/1/09, p. 625
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint16_t td        : 16; // transmit data
        uint8_t  pcs       :  4; // peripheral chip select
        uint8_t reserved0  :  4;
        uint8_t lastxfer   :  1; // last transfer
        uint8_t reserved1  :  7;
    } __attribute__((__packed__)) bits;
} spi_tdr_t;


/**
 *  SPI Status Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary 9/1/09, p. 626
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint8_t rdrf      : 1; // receive data register full
        uint8_t tdre      : 1; // transmit data register empty
        uint8_t modf      : 1; // mode fault error
        uint8_t ovres     : 1; // overrun error status
        uint8_t reserved0 : 4;
        uint8_t nssr      : 1; // nss rising
        uint8_t txempty   : 1; // transmission registers empty
        uint8_t undes     : 1; // underrun error status (slave only)
        uint8_t reserved1 : 5;
        uint8_t spiens    : 1; // spi enable status
        uint8_t reserved2 : 7;
        uint8_t reserved3 : 8;
    } __attribute__((__packed__)) bits;
} spi_sr_t;


/**
 *  SPI Interrupt Enable Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary 9/1/09, p. 628
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint8_t rdrf      : 1; // receive data register full interrupt enable
        uint8_t tdre      : 1; // spi transmit data register empty interrupt enable
        uint8_t modf      : 1; // mode fault error interrupt enable
        uint8_t ovres     : 1; // overrun error interrupt enable
        uint8_t reserved0 : 4;
        uint8_t nssr      : 1; // nss rising interrupt enable
        uint8_t txempty   : 1; // transmission registers empty enable
        uint8_t undes     : 1; // underrun error interrupt enable
        uint8_t reserved1 : 5;
        uint8_t reserved2 : 8;
        uint8_t reserved3 : 8;
    } __attribute__((__packed__)) bits;
} spi_ier_t;


/**
 *  SPI Interrupt Disable Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary 9/1/09, p. 629
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint8_t rdrf      : 1; // receive data register full interrupt disable
        uint8_t tdre      : 1; // spi transmit data register empty interrupt disable
        uint8_t modf      : 1; // mode fault error interrupt disable
        uint8_t ovres     : 1; // overrun error interrupt disable
        uint8_t reserved0 : 4;
        uint8_t nssr      : 1; // nss rising interrupt disable
        uint8_t txempty   : 1; // transmission registers empty disable
        uint8_t undes     : 1; // underrun error interrupt disable
        uint8_t reserved1 : 5;
        uint8_t reserved2 : 8;
        uint8_t reserved3 : 8;
    } __attribute__((__packed__)) bits;
} spi_idr_t;


/**
 *  SPI Interrupt Mask Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary 9/1/09, p. 630
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint8_t rdrf      : 1; // receive data register full interrupt mask
        uint8_t tdre      : 1; // spi transmit data register empty interrupt mask
        uint8_t modf      : 1; // mode fault error interrupt mask
        uint8_t ovres     : 1; // overrun error interrupt mask
        uint8_t reserved0 : 4;
        uint8_t nssr      : 1; // nss rising interrupt mask
        uint8_t txempty   : 1; // transmission registers empty mask
        uint8_t undes     : 1; // underrun error interrupt mask
        uint8_t reserved1 : 5;
        uint8_t reserved2 : 8;
        uint8_t reserved3 : 8;
   } __attribute__((__packed__)) bits;
} spi_imr_t;


/**
 *  SPI Chip Select Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary 9/1/09, p. 631
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint8_t cpol       : 1; // clock polarity
        uint8_t ncpha      : 1; // clock phase
        uint8_t csnaat     : 1; // chip select not active after transfer (ignored if csaat = 1)
        uint8_t csaat      : 1; // chip select active after transfer
        uint8_t bits       : 4; // bits per transfer
        uint8_t scbr       : 8; // serial clock baud rate
        uint8_t dlybs      : 8; // delay before spck
        uint8_t dlybct     : 8; // delay between consecutive transfers
    } __attribute__((__packed__)) bits;
} spi_csr_t;

#define SPI_CSR_BITS_8  0
#define SPI_CSR_BITS_9  1
#define SPI_CSR_BITS_10 2
#define SPI_CSR_BITS_11 3
#define SPI_CSR_BITS_12 4
#define SPI_CSR_BITS_13 5
#define SPI_CSR_BITS_14 6
#define SPI_CSR_BITS_15 7
#define SPI_CSR_BITS_16 8

/**
 *  SPI Write Protection Control Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary 9/1/09, p. 634
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint8_t spiwpen   :  1; // spi write protection enable
        uint8_t reserved0 :  7;
        uint32_t spiwpkey : 24; // spi write protection key password
    } __attribute__((__packed__)) bits;
} spi_wpcr_t;

#define SPI_WPCR_SPIWPKEY 0x535049

/**
 *  SPI Write Protection Status Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary 9/1/09, p. 635
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint8_t spiwpvs   : 3; // spi write protection violation status
        uint8_t reserved0 : 5;
        uint8_t spiwpvsrc : 8; // spi write protection violation source
        uint8_t reserved1 : 8;
        uint8_t reserved2 : 8;
    } __attribute__((__packed__)) bits;
} spi_wpsr_t;


/**
 * SPI Register definitions, AT91 ARM Cortex-M3 based Microcontrollers SAM3U
 * Series, Preliminary 9/1/09, p. 620
 */
typedef struct 
{
    volatile spi_cr_t cr;     // Control Register
    volatile spi_mr_t mr;     // Mode Register
    volatile spi_rdr_t rdr;   // Receive Data Register
    volatile spi_tdr_t tdr;   // Transmit Data Register
    volatile spi_sr_t sr;     // Status Register
    volatile spi_ier_t ier;   // Interrupt Enable Register
    volatile spi_idr_t idr;   // Interrupt Disable Register
    volatile spi_imr_t imr;   // Interrupt Mask Register
    uint32_t reserved0[4];
    volatile spi_csr_t csr0; // Chip Select Register 0
    volatile spi_csr_t csr1; // Chip Select Register 1
    volatile spi_csr_t csr2; // Chip Select Register 2
    volatile spi_csr_t csr3; // Chip Select Register 3
    uint32_t reserved1[41];
    volatile spi_wpcr_t wpcr; // Write Protection Control Register
    volatile spi_wpsr_t wpsr; // Write Protection Status Register
    uint32_t reserved2[5];
} spi_t;


#endif // _SPIHARDWARE_H
