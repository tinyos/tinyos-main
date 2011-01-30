/*
 * Copyright (c) 2010 Johns Hopkins University.
 * Copyright (c) 2010 CSIRO Australia
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without 
 * modification, are permitted provided that the following conditions 
 * are met: 
 * 
 * - Redistributions of source code must retain the above copyright 
 *   notice, this list of conditions and the following disclaimer. 
 * - Redistributions in binary form must reproduce the above copyright 
 *   notice, this list of conditions and the following disclaimer in the 
 *   documentation and/or other materials provided with the 
 *   distribution. 
 * - Neither the name of the copyright holders nor the names of 
 *   its contributors may be used to endorse or promote products derived 
 *   from this software without specific prior written permission. 
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL 
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES 
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR 
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, 
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED 
 * OF THE POSSIBILITY OF SUCH DAMAGE. 
 */

/**
 * High Speed Multimedia Card Interface register definitions.
 *
 * @author JeongGil Ko
 * @author Kevin Klues
 */

#ifndef _SAM3UHSMCIHARDWARE_H
#define _SAM3UHSMCIHARDWARE_H

// Resource definition
#define SAM3U_HSMCI_RESOURCE "Sam3uHsmci.Resource"

/**
 *  HSMCI Control Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 880
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint8_t mcien        :  1;
    uint8_t hsmcidis     :  1;
    uint8_t pwsen        :  1;
    uint8_t pwsdis       :  1;
    uint8_t reserved0    :  3;
    uint8_t swrst        :  1;
    uint8_t reserved1    :  8;
    uint16_t reserved2   : 16;
  } __attribute__((__packed__)) bits;
} hsmci_cr_t;


/**
 *  HSMCI Mode Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 881
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint8_t clkdiv       :  8;
    uint8_t pwsdiv       :  3;
    uint8_t rdproof      :  1;
    uint8_t wrproof      :  1;
    uint8_t fbyte        :  1;
    uint8_t padv         :  1;
    uint8_t reserved0    :  1;
    uint16_t blklen      : 16;
  } __attribute__((__packed__)) bits;
} hsmci_mr_t;


/**
 *  HSMCI Data Timeout Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 883
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint8_t dtocyc       :  4;
    uint8_t dtomul       :  3;
    uint8_t reserved0    :  1;
    uint8_t reserved1    :  8;
    uint16_t reserved2   : 16;
  } __attribute__((__packed__)) bits;
} hsmci_dtor_t;

/**
 *  HSMCI SDCard/SDIO Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 884
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint8_t sdcsel       :  2;
    uint8_t reserved0    :  4;
    uint8_t sdcbus       :  2;
    uint8_t reserved1    :  8;
    uint16_t reserved2   : 16;
  } __attribute__((__packed__)) bits;
} hsmci_sdcr_t;

/**
 *  HSMCI Argument Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 885
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint32_t arg   : 32;
  } __attribute__((__packed__)) bits;
} hsmci_argr_t;

/**
 *  HSMCI Command Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 886
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint8_t cmdnb        :  6;
    uint8_t rsptyp       :  2;
    uint8_t spcmd        :  3;
    uint8_t opdcmd       :  1;
    uint8_t maxlat       :  1;
    uint8_t reserved0    :  3;
    uint8_t trcmd        :  2;
    uint8_t trdir        :  1;
    uint8_t trtyp        :  3;
    uint8_t reserved1    :  2;
    uint8_t iospcmd      :  2;
    uint8_t atacs        :  1;
    uint8_t boot_ack     :  1;
    uint8_t reserved2    :  4;
  } __attribute__((__packed__)) bits;
} hsmci_cmdr_t;

/**
 *  HSMCI Block Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 889
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint32_t bcnt   : 16;
    uint32_t blklen : 16;
  } __attribute__((__packed__)) bits;
} hsmci_blkr_t;

/**
 *  HSMCI Completion Signal Timeout Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 890
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint8_t cstocyc      :  4;
    uint8_t cstomul      :  3;
    uint8_t reserved0    :  1;
    uint8_t reserved1    :  8;
    uint16_t reserved2   : 16;
  } __attribute__((__packed__)) bits;
} hsmci_cstor_t;

/**
 *  HSMCI Response Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 891
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint32_t rsp   : 32;
  } __attribute__((__packed__)) bits;
} hsmci_rspr_t;

/**
 *  HSMCI Receive Data Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 892
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint32_t data   : 32;
  } __attribute__((__packed__)) bits;
} hsmci_rdr_t;

/**
 *  HSMCI Transmit Data Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 893
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint32_t data   : 32;
  } __attribute__((__packed__)) bits;
} hsmci_tdr_t;

/**
 *  HSMCI Status Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 894
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint8_t cmdrdy       :  1;
    uint8_t rxrdy        :  1;
    uint8_t txrdy        :  1;
    uint8_t blke         :  1;
    uint8_t dtip         :  1;
    uint8_t notbusy      :  1;
    uint8_t reserved0    :  2;
    uint8_t mci_sdioirqa :  1;
    uint8_t reserved1    :  3;
    uint8_t sdiowait     :  1;
    uint8_t csrcv        :  1;
    uint8_t reserved2    :  2;
    uint8_t rinde        :  1;
    uint8_t rdire        :  1;
    uint8_t rcrce        :  1;
    uint8_t rende        :  1;
    uint8_t rtoe         :  1;
    uint8_t dcrce        :  1;
    uint8_t dtoe         :  1;
    uint8_t cstoe        :  1;
    uint8_t blkovre      :  1;
    uint8_t dmadone      :  1;
    uint8_t fifoempty    :  1;
    uint8_t xfrdone      :  1;
    uint8_t ackrcv       :  1;
    uint8_t ackrcve      :  1;
    uint8_t ovre         :  1;
    uint8_t unre         :  1;
  } __attribute__((__packed__)) bits;
} hsmci_sr_t;

/**
 *  HSMCI Interrupt Enable Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 898
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint8_t cmdrdy       :  1;
    uint8_t rxrdy        :  1;
    uint8_t txrdy        :  1;
    uint8_t blke         :  1;
    uint8_t dtip         :  1;
    uint8_t notbusy      :  1;
    uint8_t reserved0    :  2;
    uint8_t mci_sdioirqa :  1;
    uint8_t reserved1    :  3;
    uint8_t sdiowait     :  1;
    uint8_t csrcv        :  1;
    uint8_t reserved2    :  2;
    uint8_t rinde        :  1;
    uint8_t rdire        :  1;
    uint8_t rcrce        :  1;
    uint8_t rende        :  1;
    uint8_t rtoe         :  1;
    uint8_t dcrce        :  1;
    uint8_t dtoe         :  1;
    uint8_t cstoe        :  1;
    uint8_t blkovre      :  1;
    uint8_t dmadone      :  1;
    uint8_t fifoempty    :  1;
    uint8_t xfrdone      :  1;
    uint8_t ackrcv       :  1;
    uint8_t ackrcve      :  1;
    uint8_t ovre         :  1;
    uint8_t unre         :  1;
  } __attribute__((__packed__)) bits;
} hsmci_ier_t;

/**
 *  HSMCI Interrupt Disable Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 900
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint8_t cmdrdy       :  1;
    uint8_t rxrdy        :  1;
    uint8_t txrdy        :  1;
    uint8_t blke         :  1;
    uint8_t dtip         :  1;
    uint8_t notbusy      :  1;
    uint8_t reserved0    :  2;
    uint8_t mci_sdioirqa :  1;
    uint8_t reserved1    :  3;
    uint8_t sdiowait     :  1;
    uint8_t csrcv        :  1;
    uint8_t reserved2    :  2;
    uint8_t rinde        :  1;
    uint8_t rdire        :  1;
    uint8_t rcrce        :  1;
    uint8_t rende        :  1;
    uint8_t rtoe         :  1;
    uint8_t dcrce        :  1;
    uint8_t dtoe         :  1;
    uint8_t cstoe        :  1;
    uint8_t blkovre      :  1;
    uint8_t dmadone      :  1;
    uint8_t fifoempty    :  1;
    uint8_t xfrdone      :  1;
    uint8_t ackrcv       :  1;
    uint8_t ackrcve      :  1;
    uint8_t ovre         :  1;
    uint8_t unre         :  1;
  } __attribute__((__packed__)) bits;
} hsmci_idr_t;

/**
 *  HSMCI Interrupt Mask Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 902
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint8_t cmdrdy       :  1;
    uint8_t rxrdy        :  1;
    uint8_t txrdy        :  1;
    uint8_t blke         :  1;
    uint8_t dtip         :  1;
    uint8_t notbusy      :  1;
    uint8_t reserved0    :  2;
    uint8_t mci_sdioirqa :  1;
    uint8_t reserved1    :  3;
    uint8_t sdiowait     :  1;
    uint8_t csrcv        :  1;
    uint8_t reserved2    :  2;
    uint8_t rinde        :  1;
    uint8_t rdire        :  1;
    uint8_t rcrce        :  1;
    uint8_t rende        :  1;
    uint8_t rtoe         :  1;
    uint8_t dcrce        :  1;
    uint8_t dtoe         :  1;
    uint8_t cstoe        :  1;
    uint8_t blkovre      :  1;
    uint8_t dmadone      :  1;
    uint8_t fifoempty    :  1;
    uint8_t xfrdone      :  1;
    uint8_t ackrcv       :  1;
    uint8_t ackrcve      :  1;
    uint8_t ovre         :  1;
    uint8_t unre         :  1;
  } __attribute__((__packed__)) bits;
} hsmci_imr_t;

/**
 *  HSMCI DMA Configuration Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 904
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint8_t offset       :  2;
    uint8_t reserved0    :  2;
    uint8_t chksize      :  1;
    uint8_t reserved1    :  3;
    uint8_t dmaen        :  1;
    uint8_t reserved2    :  3;
    uint8_t ropt         :  1;
    uint8_t reserved3    :  3;
    uint16_t reserved4   : 16;
  } __attribute__((__packed__)) bits;
} hsmci_dma_t;

/**
 *  HSMCI Configuration Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 905
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint8_t fifomode     :  1;
    uint8_t reserved0    :  3;
    uint8_t ferrctrl     :  1;
    uint8_t reserved1    :  3;
    uint8_t hsmode       :  1;
    uint8_t reserved2    :  3;
    uint8_t lsync        :  1;
    uint8_t reserved3    :  3;
    uint16_t reserved4   : 16;
  } __attribute__((__packed__)) bits;
} hsmci_cfg_t;

/**
 *  HSMCI Write Protection Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 906
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint8_t wp_en        :  1;
    uint8_t reserved0    :  7;
    uint32_t wp_key      : 24;
  } __attribute__((__packed__)) bits;
} hsmci_wpmr_t;

/**
 *  HSMCI Write Protect Status Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 907
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint8_t wp_vs        :  4;
    uint8_t reserved0    :  4;
    uint16_t wp_key      : 16;
    uint8_t reserved1    :  8;
  } __attribute__((__packed__)) bits;
} hsmci_wpsr_t;

/**
 *  HSMCI FIFO Memory Aperture, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 908
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint32_t data       : 32;
  } __attribute__((__packed__)) bits;
} hsmci_fifo_t;

/**
 * HSMCI Register definitions, AT91 ARM Cortex-M3 based Microcontrollers SAM3U
 * Series, Preliminary, p. 879
 */
