/*
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
 * High Speed USB Device Port register definitions.
 *
 * @author Kevin Klues
 */

#ifndef _SAM3UUDPHSHARDWARE_H
#define _SAM3UUDPHSHARDWARE_H

#include <sam3unvichardware.h>

// Resource definition
#define SAM3U_UDPHS_RESOURCE "Sam3uUdphs.Resource"

//Defines needed by Atmel USB framework
typedef irqn_t IRQn_Type;

/**
 *  UDPHS Control Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 973
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint32_t dev_addr     :  7;
    uint32_t faddr_en     :  1;
    uint32_t en_udphs     :  1;
    uint32_t detach       :  1;
    uint32_t rewakeup     :  1;
    uint32_t pulld_dis    :  1;
    uint32_t reserved     :  20;
  } __attribute__((__packed__)) bits;
} udphs_ctrl_t;

/**
 *  UDPHS Frame Number Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 975
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint32_t micro_frame_num    : 3;
    uint32_t frame_number       : 11;
    uint32_t reserved           : 17;
    uint32_t fnum_err           : 1;
  } __attribute__((__packed__)) bits;
} udphs_fnum_t;

/**
 *  UDPHS Interrupt Enable Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 976
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint32_t reserved0         : 1;
    uint32_t det_suspd         : 1;
    uint32_t micro_sof         : 1;
    uint32_t int_sof           : 1;
    uint32_t endreset          : 1;
    uint32_t wake_up           : 1;
    uint32_t endofrsm          : 1;
    uint32_t upstr_res         : 1;
    uint32_t ept_0             : 1;
    uint32_t ept_1             : 1;
    uint32_t ept_2             : 1;
    uint32_t ept_3             : 1;
    uint32_t ept_4             : 1;
    uint32_t ept_5             : 1;
    uint32_t ept_6             : 1;
    uint32_t reserved1         : 10;
    uint32_t dma_1             : 1;
    uint32_t dma_2             : 1;
    uint32_t dma_3             : 1;
    uint32_t dma_4             : 1;
    uint32_t dma_r             : 1;
    uint32_t dma_6             : 1;
    uint32_t reserved2         : 1;
  } __attribute__((__packed__)) bits;
} udphs_ien_t;

/**
 *  UDPHS Interrupt Status Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 979
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint32_t speed         : 1;
    uint32_t det_suspd     : 1;
    uint32_t micro_sof     : 1;
    uint32_t int_sof       : 1;
    uint32_t endreset      : 1;
    uint32_t wake_up       : 1;
    uint32_t endofrsm      : 1;
    uint32_t upstr_res     : 1;
    uint32_t ept_0         : 1;
    uint32_t ept_1         : 1;
    uint32_t ept_2         : 1;
    uint32_t ept_3         : 1;
    uint32_t ept_4         : 1;
    uint32_t ept_5         : 1;
    uint32_t ept_6         : 1;
    uint32_t reserved0     : 10;
    uint32_t dma_1         : 1;
    uint32_t dma_2         : 1;
    uint32_t dma_3         : 1;
    uint32_t dma_4         : 1;
    uint32_t dma_5         : 1;
    uint32_t dma_6         : 1;
    uint32_t reserved1     : 1;
  } __attribute__((__packed__)) bits;
} udphs_intsta_t;          

/**
 *  UDPHS Clear Interrupt Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 981
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint32_t reserved0   : 1;
    uint32_t det_suspd   : 1;
    uint32_t micro_sof   : 1;
    uint32_t int_sof     : 1;
    uint32_t endreset    : 1;
    uint32_t wake_up     : 1;
    uint32_t endofrsm    : 1;
    uint32_t upstr_res   : 1;
    uint32_t reserved1   : 24;
  } __attribute__((__packed__)) bits;
} udphs_clrint_t;

/**
 *  UDPHS Endpoints Reset Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 982
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint32_t ept_0      : 1;
    uint32_t ept_1      : 1;
    uint32_t ept_2      : 1;
    uint32_t ept_3      : 1;
    uint32_t ept_4      : 1;
    uint32_t ept_5      : 1;
    uint32_t ept_6      : 1;
    uint32_t reserved   : 25;
  } __attribute__((__packed__)) bits;
} udphs_eptrst_t;

/**
 *  UDPHS Test Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 983
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint32_t speed_cfg  : 2;
    uint32_t tst_j      : 1;
    uint32_t tst_k      : 1;
    uint32_t tst_pkt    : 1;
    uint32_t opmode2    : 1;
    uint32_t reserved   : 26;
  } __attribute__((__packed__)) bits;
} udphs_tst_t;

/**
 *  UDPHS Name1 Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 985
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint32_t ip_name1 : 32;
  } __attribute__((__packed__)) bits;
} udphs_ipname1_t;

/**
 *  UDPHS Name2 Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 986
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint32_t ip_name2 : 32;
  } __attribute__((__packed__)) bits;
} udphs_ipname2_t;

/**
 *  UDPHS Features Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 987
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint32_t ept_nbr_max           : 4;
    uint32_t dma_channel_nbr       : 3;
    uint32_t dma_b_siz             : 1;
    uint32_t dma_fifo_word_depth   : 4;
    uint32_t fifo_max_size         : 3;
    uint32_t bw_dpram              : 1;
    uint32_t datab16_8             : 1;
    uint32_t iso_ept_1             : 1;
    uint32_t iso_ept_2             : 1;
    uint32_t iso_ept_3             : 1;
    uint32_t iso_ept_4             : 1;
    uint32_t iso_ept_5             : 1;
    uint32_t iso_ept_6             : 1;
    uint32_t iso_ept_7             : 1;
    uint32_t iso_ept_8             : 1;
    uint32_t iso_ept_9             : 1;
    uint32_t iso_ept_10            : 1;
    uint32_t iso_ept_11            : 1;
    uint32_t iso_ept_12            : 1;
    uint32_t iso_ept_13            : 1;
    uint32_t iso_ept_14            : 1;
    uint32_t iso_ept_15            : 1;
  } __attribute__((__packed__)) bits;
} udphs_ipfeatures_t;

/**
 *  UDPHS Endpoint Configuration Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 989
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint32_t ept_size      : 3;
    uint32_t ept_dir       : 1;
    uint32_t ept_type      : 2;
    uint32_t bk_number     : 2;
    uint32_t nb_trans      : 2;
    uint32_t reserved      : 21;
    uint32_t ept_mapd      : 1;
  } __attribute__((__packed__)) bits;
} udphs_eptcfg_t;

/**
 *  UDPHS Endpoint Control Enable Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 991
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint32_t ept_enabl         : 1;
    uint32_t auto_valid        : 1;
    uint32_t reserved0         : 1;
    uint32_t intdis_dma        : 1;
    uint32_t nyet_dis          : 1;
    uint32_t reserved1         : 1;
    uint32_t datax_rx          : 1;
    uint32_t mdata_rx          : 1;
    uint32_t err_ovflw         : 1;
    uint32_t rx_bk_rdy         : 1;
    uint32_t tx_complt         : 1;
//    union {                    
      uint32_t tx_pk_rdy       : 1;
//      uint32_t err_trans       : 1;
//    };                         
//    union {                    
      uint32_t rx_setup        : 1;
//      uint32_t err_fl_iso      : 1;
//    };                         
//    union {                    
      uint32_t stall_snt       : 1;
//      uint32_t err_criso       : 1;
//      uint32_t err_nbtra       : 1;
//    };                         
//    union {                    
      uint32_t nak_in          : 1;
//      uint32_t err_flush       : 1;
//    };                         
    uint32_t nak_out           : 1;
    uint32_t reserved2         : 2;
    uint32_t busy_bank         : 1;
    uint32_t reserved3         : 12;
    uint32_t shrt_pckt         : 1;
  } __attribute__((__packed__)) bits;
} udphs_eptctlenb_t;           
                               
/**
 *  UDPHS Endpoint Control Disable Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 993
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint32_t ept_disabl        : 1;
    uint32_t auto_valid        : 1;
    uint32_t reserved0         : 1;
    uint32_t intdis_dma        : 1;
    uint32_t nyet_dis          : 1;
    uint32_t reserved1         : 1;
    uint32_t datax_rx          : 1;
    uint32_t mdata_rx          : 1;
    uint32_t err_ovflw         : 1;
    uint32_t rx_bk_rdy         : 1;
    uint32_t tx_complt         : 1;
//    union {                    
      uint32_t tx_pk_rdy       : 1;
//      uint32_t err_trans       : 1;
//    };                         
//    union {                    
      uint32_t rx_setup        : 1;
//      uint32_t err_fl_iso      : 1;
//    };                         
//    union {                    
      uint32_t stall_snt       : 1;
//      uint32_t err_criso       : 1;
//      uint32_t err_nbtra       : 1;
//    };                         
//    union {                    
      uint32_t nak_in          : 1;
//      uint32_t err_flush       : 1;
//    };                         
    uint32_t nak_out           : 1;
    uint32_t reserved2         : 2;
    uint32_t busy_bank         : 1;
    uint32_t reserved3         : 12;
    uint32_t shrt_pckt         : 1;
  } __attribute__((__packed__)) bits;
} udphs_eptctldis_t;

/**
 *  UDPHS Endpoint Control Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 995
 */
