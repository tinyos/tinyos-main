/*
 * Copyright (c) 2009 Johns Hopkins University.
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
 * 4 Channel DMA Controller register definitions.
 *
 * @author JeongGil Ko
 */

#ifndef _SAM3UDMAHARDWARE_H
#define _SAM3UDMAHARDWARE_H

/**
 *  DMAC Global Configuration Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 1073
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint8_t reserved0     :  4;
    uint8_t arb_cfg       :  1;
    uint8_t reserved1     :  3;
    uint16_t reserved2    : 16;
    uint8_t reserved3     :  8;
  } __attribute__((__packed__)) bits;
} dmac_gcfg_t; 

/**
 *  DMAC Enable Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 1074
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint8_t enable        :  1;
    uint8_t reserved0     :  7;
    uint16_t reserved1    : 16;
    uint8_t reserved2     :  8;
  } __attribute__((__packed__)) bits;
} dmac_en_t; 

/**
 *  DMAC Software Single Request Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 1075
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint8_t ssreq0        :  1;
    uint8_t dsreq0        :  1;
    uint8_t ssreq1        :  1;
    uint8_t dsreq1        :  1;
    uint8_t ssreq2dash    :  1;
    uint8_t dsreq2dash    :  1;
    uint8_t ssreq3        :  1;
    uint8_t dsreq3        :  1;
    uint16_t reserved0    : 16;
    uint8_t reserved1     :  8;
  } __attribute__((__packed__)) bits;
} dmac_sreq_t; 

/**
 *  DMAC Software Chunk Request Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 1076
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint8_t screq0        :  1;
    uint8_t dcreq0        :  1;
    uint8_t screq1        :  1;
    uint8_t dcreq1        :  1;
    uint8_t screq2dash    :  1;
    uint8_t dcreq2dash    :  1;
    uint8_t screq3        :  1;
    uint8_t dcreq3        :  1;
    uint16_t reserved0    : 16;
    uint8_t reserved1     :  8;
  } __attribute__((__packed__)) bits;
} dmac_creq_t; 

/**
 *  DMAC Software Last Transfer Flag Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 1077
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint8_t slast0        :  1;
    uint8_t dlast0        :  1;
    uint8_t slast1        :  1;
    uint8_t dlast1        :  1;
    uint8_t slast2        :  1;
    uint8_t dlast2        :  1;
    uint8_t slast3        :  1;
    uint8_t dlast3        :  1;
    uint16_t reserved0    : 16;
    uint8_t reserved1     :  8;
  } __attribute__((__packed__)) bits;
} dmac_last_t; 

/**
 *  DMAC Error, Buffer Transfer and Chained Buffer Transfer Interrupt Enable Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 1078
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint8_t btc0        :  1;
    uint8_t btc1        :  1;
    uint8_t btc2        :  1;
    uint8_t btc3        :  1;
    uint8_t reserved0   :  4;
    uint8_t cbtc0       :  1;
    uint8_t cbtc1       :  1;
    uint8_t cbtc2       :  1;
    uint8_t cbtc3       :  1;
    uint8_t reserved1   :  4;
    uint8_t err0        :  1;
    uint8_t err1        :  1;
    uint8_t err2        :  1;
    uint8_t err3        :  1;
    uint8_t reserved2   :  4;
    uint8_t reserved3   :  8;
  } __attribute__((__packed__)) bits;
} dmac_ebcier_t; 

/**
 *  DMAC Error, Buffer Transfer and Chained Buffer Transfer Interrupt Disable Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 1079
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint8_t btc0        :  1;
    uint8_t btc1        :  1;
    uint8_t btc2        :  1;
    uint8_t btc3        :  1;
    uint8_t reserved0   :  4;
    uint8_t cbtc0       :  1;
    uint8_t cbtc1       :  1;
    uint8_t cbtc2       :  1;
    uint8_t cbtc3       :  1;
    uint8_t reserved1   :  4;
    uint8_t err0        :  1;
    uint8_t err1        :  1;
    uint8_t err2        :  1;
    uint8_t err3        :  1;
    uint8_t reserved2   :  4;
    uint8_t reserved3   :  8;
  } __attribute__((__packed__)) bits;
} dmac_ebcidr_t; 

/**
 *  DMAC Error, Buffer Transfer and Chained Buffer Transfer Interrupt Mask Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 1080
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint8_t btc0        :  1;
    uint8_t btc1        :  1;
    uint8_t btc2        :  1;
    uint8_t btc3        :  1;
    uint8_t reserved0   :  4;
    uint8_t cbtc0       :  1;
    uint8_t cbtc1       :  1;
    uint8_t cbtc2       :  1;
    uint8_t cbtc3       :  1;
    uint8_t reserved1   :  4;
    uint8_t err0        :  1;
    uint8_t err1        :  1;
    uint8_t err2        :  1;
    uint8_t err3        :  1;
    uint8_t reserved2   :  4;
    uint8_t reserved3   :  8;
  } __attribute__((__packed__)) bits;
} dmac_ebcimr_t;

/**
 *  DMAC Error, Buffer Transfer and Chained Buffer Transfer Interrupt Status Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 1081
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint8_t btc0        :  1;
    uint8_t btc1        :  1;
    uint8_t btc2        :  1;
    uint8_t btc3        :  1;
    uint8_t reserved0   :  4;
    uint8_t cbtc0       :  1;
    uint8_t cbtc1       :  1;
    uint8_t cbtc2       :  1;
    uint8_t cbtc3       :  1;
    uint8_t reserved1   :  4;
    uint8_t err0        :  1;
    uint8_t err1        :  1;
    uint8_t err2        :  1;
    uint8_t err3        :  1;
    uint8_t reserved2   :  4;
    uint8_t reserved3   :  8;
  } __attribute__((__packed__)) bits;
} dmac_ebcisr_t;

/**
 *  DMAC Channel Handler Enable Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 1082
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint8_t ena0        :  1;
    uint8_t ena1        :  1;
    uint8_t ena2        :  1;
    uint8_t ena3        :  1;
    uint8_t reserved0   :  4;
    uint8_t susp0       :  1;
    uint8_t susp1       :  1;
    uint8_t susp2       :  1;
    uint8_t susp3       :  1;
    uint8_t reserved1   :  4;
    uint8_t reserved2   :  8;
    uint8_t keep0       :  1;
    uint8_t keep1       :  1;
    uint8_t keep2       :  1;
    uint8_t keep3       :  1;
    uint8_t reserved3   :  4;
  } __attribute__((__packed__)) bits;
} dmac_cher_t;

/**
 *  DMAC Channel Handler Disable Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 1083
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint8_t dis0        :  1;
    uint8_t dis1        :  1;
    uint8_t dis2        :  1;
    uint8_t dis3        :  1;
    uint8_t reserved0   :  4;
    uint8_t res0        :  1;
    uint8_t res1        :  1;
    uint8_t res2        :  1;
    uint8_t res3        :  1;
    uint8_t reserved1   :  4;
    uint8_t reserved2   :  8;
    uint8_t reserved3   :  8;
  } __attribute__((__packed__)) bits;
} dmac_chdr_t;

/**
 *  DMAC Channel Handler Status Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 1084
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint8_t ena0        :  1;
    uint8_t ena1        :  1;
    uint8_t ena2        :  1;
    uint8_t ena3        :  1;
    uint8_t reserved0   :  4;
    uint8_t susp0       :  1;
    uint8_t susp1       :  1;
    uint8_t susp2       :  1;
    uint8_t susp3       :  1;
    uint8_t reserved1   :  4;
    uint8_t empt0       :  1;
    uint8_t empt1       :  1;
    uint8_t empt2       :  1;
    uint8_t empt3       :  1;
    uint8_t reserved2   :  4;
    uint8_t stal0       :  1;
    uint8_t stal1       :  1;
    uint8_t stal2       :  1;
    uint8_t stal3       :  1;
    uint8_t reserved3   :  4;
  } __attribute__((__packed__)) bits;
} dmac_chsr_t;

/**
 *  DMAC Channal x Source Address Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 1085
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint32_t saddrx         : 32;
  } __attribute__((__packed__)) bits;
} dmac_saddrx_t;

/**
 *  DMAC Channal x Destination Address Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 1086
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint32_t daddrx         : 32;
  } __attribute__((__packed__)) bits;
} dmac_daddrx_t;

/**
 *  DMAC Channal x Descriptor Address Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 1087
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint32_t reserved0     :  2;
    uint32_t dscrx         : 30; 
  } __attribute__((__packed__)) bits;
} dmac_dscrx_t;

/**
 *  DMAC Channal x Control A Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 1088
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint16_t btsize     : 12;
    uint16_t scsize     :  1;
    uint16_t reserved0  :  3;
    uint8_t dcsize      :  1;
    uint8_t reserved1   :  3;
    uint8_t src_width   :  2;
    uint8_t reserved2   :  2;
    uint8_t dst_width   :  2;
    uint8_t reserved3   :  1;
    uint8_t done        :  1;
  } __attribute__((__packed__)) bits;
} dmac_ctrlax_t;

/**
 *  DMAC Channal x Control B Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 1090
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint8_t reserved0      :  8;
    uint8_t resetved1      :  8;
    uint8_t src_dscr       :  1;
    uint8_t reserved2      :  3;
    uint8_t dst_dscr       :  1;
    uint8_t fc             :  2;
    uint8_t reserved3      :  1;
    uint8_t src_incr       :  2;
    uint8_t reserved4      :  2;
    uint8_t dst_incr       :  2;
    uint8_t ien            :  1;
    uint8_t reserved5      :  1;
  } __attribute__((__packed__)) bits;
} dmac_ctrlbx_t;

/**
 *  DMAC Channal x Configuration Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 1090
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint8_t src_per      :  4;
    uint8_t dst_per      :  4;
    uint8_t reserved0    :  1;
    uint8_t src_h2sel    :  1;
    uint8_t reserved1    :  3;
    uint8_t dst_h2sel    :  1;
    uint8_t reserved2    :  2;
    uint8_t sod          :  1;
    uint8_t reserved3    :  3;
    uint8_t lock_if      :  1;
    uint8_t lock_b       :  1;
    uint8_t lock_if_l    :  1;
    uint8_t reserved4    :  1;
    uint8_t ahb_prot     :  3;
    uint8_t reserved5    :  1;
    uint8_t fifocfg      :  2;
    uint8_t reserved6    :  2;
  } __attribute__((__packed__)) bits;
} dmac_cfgx_t;

/**
 * DMAC Register definitions, AT91 ARM Cortex-M3 based Microcontrollers SAM3U
 * Series, Preliminary, p. 1072
 */