typedef struct hsmci
{
  volatile hsmci_cr_t cr;        // Control Register
  volatile hsmci_mr_t mr;        // Mode Register
  volatile hsmci_dtor_t dtor;    // Data Timeout Register
  volatile hsmci_sdcr_t sdcr;    // SD/SDIO Card Register
  volatile hsmci_argr_t argr;    // Argument Register
  volatile hsmci_cmdr_t cmdr;    // Command Register
  volatile hsmci_blkr_t blkr;    // Block Register
  volatile hsmci_cstor_t cstor;  // Completion Signal Timeout Register
  volatile hsmci_rspr_t rspr[4]; // Response Registers
  volatile hsmci_rdr_t rdr;      // Receive Data Register
  volatile hsmci_tdr_t tdr;      // Transmit Data Register
  uint32_t reserved0[2];         // ***Reserved***
  volatile hsmci_sr_t sr;        // Status Register
  volatile hsmci_ier_t ier;      // Interrupt Enable Register
  volatile hsmci_idr_t idr;      // Interrupt Disable Register
  volatile hsmci_imr_t imr;      // Interrupt Mask Register
  volatile hsmci_dma_t dma;      // DMA Configuration Register
  volatile hsmci_cfg_t cfg;      // Configuration Register
  uint32_t reserved1[3];         // ***Reserved***
  volatile hsmci_wpmr_t wpmr;    // Write Protection Mode Register
  volatile hsmci_wpsr_t wpsr;    // Write Portection Status Register
  uint32_t reserved2[5];         // ***Reserved***
} hsmci_t;

