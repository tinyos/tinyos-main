/**
 * Copyright (c) 2005-2006 Arch Rock Corporation
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
 * - Neither the name of the Arch Rock Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * ARCHED ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

/**
 * "Copyright (c) 2000-2005 The Regents of the University of California.  
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
 * @author Ben Greenstein <ben@cs.ucla.edu>
 * @author Jonathan Hui <jhui@archrock.com>
 * @author Mark Hays
 * $Revision: 1.5 $ $Date: 2007-11-08 21:34:42 $
 */

#ifndef MSP430DMA_H
#define MSP430DMA_H

// General stuff
enum {
  DMA_CHANNELS = 3
};

enum {
  DMA_CHANNEL0 = 0,
  DMA_CHANNEL1 = 1,
  DMA_CHANNEL2 = 2,
  DMA_CHANNEL_UNKNOWN = 3
};

enum { 
  DMA_CHANNEL_AVAILABLE = 0,
  DMA_CHANNEL_IN_USE    = 1
};

////////////////////////////////////////
// Per-channel fields in DMACTL0
enum {
  DMA0TSEL_SHIFT = 0,
  DMA1TSEL_SHIFT = 4,
  DMA2TSEL_SHIFT = 8,
  DMATSEL_MASK   = (uint16_t)0xf,
  DMA0TSEL_MASK  = ( 0xf ),
  DMA1TSEL_MASK  = ( 0xf0 ),
  DMA2TSEL_MASK  = ( 0xf00 ),
};

// Per-field (channel) in DMACTL0
typedef enum {
  DMA_TRIGGER_DMAREQ =          0x0, // software trigger
  DMA_TRIGGER_TACCR2 =          0x1,            
  DMA_TRIGGER_TBCCR2 =          0x2,
  DMA_TRIGGER_URXIFG0 =         0x3, // RX on USART0 (UART/SPI)
  DMA_TRIGGER_UTXIFG0 =         0x4, // TX on USART0 (UART/SPI)
  DMA_TRIGGER_DAC12IFG =        0x5, // DAC12_0CTL DAC12IFG bit
  DMA_TRIGGER_ADC12IFGx =       0x6, 
  DMA_TRIGGER_TACCR0 =          0x7, // CCIFG bit
  DMA_TRIGGER_TBCCR0 =          0x8, // CCIFG bit
  DMA_TRIGGER_URXIFG1 =         0x9, // RX on USART1 (UART/SPI)
  DMA_TRIGGER_UTXIFG1 =         0xa, // TX on USART1 (UART/SPI)
  DMA_TRIGGER_MULT =            0xb, // Hardware Multiplier Ready
  DMA_TRIGGER_DMAxIFG =         0xe, // DMA0IFG triggers DMA channel 1
                                     // DMA1IFG triggers DMA channel 2
                                     // DMA2IFG triggers DMA channel 0
  DMA_TRIGGER_DMAE0 =           0xf  // External Trigger DMAE0
} dma_trigger_t;

typedef struct dma_channel_trigger_s {
  unsigned int trigger : 4; 
  unsigned int reserved : 12;
} __attribute__ ((packed)) dma_channel_trigger_t;

////////////////////////////////////////
// Bits in DMACTL1
enum {
  DISABLE_NMI = 0,
  ENABLE_NMI  = 1,
};

enum {
  NOT_ROUND_ROBIN = 0,
  ROUND_ROBIN     = 1,
};

enum {
  NOT_ON_FETCH = 0,
  ON_FETCH     = 1,
};

typedef struct dma_state_s {
  unsigned int enableNMI : 1;
  unsigned int roundRobin : 1;
  unsigned int onFetch : 1;
  unsigned int reserved : 13;
} __attribute__ ((packed)) dma_state_t;

////////////////////////////////////////
// Stuff in DMAxCTL

// DMADTx
enum {
  DMADT_SHIFT = 12,
  DMADT_MASK  = 0x7,
};

typedef enum {
  DMA_SINGLE_TRANSFER               = 0x0,
  DMA_BLOCK_TRANSFER                = 0x1,
  DMA_BURST_BLOCK_TRANSFER          = 0x2,
  DMA_REPEATED_SINGLE_TRANSFER      = 0x4,
  DMA_REPEATED_BLOCK_TRANSFER       = 0x5,
  DMA_REPEATED_BURST_BLOCK_TRANSFER = 0x7
} dma_transfer_mode_t;

// DMA{SRC,DST}INCRx
enum {
  DMASRCINCR_SHIFT = 8,
  DMADSTINCR_SHIFT = 10,
  DMAINCR_MASK     = 0x3,
};

typedef enum {
  DMA_ADDRESS_UNCHANGED   = 0x0,
  DMA_ADDRESS_DECREMENTED = 0x2,
  DMA_ADDRESS_INCREMENTED = 0x3
} dma_incr_t;

typedef enum {
  DMA_WORD = 0x0,
  DMA_BYTE = 0x1
} dma_byte_t;

// DMALEVEL
typedef enum {
  DMA_EDGE_SENSITIVE  = 0x0,
  DMA_LEVEL_SENSITIVE = 0x1
} dma_level_t;

typedef struct dma_channel_state_s {
  unsigned int request : 1;
  unsigned int abort : 1;
  unsigned int interruptEnable : 1;
  unsigned int interruptFlag : 1;
  unsigned int enable : 1;
  unsigned int level : 1;            /* or edge- triggered */
  unsigned int srcByte : 1;          /* or word */
  unsigned int dstByte : 1;
  unsigned int srcIncrement : 2;     /* or no-increment, decrement */
  unsigned int dstIncrement : 2;
  unsigned int transferMode : 3;
  unsigned int reserved2 : 1;
} __attribute__ ((packed)) dma_channel_state_t;

#endif