typedef struct dmac
{
  volatile dmac_gcfg_t gcfg;
  volatile dmac_en_t en;
  volatile dmac_sreq_t sreq;
  volatile dmac_creq_t creq;
  volatile dmac_last_t last;
  uint32_t reserved0;
  volatile dmac_ebcier_t ebcier;
  volatile dmac_ebcidr_t ebcidr;
  volatile dmac_ebcimr_t ebcimr;
  volatile dmac_ebcisr_t ebcisr;
  volatile dmac_cher_t cher;
  volatile dmac_chdr_t chdr;
  volatile dmac_chsr_t chsr;
  uint32_t reserved1;
  uint32_t reserved2;
  volatile dmac_saddrx_t saddr0;
  volatile dmac_daddrx_t daddr0;
  volatile dmac_dscrx_t dscr0;
  volatile dmac_ctrlax_t ctrla0;
  volatile dmac_ctrlbx_t ctrlb0;
  volatile dmac_cfgx_t cfg0;
  uint32_t reserved3;
  uint32_t reserved4;
  uint32_t reserved5;
  uint32_t reserved6;
  volatile dmac_saddrx_t saddr1;
  volatile dmac_daddrx_t daddr1;
  volatile dmac_dscrx_t dscr1;
  volatile dmac_ctrlax_t ctrla1;
  volatile dmac_ctrlbx_t ctrlb1;
  volatile dmac_cfgx_t cfg1;
  uint32_t reserved7;
  uint32_t reserved8;
  uint32_t reserved9;
  uint32_t reserved10;
  volatile dmac_saddrx_t saddr2;
  volatile dmac_daddrx_t daddr2;
  volatile dmac_dscrx_t dscr2;
  volatile dmac_ctrlax_t ctrla2;
  volatile dmac_ctrlbx_t ctrlb2;
  volatile dmac_cfgx_t cfg2;
  uint32_t reserved11;
  uint32_t reserved12;
  uint32_t reserved13;
  uint32_t reserved14;
  volatile dmac_saddrx_t saddr3;
  volatile dmac_daddrx_t daddr3;
  volatile dmac_dscrx_t dscr3;
  volatile dmac_ctrlax_t ctrla3;
  volatile dmac_ctrlbx_t ctrlb3;
  volatile dmac_cfgx_t cfg3;
}  __attribute__((__packed__)) dmac_t;