/**
 * Memory mapping for the HSMCI controller
 */
volatile hsmci_t* HSMCI = (volatile hsmci_t *) 0x40000000;
volatile hsmci_fifo_t* hsmci_fifo = (volatile hsmci_fifo_t *) 0x40000200;

enum {
  CMD_PON,
  CMD0,
  CMD2,
  CMD3,
  CMD4,
  CMD6,
  CMD7,
  CMD8,
  CMD9,
  CMD10,
  CMD12,
  CMD13,
  CMD15,
  CMD16,
  CMD17,
  CMD18,
  CMD19,
  CMD20,
  CMD24,
  CMD25,
  CMD26,
  CMD27,
  CMD28,
  CMD29,
  CMD30,
  CMD32,
  CMD33,
  CMD38,
  CMD42,
  CMD56R,
  CMD56W,
  ACMD6,
  ACMD6_REAL,
  ACMD13,
  ACMD13_REAL,
  ACMD22,
  ACMD22_REAL,
  ACMD23,
  ACMD23_REAL,
  ACMD41,
  ACMD41_REAL,
  ACMD42,
  ACMD42_REAL,
  ACMD51,
  ACMD51_REAL,
};

#define AT91C_MCI_CMDNB                      (0x3F <<  0) // (MCI) Command Number
#define AT91C_MCI_RSPTYP                     (0x3 <<  6)  // (MCI) Response Type
#define AT91C_MCI_RSPTYP_NO                  (0x0 <<  6)  // (MCI) No response
#define AT91C_MCI_RSPTYP_48                  (0x1 <<  6)  // (MCI) 48-bit response
#define AT91C_MCI_RSPTYP_136                 (0x2 <<  6)  // (MCI) 136-bit response
#define AT91C_MCI_RSPTYP_R1B                 (0x3 <<  6)  // (MCI) R1b response
#define AT91C_MCI_SPCMD                      (0x7 <<  8)  // (MCI) Special CMD
#define AT91C_MCI_SPCMD_NONE                 (0x0 <<  8)  // (MCI) Not a special CMD
#define AT91C_MCI_SPCMD_INIT                 (0x1 <<  8)  // (MCI) Initialization CMD
#define AT91C_MCI_SPCMD_SYNC                 (0x2 <<  8)  // (MCI) Synchronized CMD
#define AT91C_MCI_SPCMD_CE_ATA               (0x3 <<  8)  // (MCI) CE-ATA Completion Signal disable CMD
#define AT91C_MCI_SPCMD_IT_CMD               (0x4 <<  8)  // (MCI) Interrupt command
#define AT91C_MCI_SPCMD_IT_REP               (0x5 <<  8)  // (MCI) Interrupt response
#define AT91C_MCI_OPDCMD                     (0x1 << 11)  // (MCI) Open Drain Command
#define AT91C_MCI_OPDCMD_PUSHPULL            (0x0 << 11)  // (MCI) Push/pull command
#define AT91C_MCI_OPDCMD_OPENDRAIN           (0x1 << 11)  // (MCI) Open drain command
#define AT91C_MCI_MAXLAT                     (0x1 << 12)  // (MCI) Maximum Latency for Command to respond
#define AT91C_MCI_MAXLAT_5                   (0x0 << 12)  // (MCI) 5 cycles maximum latency
#define AT91C_MCI_MAXLAT_64                  (0x1 << 12)  // (MCI) 64 cycles maximum latency
#define AT91C_MCI_TRCMD                      (0x3 << 16)  // (MCI) Transfer CMD
#define AT91C_MCI_TRCMD_NO                   (0x0 << 16)  // (MCI) No transfer
#define AT91C_MCI_TRCMD_START                (0x1 << 16)  // (MCI) Start transfer
#define AT91C_MCI_TRCMD_STOP                 (0x2 << 16)  // (MCI) Stop transfer
#define AT91C_MCI_TRDIR                      (0x1 << 18)  // (MCI) Transfer Direction
#define AT91C_MCI_TRDIR_WRITE                (0x0 << 18)  // (MCI) Write
#define AT91C_MCI_TRDIR_READ                 (0x1 << 18)  // (MCI) Read
#define AT91C_MCI_TRTYP                      (0x7 << 19)  // (MCI) Transfer Type
#define AT91C_MCI_TRTYP_BLOCK                (0x0 << 19)  // (MCI) MMC/SDCard Single Block Transfer type
#define AT91C_MCI_TRTYP_MULTIPLE             (0x1 << 19)  // (MCI) MMC/SDCard Multiple Block transfer type
#define AT91C_MCI_TRTYP_STREAM               (0x2 << 19)  // (MCI) MMC Stream transfer type
#define AT91C_MCI_TRTYP_SDIO_BYTE            (0x4 << 19)  // (MCI) SDIO Byte transfer type
#define AT91C_MCI_TRTYP_SDIO_BLOCK           (0x5 << 19)  // (MCI) SDIO Block transfer type
#define AT91C_MCI_IOSPCMD                    (0x3 << 24)  // (MCI) SDIO Special Command
#define AT91C_MCI_IOSPCMD_NONE               (0x0 << 24)  // (MCI) NOT a special command
#define AT91C_MCI_IOSPCMD_SUSPEND            (0x1 << 24)  // (MCI) SDIO Suspend Command
#define AT91C_MCI_IOSPCMD_RESUME             (0x2 << 24)  // (MCI) SDIO Resume Command
#define AT91C_MCI_ATACS                      (0x1 << 26)  // (MCI) ATA with command completion signal
#define AT91C_MCI_ATACS_NORMAL               (0x0 << 26)  // (MCI) normal operation mode
#define AT91C_MCI_ATACS_COMPLETION           (0x1 << 26)  // (MCI) completion 