typedef union
{
  uint32_t flat;
  struct
  {                 
    uint32_t ept_enabl         : 1;
    uint32_t auto_valid        : 1;
    uint32_t reserved0         : 1;
    uint32_t intdis_dma        : 1;
    uint32_t nyet_dis          : 1;
    uint32_t reserved1         : 1;
    uint32_t datax_rx          : 1;
    uint32_t mdata_rx          : 1;
    uint32_t err_ovflw         : 1;
    uint32_t rx_bk_rdy         : 1;
    uint32_t tx_complt         : 1;
//    union {                    
      uint32_t tx_pk_rdy       : 1;
//      uint32_t err_trans       : 1;
//    };                         
//    union {                    
      uint32_t rx_setup        : 1;
//      uint32_t err_fl_iso      : 1;
//    };                         
//    union {                    
      uint32_t stall_snt       : 1;
//      uint32_t err_criso       : 1;
//      uint32_t err_nbtra       : 1;
//    };                         
//    union {                    
      uint32_t nak_in          : 1;
//      uint32_t err_flush       : 1;
//    };                         
    uint32_t nak_out           : 1;
    uint32_t reserved2         : 2;
    uint32_t busy_bank         : 1;
    uint32_t reserved3         : 12;
    uint32_t shrt_pckt         : 1;
  } __attribute__((__packed__)) bits;
} udphs_eptctl_t;