volatile dmac_t* DMAC = (volatile dmac_t *) 0x400B0000; // DMAC Base Address
//volatile dmac_gcfg_t* SREQ = (volatile dmac_gcfg_t *) 0x400B0008;

/*

*/


/*
typedef enum {
  DMAC_SINGLE_TRANSFER               = 0x0,
  DMAC_BLOCK_TRANSFER                = 0x1,
  DMAC_BURST_BLOCK_TRANSFER          = 0x2,
  DMAC_REPEATED_SINGLE_TRANSFER      = 0x4,
  DMAC_REPEATED_BLOCK_TRANSFER       = 0x5,
  DMAC_REPEATED_BURST_BLOCK_TRANSFER = 0x7
} dmac_transfer_mode_t;
*/

typedef enum {
  ONE_DATA_TRANSFERRED  = 0x0,
  FOUR_DATA_TRANSFERRED = 0x1
} dmac_chunk_t;

typedef enum {
  SINGLE_TRANSFER_SIZE_BYTE      = 0x0,
  SINGLE_TRANSFER_SIZE_HALF_WORD = 0x1,
  SINGLE_TRANSFER_SIZE_WORD      = 0x2
} dmac_width_t;

typedef enum {
  MEMORY_TO_MEMORY         = 0x0,
  MEMORY_TO_PERIPHERAL     = 0x1,
  PERIPHERAL_TO_MEMORY     = 0x2,
  PERIPHERAL_TO_PERIPHERAL = 0x3
} dmac_fc_t;