//-----------------------------------------------------------------------------
/// OCR Register
//-----------------------------------------------------------------------------
#define AT91C_VDD_16_17          (1 << 4)
#define AT91C_VDD_17_18          (1 << 5)
#define AT91C_VDD_18_19          (1 << 6)
#define AT91C_VDD_19_20          (1 << 7)
#define AT91C_VDD_20_21          (1 << 8)
#define AT91C_VDD_21_22          (1 << 9)
#define AT91C_VDD_22_23          (1 << 10)
#define AT91C_VDD_23_24          (1 << 11)
#define AT91C_VDD_24_25          (1 << 12)
#define AT91C_VDD_25_26          (1 << 13)
#define AT91C_VDD_26_27          (1 << 14)
#define AT91C_VDD_27_28          (1 << 15)
#define AT91C_VDD_28_29          (1 << 16)
#define AT91C_VDD_29_30          (1 << 17)
#define AT91C_VDD_30_31          (1 << 18)
#define AT91C_VDD_31_32          (1 << 19)
#define AT91C_VDD_32_33          (1 << 20)
#define AT91C_VDD_33_34          (1 << 21)
#define AT91C_VDD_34_35          (1 << 22)
#define AT91C_VDD_35_36          (1 << 23)
#define AT91C_CARD_POWER_UP_BUSY (1 << 31)
#define AT91C_MMC_OCR_BIT2930    (3 << 29)

#define AT91C_MMC_HOST_VOLTAGE_RANGE     (AT91C_VDD_27_28 +\
                                          AT91C_VDD_28_29 +\
                                          AT91C_VDD_29_30 +\
                                          AT91C_VDD_30_31 +\
                                          AT91C_VDD_31_32 +\
                                          AT91C_VDD_32_33)

// Basic Commands (class 0)
//
// Cmd0 MCI + SPI
#define   AT91C_POWER_ON_INIT         (0 | AT91C_MCI_TRCMD_NO \
				         | AT91C_MCI_SPCMD_INIT \
				         | AT91C_MCI_OPDCMD)

#define   AT91C_GO_IDLE_STATE_CMD     (0 | AT91C_MCI_TRCMD_NO \
                                         | AT91C_MCI_SPCMD_NONE )
// Cmd1 SPI
#define   AT91C_MMC_SEND_OP_COND_CMD  (1 | AT91C_MCI_TRCMD_NO \
                                         | AT91C_MCI_SPCMD_NONE \
                                         | AT91C_MCI_RSPTYP_48 \
                                         | AT91C_MCI_OPDCMD)
// Cmd2 MCI
#define   AT91C_ALL_SEND_CID_CMD      (2 | AT91C_MCI_TRCMD_NO \
                                         | AT91C_MCI_SPCMD_NONE \
                                         | AT91C_MCI_RSPTYP_136 )