/**
 *  UDPHS Endpoint Set Status Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 998
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint32_t reserved0        : 5;
    uint32_t frcestall        : 1;
    uint32_t reserved1        : 3;
    uint32_t kill_bank        : 1;
    uint32_t reserved2        : 1;
    uint32_t tx_pk_rdy        : 1;
    uint32_t reserved3        : 20;
  } __attribute__((__packed__)) bits;
} udphs_eptsetsta_t;

/**
 *  UDPHS Endpoint Clear Status Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 999
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint32_t reserved0      : 5;
    uint32_t frcestall      : 1;
    uint32_t togglesq       : 1;
    uint32_t reserved1      : 2;
    uint32_t rx_bk_rdy      : 1;
    uint32_t tx_complt      : 1;
    uint32_t reserved3      : 1;
//    union {
      uint32_t rx_setup     : 1;
//      uint32_t err_fl_iso   : 1;
//    };
//    union {
      uint32_t stall_snt    : 1;
//      uint32_t err_nbtra    : 1;
//    };
//    union {
      uint32_t nak_in       : 1;
//      uint32_t err_flush    : 1;
//    };
    uint32_t nak_out        : 1;
    uint32_t reserved4      : 16;
  } __attribute__((__packed__)) bits;
} udphs_eptclrsta_t;

/**
 *  UDPHS Endpoint Status Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 999
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint32_t reserved            : 5;
    uint32_t frcestall           : 1;
    uint32_t togglesq_sta        : 2;
    uint32_t err_ovflw           : 1;
//    union {
      uint32_t rx_bk_rdy         : 1;
//      uint32_t kill_bank         : 1;
//    };                       
    uint32_t tx_complt           : 1;
//    union {
      uint32_t tx_pk_rdy         : 1;
//      uint32_t err_trans         : 1;
//    };                       
//    union {                  
      uint32_t rx_setup          : 1;
//      uint32_t err_fl_iso        : 1;
//    };
//    union {
      uint32_t stall_snt         : 1;
//      uint32_t err_criso         : 1;
//      uint32_t err_nbtra         : 1;
//    };                       
//    union {                  
      uint32_t nak_in            : 1;
//      uint32_t err_flush         : 1;
//    };
    uint32_t nak_out             : 1;
//    union {                  
      uint32_t current_bank      : 2;
//      uint32_t control_dir       : 2;
//    };
    uint32_t busy_bank_sta       : 2;
    uint32_t byte_count          : 11;
    uint32_t shrt_pckt           : 1;
  } __attribute__((__packed__)) bits;
} udphs_eptsta_t;

/**
 *  UDPHS DMA Next Descriptor Address Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 1007
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint32_t nxt_dsc_add : 32;
  } __attribute__((__packed__)) bits;
} udphs_dmanxtdsc_t;

/**
 *  UDPHS DMA Channel Address Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 1008
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint32_t buff_add : 32;
  } __attribute__((__packed__)) bits;
} udphs_dmaaddress_t;

/**
 *  UDPHS DMA Channel Control Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 1009
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint32_t chann_enb         : 1;
    uint32_t ldnxt_dsc         : 1;
    uint32_t end_tr_en         : 1;
    uint32_t end_b_en          : 1;
    uint32_t end_tr_it         : 1;
    uint32_t end_buffit        : 1;
    uint32_t desc_ld_it        : 1;
    uint32_t burst_lck         : 1;
    uint32_t reserved          : 8;
    uint32_t buff_length       : 16;
  } __attribute__((__packed__)) bits;
} udphs_dmacontrol_t;

/**
 *  UDPHS DMA Channel Status Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 1011
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint32_t chann_enb        : 1;
    uint32_t chann_act        : 1;
    uint32_t reserved0        : 2;
    uint32_t end_tr_st        : 1;
    uint32_t end_bf_st        : 1;
    uint32_t desc_ldst        : 1;
    uint32_t reserved1        : 9;
    uint32_t buff_count       : 16;
  } __attribute__((__packed__)) bits;
} udphs_dmastatus_t;

/**
 * UDPHS Register definitions, AT91 ARM Cortex-M3 based Microcontrollers SAM3U
 * Series, Preliminary, p. 972
 */
