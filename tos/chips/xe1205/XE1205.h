/* 
 * Copyright (c) 2005, Ecole Polytechnique Federale de Lausanne (EPFL)
 * and Shockfish SA, Switzerland.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Ecole Polytechnique Federale de Lausanne (EPFL) 
 *   and Shockfish SA, nor the names of its contributors may be used to 
 *   endorse or promote products derived from this software without 
 *   specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * ========================================================================
 */
/*
 * XE1205 constants and helper macros and functions.
 *
 */

/**
 * @author Henri Dubois-Ferriere
 * @author Remy Blank
 *
 */


#ifndef _XE1205CONST_H
#define _XE1205CONST_H

#include "AM.h"

typedef nx_struct xe1205_header_t {
  nx_am_addr_t dest;
  nx_am_addr_t source;
  nx_am_id_t type;
  nx_am_group_t group;
} xe1205_header_t;

typedef nx_struct xe1205_footer_t {
  nxle_uint16_t crc;  
} xe1205_footer_t;

typedef nx_struct xe1205_metadata_t {
  nx_uint8_t length;
  nx_uint8_t ack;// xxx this should move to header or footer, leaving it here for now for 1.x compat
} xe1205_metadata_t;


/*
 * Register address generators.
 */
#define XE1205_WRITE(register_)                 (((register_) << 1) | 0x01)
#define XE1205_READ(register_)                  (((register_) << 1) | 0x41)

/**
 * Register addresses.
 */
enum xe1205_register_enums {
  MCParam_0    = 0,
  MCParam_1    = 1,
  MCParam_2    = 2,
  MCParam_3    = 3,
  MCParam_4    = 4,
  IrqParam_5   = 5,
  IrqParam_6   = 6,
  TXParam_7    = 7,
  RXParam_8    = 8,
  RXParam_9    = 9,
  RXParam_10   = 10,
  RXParam_11   = 11,
  RXParam_12   = 12,
  Pattern_13   = 13,
  Pattern_14   = 14,
  Pattern_15   = 15,
  Pattern_16   = 16,
  OscParam_17  = 17,
  OscParam_18  = 18,
  TParam_19    = 19,
  TParam_21    = 21,
  TParam_22    = 22,
  XE1205_RegCount
};

#ifndef TOSH_DATA_LENGTH
#define TOSH_DATA_LENGTH 28
#endif

enum {
  xe1205_mtu=TOSH_DATA_LENGTH + sizeof(xe1205_header_t) + sizeof(xe1205_footer_t)
};

enum {
  data_pattern = 0x893456,
};


typedef enum {
  rx_irq0_none=0,
  rx_irq0_write_byte=1,
  rx_irq0_nFifoEmpty=2,
  rx_irq0_Pattern=3,   
}  xe1205_rx_irq0_src_t;

typedef enum xe1205_rx_irq1_src_t {
  rx_irq1_none=0,
  rx_irq1_FifoFull=1,
  rx_irq1_Rssi=2
} xe1205_rx_irq1_src_t;

// In TX, IRQ0 is always mapped to nFifoEmpty 
typedef enum {
  tx_irq1_FifoFull=0,
  tx_irq1_TxStopped=1
} xe1205_tx_irq1_src_t;


typedef enum {
  xe1205_channelpreset_867mhz=0,
  xe1205_channelpreset_868mhz=1,
  xe1205_channelpreset_869mhz=2,
} xe1205_channelpreset_t;

typedef enum {
  xe1205_txpower_0dbm=0,
  xe1205_txpower_5dbm=1,
  xe1205_txpower_10dbm=2,
  xe1205_txpower_15dbm=3
} xe1205_txpower_t;

typedef enum {
  xe1205_bitrate_152340=152340U,
  xe1205_bitrate_76170=76170U,
  xe1205_bitrate_50780=50780U,
  xe1205_bitrate_38085=38085U,
//   xe1205_bitrate_30468=30468,
//   xe1205_bitrate_19042=19042,
//   xe1205_bitrate_12695=12695,
//   xe1205_bitrate_8017=8017,
//   xe1205_bitrate_4760=4760
} xe1205_bitrate_t;



/**
 * Receiver modes.
 */
enum {
  XE1205_LnaModeA = 0,
  XE1205_LnaModeB = 1
};


/** 
 * Radio Transition times.
 * See Table 4 of the XE1205 data sheet.
 */
enum xe1205_transition_time_enums {
  XE1205_Standby_to_RX_Time = 700,   // RX wakeup time (us), with quartz oscillator enabled
  XE1205_TX_to_RX_Time = 500,    // RX wakeup time (us), with freq. synthesizer enabled
  XE1205_Standby_to_TX_Time = 250,   // TX wakeup time (us), with quartz oscillator enabled
  XE1205_RX_to_TX_Time = 100,    // TX wakeup time (us), with freq. synthesizer enabled
  XE1205_FS_Wakeup_Time = 200,    // Frequency synthesizer wakeup time 
  XE1205_Sleep_to_Standby_Time = 1000    // Quartz oscillator wakeup time ( xxx 7ms for 3rd overtone????)
};

// xxx merge into above enum but check
enum {
  XE1205_Sleep_to_RX_Time = XE1205_Sleep_to_Standby_Time + XE1205_Standby_to_RX_Time, 
  XE1205_Sleep_to_TX_Time = XE1205_Sleep_to_Standby_Time + XE1205_Standby_to_TX_Time
};


#endif /* _XE1205CONST_H */