// Cmd3 MCI
#define   AT91C_SET_RELATIVE_ADDR_CMD (3 | AT91C_MCI_TRCMD_NO \
                                         | AT91C_MCI_SPCMD_NONE \
                                         | AT91C_MCI_RSPTYP_48 \
                                         | AT91C_MCI_MAXLAT )
// Cmd4 MCI
#define AT91C_SET_DSR_CMD             (4 | AT91C_MCI_TRCMD_NO \
                                         | AT91C_MCI_SPCMD_NONE \
                                         | AT91C_MCI_RSPTYP_NO \
                                         | AT91C_MCI_MAXLAT )
// Cmd6 SD/MMC
#define AT91C_MMC_SWITCH_CMD          (6 | AT91C_MCI_TRCMD_NO \
                                         | AT91C_MCI_SPCMD_NONE \
                                         | AT91C_MCI_RSPTYP_48 \
                                         | AT91C_MCI_MAXLAT )

#define AT91C_SD_SWITCH_CMD           (6 | AT91C_MCI_TRCMD_START \
                                         | AT91C_MCI_TRTYP_BLOCK \
                                         | AT91C_MCI_TRDIR_READ \
                                         | AT91C_MCI_SPCMD_NONE \
                                         | AT91C_MCI_RSPTYP_48 \
                                         | AT91C_MCI_MAXLAT )
// cmd7 MCI
#define   AT91C_SEL_DESEL_CARD_CMD    (7 | AT91C_MCI_TRCMD_NO \
                                         | AT91C_MCI_SPCMD_NONE \
                                         | AT91C_MCI_RSPTYP_48 \
                                         | AT91C_MCI_MAXLAT )
#define   AT91C_SEL_CARD_CMD          (7 | AT91C_MCI_TRCMD_NO \
                                         | AT91C_MCI_SPCMD_NONE \
                                         | AT91C_MCI_RSPTYP_48 \
                                         | AT91C_MCI_MAXLAT )
#define   AT91C_DESEL_CARD_CMD        (7 | AT91C_MCI_TRCMD_NO \
                                         | AT91C_MCI_SPCMD_NONE \
                                         | AT91C_MCI_RSPTYP_NO \
                                         | AT91C_MCI_MAXLAT )
// Cmd8 MCI + SPI
#define   AT91C_SEND_IF_COND          (8  | AT91C_MCI_TRCMD_NO \
                                          | AT91C_MCI_SPCMD_NONE \
                                          | AT91C_MCI_RSPTYP_48 \
                                          | AT91C_MCI_MAXLAT )
// Cmd9 MCI + SPI
#define   AT91C_SEND_CSD_CMD          (9  | AT91C_MCI_TRCMD_NO \
                                          | AT91C_MCI_SPCMD_NONE \
                                          | AT91C_MCI_RSPTYP_136 \
                                          | AT91C_MCI_MAXLAT )
// Cmd10 MCI + SPI
#define   AT91C_SEND_CID_CMD          (10 | AT91C_MCI_TRCMD_NO \
                                          | AT91C_MCI_SPCMD_NONE \
                                          | AT91C_MCI_RSPTYP_136 \
                                          | AT91C_MCI_MAXLAT )
// Cmd12 MCI + SPI
#define   AT91C_STOP_TRANSMISSION_CMD (12 | AT91C_MCI_TRCMD_STOP \
                                          | AT91C_MCI_SPCMD_NONE \
                                          | AT91C_MCI_RSPTYP_48 \
                                          | AT91C_MCI_MAXLAT )

// Cmd13 MCI + SPI
#define   AT91C_SEND_STATUS_CMD       (13 | AT91C_MCI_TRCMD_NO \
                                          | AT91C_MCI_SPCMD_NONE \
                                          | AT91C_MCI_RSPTYP_48 \
                                          | AT91C_MCI_MAXLAT )
// Cmd15 MCI
#define AT91C_GO_INACTIVE_STATE_CMD   (15 | AT91C_MCI_RSPTYP_NO )

// Cmd58 SPI
#define   AT91C_READ_OCR_CMD          (58 | AT91C_MCI_RSPTYP_48 \
                                          | AT91C_MCI_SPCMD_NONE \
                                          | AT91C_MCI_MAXLAT )
// Cmd59 SPI
#define   AT91C_CRC_ON_OFF_CMD        (59 | AT91C_MCI_RSPTYP_48 \
                                          | AT91C_MCI_SPCMD_NONE \
                                          | AT91C_MCI_MAXLAT )

//*------------------------------------------------
//* Class 2 commands: Block oriented Read commands
//*------------------------------------------------

// Cmd8 for MMC
#define AT91C_SEND_EXT_CSD_CMD          (8 | AT91C_MCI_SPCMD_NONE \
                                           | AT91C_MCI_OPDCMD_PUSHPULL \
                                           | AT91C_MCI_RSPTYP_48 \
                                           | AT91C_MCI_TRCMD_START \
                                           | AT91C_MCI_TRTYP_BLOCK \
                                           | AT91C_MCI_TRDIR \
                                           | AT91C_MCI_MAXLAT)

// Cmd16
#define AT91C_SET_BLOCKLEN_CMD          (16 | AT91C_MCI_TRCMD_NO \
                                            | AT91C_MCI_SPCMD_NONE \
                                            | AT91C_MCI_RSPTYP_48 \
                                            | AT91C_MCI_MAXLAT )