typedef struct {
  udphs_eptcfg_t         cfg;
  udphs_eptctlenb_t      ctlenb;
  udphs_eptctldis_t      ctldis;
  udphs_eptctl_t         ctl;
  uint32_t               endpoint;
  udphs_eptsetsta_t      setsta;
  udphs_eptclrsta_t      crlsta;
  udphs_eptsta_t         sta;
} udphs_ept_t;

typedef struct {
  udphs_dmanxtdsc_t      nxtdsc;
  udphs_dmaaddress_t     address;
  udphs_dmacontrol_t     control;
  udphs_dmastatus_t      status;
} udphs_dma_t;

typedef struct udphs
{
  volatile udphs_ctrl_t        ctrl;
  volatile udphs_fnum_t        fnum;
  uint32_t                     reserved0[2];
  volatile udphs_ien_t         ien;
  volatile udphs_intsta_t      intsta;
  volatile udphs_clrint_t      clrint;
  volatile udphs_eptrst_t      eptrst;
  uint32_t                     reserved1[48]; //Data sheet range is wrong....
  volatile udphs_tst_t         tst;
  uint32_t                     reserved2[3]; // Data sheet range wrong here too....
  volatile udphs_ipname1_t     ipname1;
  volatile udphs_ipname2_t     ipname2;
  volatile udphs_ipfeatures_t  ipfeatures;
  uint32_t                     reserved3[1]; // Not even listed on data sheet...
  volatile udphs_ept_t         ept[7];
  uint32_t                     reserved4[72];
  udphs_dma_t                  reserved_dma0;
  volatile udphs_dma_t         dma[5];
} udphs_t;

/**
 * Memory mapping for the UDPHS controller
 */
volatile udphs_t* UDPHS = (volatile udphs_t *) 0x400A4000;

// Valid endpoint sizes
enum {
  EPT_SIZE_8,
  EPT_SIZE_16,
  EPT_SIZE_32,
  EPT_SIZE_64,
  EPT_SIZE_128,
  EPT_SIZE_256,
  EPT_SIZE_512,
  EPT_SIZE_1024,
};

// Valid endpoint directions
enum {
  EPT_DIR_OUT,
  EPT_DIR_IN,
  #define EPT_DIR_DONTCARE EPT_DIR_OUT
};

// Valid endpoint transfer types
enum {
  EPT_CTRL,
  EPT_ISO,
  EPT_BULK,
  EPT_INT,
};

#endif