typedef enum {
  ADDRESS_UPDATE_MEMORY   = 0x0,
  ADDRESS_UPDATE_DISABLED = 0x1
} dmac_dscr_t;

typedef enum {
  INCREMENTING_ADDRESS  = 0x0,
  FIXED_ADDRESS         = 0x1
} dmac_inc_t;

typedef enum {
  LOCK_MASTER_ARBITOR_CHUNK  = 0x0,
  LOCK_MASTER_ABRITOR_BUFFER = 0x1
} dmac_IFL_t;

typedef enum {
  DATA_ACCESS_USER_ACCESS_NO_BUFFER_NO_CACHE = 0x1,
  DATA_ACCESS_PRIV_ACCESS_NO_BUFFER_NO_CACHE = 0x3,
  DATA_ACCESS_USER_ACCESS_BUFFER_NO_CACHE    = 0x5,
  DATA_ACCESS_PRIV_ACCESS_BUFFER_NO_CACHE    = 0x7,
  DATA_ACCESS_USER_ACCESS_NO_BUFFER_CACHE    = 0x9,
  DATA_ACCESS_PRIV_ACCESS_NO_BUFFER_CACHE    = 0xB,
  DATA_ACCESS_USER_ACCESS_BUFFER_CACHE       = 0xD,
  DATA_ACCESS_PRIV_ACCESS_BUFFER_CACHE       = 0xF
} dmac_ahbprot_t;

typedef enum {
  LARGEST_LENGTH_AHB_BURST_DST = 0x0,
  SERV_HALF_FIFO               = 0x1,
  SERV_ENOUGH_FIFO             = 0x2
} dmac_fifocfg_t;

#endif