// Cmd17
#define AT91C_READ_SINGLE_BLOCK_CMD     (17 | AT91C_MCI_SPCMD_NONE \
                                            | AT91C_MCI_RSPTYP_48 \
                                            | AT91C_MCI_TRCMD_START \
                                            | AT91C_MCI_TRTYP_BLOCK \
                                            | AT91C_MCI_TRDIR \
                                            | AT91C_MCI_MAXLAT)
// Cmd18
#define AT91C_READ_MULTIPLE_BLOCK_CMD   (18 | AT91C_MCI_SPCMD_NONE \
                                            | AT91C_MCI_RSPTYP_48 \
                                            | AT91C_MCI_TRCMD_START \
                                            | AT91C_MCI_TRTYP_MULTIPLE \
                                            | AT91C_MCI_TRDIR \
                                            | AT91C_MCI_MAXLAT)

//*------------------------------------------------
//* Class 4 commands: Block oriented write commands
//*------------------------------------------------
// Cmd24
#define AT91C_WRITE_BLOCK_CMD           (24 | AT91C_MCI_SPCMD_NONE \
                                            | AT91C_MCI_RSPTYP_48 \
                                            | AT91C_MCI_TRCMD_START \
                                            | (AT91C_MCI_TRTYP_BLOCK \
                                                & ~(AT91C_MCI_TRDIR)) \
                                            | AT91C_MCI_MAXLAT)
// Cmd25
#define AT91C_WRITE_MULTIPLE_BLOCK_CMD  (25 | AT91C_MCI_SPCMD_NONE \
                                            | AT91C_MCI_RSPTYP_48 \
                                            | AT91C_MCI_TRCMD_START \
                                            | (AT91C_MCI_TRTYP_MULTIPLE \
                                                & ~(AT91C_MCI_TRDIR)) \
                                            | AT91C_MCI_MAXLAT)
// Cmd27
#define AT91C_PROGRAM_CSD_CMD            (27 | AT91C_MCI_RSPTYP_48 )

//*----------------------------------------
//* Class 5 commands: Erase commands
//*----------------------------------------
// Cmd32
#define AT91C_TAG_SECTOR_START_CMD          (32 | AT91C_MCI_SPCMD_NONE \
                                                | AT91C_MCI_RSPTYP_48 \
                                                | AT91C_MCI_TRCMD_NO \
                                                | AT91C_MCI_MAXLAT)
// Cmd33
#define AT91C_TAG_SECTOR_END_CMD            (33 | AT91C_MCI_SPCMD_NONE \
                                                | AT91C_MCI_RSPTYP_48 \
                                                | AT91C_MCI_TRCMD_NO \
                                                | AT91C_MCI_MAXLAT)
// Cmd38
#define AT91C_ERASE_CMD                     (38 | AT91C_MCI_SPCMD_NONE \
                                                | AT91C_MCI_RSPTYP_48 \
                                                | AT91C_MCI_TRCMD_NO \
                                                | AT91C_MCI_MAXLAT )

//*---------------------------------------- 
//* Class 7 commands: Lock commands 
//*---------------------------------------- 
// Cmd42 
#define AT91C_LOCK_UNLOCK           (42 | AT91C_MCI_SPCMD_NONE \
                                        | AT91C_MCI_RSPTYP_48 \
                                        | AT91C_MCI_TRCMD_NO \
                                        | AT91C_MCI_MAXLAT)

//*-----------------------------------------------
// Class 8 commands: Application specific commands
//*-----------------------------------------------
// Cmd55
#define AT91C_APP_CMD               (55 | AT91C_MCI_SPCMD_NONE \
                                        | AT91C_MCI_RSPTYP_48 \
                                        | AT91C_MCI_TRCMD_NO \
                                        | AT91C_MCI_MAXLAT)
// Cmd56
#define AT91C_GEN_CMD               (56 | AT91C_MCI_SPCMD_NONE \
                                        | AT91C_MCI_RSPTYP_48 \
                                        | AT91C_MCI_TRCMD_NO \
                                        | AT91C_MCI_MAXLAT)
// ACMD6
#define AT91C_SD_SET_BUS_WIDTH_CMD          (6  | AT91C_MCI_SPCMD_NONE \
                                                | AT91C_MCI_RSPTYP_48 \
                                                | AT91C_MCI_TRCMD_NO \
                                                | AT91C_MCI_MAXLAT)
// ACMD13
#define AT91C_SD_STATUS_CMD                 (13 | AT91C_MCI_SPCMD_NONE \
                                                | AT91C_MCI_RSPTYP_48 \
                                                | AT91C_MCI_TRCMD_START \
                                                | AT91C_MCI_TRTYP_BLOCK \
                                                | AT91C_MCI_TRDIR_READ \
                                                | AT91C_MCI_MAXLAT)
// ACMD22
#define AT91C_SD_SEND_NUM_WR_BLOCKS_CMD     (22 | AT91C_MCI_SPCMD_NONE \
                                                | AT91C_MCI_RSPTYP_48 \
                                                | AT91C_MCI_TRCMD_NO \
                                                | AT91C_MCI_MAXLAT)
// ACMD23
#define AT91C_SD_SET_WR_BLK_ERASE_COUNT_CMD (23 | AT91C_MCI_SPCMD_NONE \
                                                | AT91C_MCI_RSPTYP_48 \
                                                | AT91C_MCI_TRCMD_NO \
                                                | AT91C_MCI_MAXLAT)
// ACMD41
#define AT91C_SD_APP_OP_COND_CMD            (41 | AT91C_MCI_SPCMD_NONE \
                                                | AT91C_MCI_RSPTYP_48 \
                                                | AT91C_MCI_TRCMD_NO )
// ACMD42
#define AT91C_SD_SET_CLR_CARD_DETECT_CMD    (42 | AT91C_MCI_SPCMD_NONE \
                                                | AT91C_MCI_RSPTYP_48 \
                                                | AT91C_MCI_TRCMD_NO \
                                                | AT91C_MCI_MAXLAT)
// ACMD51
#define AT91C_SD_SEND_SCR_CMD               (51 | AT91C_MCI_SPCMD_NONE \
                                                | AT91C_MCI_RSPTYP_48 \
                                                | AT91C_MCI_TRCMD_START \
                                                | AT91C_MCI_TRDIR_READ \
                                                | AT91C_MCI_TRTYP_BLOCK \
                                                | AT91C_MCI_MAXLAT)

//*-----------------------------------------------
// SDIO Commands
//*-----------------------------------------------
// CMD5, R4
#define AT91C_SDIO_SEND_OP_COND (5 | AT91C_MCI_TRCMD_NO \
                                   | AT91C_MCI_SPCMD_NONE \
                                   | AT91C_MCI_RSPTYP_48 \
                                   | AT91C_MCI_OPDCMD)

// CMD52, R5
#define AT91C_SDIO_IO_RW_DIRECT (52| AT91C_MCI_TRCMD_NO \
                                   | AT91C_MCI_SPCMD_NONE \

//*-----------------------------------------------
// Constants
//*-----------------------------------------------
#define SD_STAT_DATA_BUS_WIDTH_4BIT      0x2
#define SD_STAT_DATA_BUS_WIDTH_1BIT      0x0

#define STATUS_APP_CMD           (1 << 5)
#define STATUS_SWITCH_ERROR      (1 << 7)
#define STATUS_READY_FOR_DATA    (1 << 8)
#define STATUS_IDLE              (0 << 9)
#define STATUS_READY             (1 << 9)
#define STATUS_IDENT             (2 << 9)
#define STATUS_STBY              (3 << 9)
#define STATUS_TRAN              (4 << 9)
#define STATUS_DATA              (5 << 9)
#define STATUS_RCV               (6 << 9)
#define STATUS_PRG               (7 << 9)
#define STATUS_DIS               (8 << 9)
#define STATUS_STATE             (0xF << 9)
#define STATUS_ERASE_RESET       (1 << 13)
#define STATUS_WP_ERASE_SKIP     (1 << 15)
#define STATUS_CIDCSD_OVERWRITE  (1 << 16)
#define STATUS_OVERRUN           (1 << 17)
#define STATUS_UNERRUN           (1 << 18)
#define STATUS_ERROR             (1 << 19)
#define STATUS_CC_ERROR          (1 << 20)
#define STATUS_CARD_ECC_FAILED   (1 << 21)
#define STATUS_ILLEGAL_COMMAND   (1 << 22)
#define STATUS_COM_CRC_ERROR     (1 << 23)
#define STATUS_UN_LOCK_FAILED    (1 << 24)
#define STATUS_CARD_IS_LOCKED    (1 << 25)
#define STATUS_WP_VIOLATION      (1 << 26)
#define STATUS_ERASE_PARAM       (1 << 27)
#define STATUS_ERASE_SEQ_ERROR   (1 << 28)
#define STATUS_BLOCK_LEN_ERROR   (1 << 29)
#define STATUS_ADDRESS_MISALIGN  (1 << 30)
#define STATUS_ADDR_OUT_OR_RANGE (1 << 31)

#define STATUS_STOP ( STATUS_CARD_IS_LOCKED \
                        | STATUS_COM_CRC_ERROR \
                        | STATUS_ILLEGAL_COMMAND \
                        | STATUS_CC_ERROR \
                        | STATUS_ERROR \
                        | STATUS_STATE \
                        | STATUS_READY_FOR_DATA )

#define STATUS_WRITE ( STATUS_ADDR_OUT_OR_RANGE \
                        | STATUS_ADDRESS_MISALIGN \
                        | STATUS_BLOCK_LEN_ERROR \
                        | STATUS_WP_VIOLATION \
                        | STATUS_CARD_IS_LOCKED \
                        | STATUS_COM_CRC_ERROR \
                        | STATUS_ILLEGAL_COMMAND \
                        | STATUS_CC_ERROR \
                        | STATUS_ERROR \
                        | STATUS_ERASE_RESET \
                        | STATUS_STATE \
                        | STATUS_READY_FOR_DATA )

#define STATUS_READ  ( STATUS_ADDR_OUT_OR_RANGE \
                        | STATUS_ADDRESS_MISALIGN \
                        | STATUS_BLOCK_LEN_ERROR \
                        | STATUS_CARD_IS_LOCKED \
                        | STATUS_COM_CRC_ERROR \
                        | STATUS_ILLEGAL_COMMAND \
                        | STATUS_CARD_ECC_FAILED \
                        | STATUS_CC_ERROR \
                        | STATUS_ERROR \
                        | STATUS_ERASE_RESET \
                        | STATUS_STATE \
                        | STATUS_READY_FOR_DATA )

#define STATUS_SD_SWITCH ( STATUS_ADDR_OUT_OR_RANGE \
                            | STATUS_CARD_IS_LOCKED \
                            | STATUS_COM_CRC_ERROR \
                            | STATUS_ILLEGAL_COMMAND \
                            | STATUS_CARD_ECC_FAILED \
                            | STATUS_CC_ERROR \
                            | STATUS_ERROR \
                            | STATUS_UNERRUN \
                            | STATUS_OVERRUN \
                            | STATUS_STATE)

#define STATUS_MMC_SWITCH ( STATUS_CARD_IS_LOCKED \
                            | STATUS_COM_CRC_ERROR \
                            | STATUS_ILLEGAL_COMMAND \
                            | STATUS_CC_ERROR \
                            | STATUS_ERROR \
                            | STATUS_ERASE_RESET \
                            | STATUS_STATE \
                            | STATUS_READY_FOR_DATA \
                            | STATUS_SWITCH_ERROR )

//*-----------------------------------------------
// Return Types
//*-----------------------------------------------
typedef struct hsmci_sd_r1 {
  uint32_t status : 32;
  uint32_t cmd_index   :  6;
} __attribute__((__packed__)) hsmci_sd_r1_t;

typedef struct hsmci_sd_r2 {
  union {
    struct {
      uint32_t reserved0 : 1;
      uint32_t crc7      : 7;
      uint32_t mdt       : 12;
      uint32_t reserved1 : 4;
      uint32_t psn       : 32;
      uint32_t prv       : 8;
      uint64_t pnm       : 40;
      uint32_t oid       : 16;
      uint32_t mid       : 8;
    } __attribute__((__packed__)) cid;
    struct {
      uint32_t reserved6          : 1;
      uint32_t crc                : 7;
      uint32_t reserved5          : 2;
      uint32_t file_format        : 2;
      uint32_t tmp_write_protect  : 1;
      uint32_t perm_write_protect : 1;
      uint32_t copy               : 1;
      uint32_t file_format_grp    : 1;
      uint32_t reserved4          : 5;
      uint32_t write_bl_partial   : 1;
      uint32_t write_bl_len       : 4;
      uint32_t r2w_factor         : 3;
      uint32_t reserved3          : 2;
      uint32_t wp_grp_enable      : 1;
      uint32_t wp_grp_size        : 7;
      uint32_t sector_size        : 7;
      uint32_t erase_blk_en       : 1;
      uint32_t c_size_mult        : 3;
      uint32_t vdd_w_curr_max     : 3;
      uint32_t vdd_w_curr_min     : 3;
      uint32_t vdd_r_curr_max     : 3;
      uint32_t vdd_r_curr_min     : 3;
      uint32_t c_size             : 12;
      uint32_t reserved1          : 2;
      uint32_t dsr_imp            : 1;
      uint32_t read_blk_misalign  : 1;
      uint32_t write_blk_misalign : 1;
      uint32_t read_bl_partial    : 1;
      uint32_t read_bl_len        : 4;
      uint32_t ccc                : 12;
      uint32_t tran_speed         : 8;
      uint32_t nsac               : 8;
      uint32_t taac               : 8;
      uint32_t reserved0          : 6;
      uint32_t csd_structure      : 2;
    } __attribute__((__packed__)) v1_csd;
    struct {
      uint32_t reserved6          : 1;
      uint32_t crc                : 7;
      uint32_t reserved5          : 2;
      uint32_t file_format        : 2;
      uint32_t tmp_write_protect  : 1;
      uint32_t perm_write_protect : 1;
      uint32_t copy               : 1;
      uint32_t file_format_grp    : 1;
      uint32_t reserved4          : 5;
      uint32_t write_bl_partial   : 1;
      uint32_t write_bl_len       : 4;
      uint32_t r2w_factor         : 3;
      uint32_t reserved3          : 2;
      uint32_t wp_grp_enable      : 1;
      uint32_t wp_grp_size        : 7;
      uint32_t sector_size        : 7;
      uint32_t erase_blk_en       : 1;
      uint32_t reserved2          : 1;
      uint32_t c_size             : 22;
      uint32_t reserved1          : 6;
      uint32_t dsr_imp            : 1;
      uint32_t read_blk_misalign  : 1;
      uint32_t write_blk_misalign : 1;
      uint32_t read_bl_partial    : 1;
      uint32_t read_bl_len        : 4;
      uint32_t ccc                : 12;
      uint32_t tran_speed         : 8;
      uint32_t nsac               : 8;
      uint32_t taac               : 8;
      uint32_t reserved0          : 6;
      uint32_t csd_structure      : 2;
    } __attribute__((__packed__)) csd;
  };
} hsmci_sd_r2_t;

typedef struct hsmci_sd_r3 {
  struct {
    uint32_t reserved0 : 8;
    uint32_t ocr       : 16;
    uint32_t s18a      : 1;
    uint32_t reserved1 : 4;
    uint32_t reserved2 : 1;
    uint32_t ccs       : 1;
    uint32_t busy      : 1;
  } __attribute__((__packed__)) ocr;
} hsmci_sd_r3_t;

typedef struct hsmci_sd_r6 {
  uint32_t status : 16;
  uint32_t rca    : 16;
} __attribute__((__packed__)) hsmci_sd_r6_t;

typedef struct hsmci_sd_r7 {
  uint32_t cpattern : 8;
  uint32_t vrange   : 4;
} __attribute__((__packed__)) hsmci_sd_r7_t;

#endif // _SAM3UHSMCIHARDWARE_H
