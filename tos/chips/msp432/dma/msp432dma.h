/*
 * Copyright (c) 2016 Eric B. Decker
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 *
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 *
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
 *
 * @author Eric B. Decker <cire831@gmail.com>
 *
 * Support the msp432 dma engine for the TI MSP432P401{m,r}
 * (see TI MSP432P4xx Family Technical Reference Manual slau356).
 *
 * msp432:  __MCU_HAS_DMA__
 */

#ifndef __MSP432DMA_H__
#define __MSP432DMA_H__

#include <msp432.h>

typedef struct {
  volatile uint32_t src_end;
  volatile uint32_t dst_end;
  volatile uint32_t control;
  volatile uint32_t pad;
} dma_cb_t;


/*
 * The DMA can be triggered by the following src triggers.  These are the
 * only h/w peripheral bits that can trigger dma activity.
 */

typedef enum {
  MSP432_DMA_CHX_NONE = 0,

  MSP432_DMA_CH0_A0_TX   = 1,
  MSP432_DMA_CH0_B0_TX0  = 2,
  MSP432_DMA_CH0_B3_TX1  = 3,
  MSP432_DMA_CH0_B2_TX2  = 4,
  MSP432_DMA_CH0_B1_TX3  = 5,
  MSP432_DMA_CH0_TA0CCR0 = 6,
  MSP432_DMA_CH0_AES_T0  = 7,

  MSP432_DMA_CH1_A0_RX   = 1,
  MSP432_DMA_CH1_B0_RX0  = 2,
  MSP432_DMA_CH1_B3_RX1  = 3,
  MSP432_DMA_CH1_B2_RX2  = 4,
  MSP432_DMA_CH1_B1_RX3  = 5,
  MSP432_DMA_CH1_TA0CCR2 = 6,
  MSP432_DMA_CH1_AES_T1  = 7,

  MSP432_DMA_CH2_A1_TX   = 1,
  MSP432_DMA_CH2_B1_TX0  = 2,
  MSP432_DMA_CH2_B0_TX1  = 3,
  MSP432_DMA_CH2_B3_TX2  = 4,
  MSP432_DMA_CH2_B2_TX3  = 5,
  MSP432_DMA_CH2_TA1CCR0 = 6,
  MSP432_DMA_CH2_AES_T2  = 7,

  MSP432_DMA_CH3_A1_RX   = 1,
  MSP432_DMA_CH3_B1_RX0  = 2,
  MSP432_DMA_CH3_B0_RX1  = 3,
  MSP432_DMA_CH3_B3_RX2  = 4,
  MSP432_DMA_CH3_B2_RX3  = 5,
  MSP432_DMA_CH3_TA1CCR2 = 6,

  MSP432_DMA_CH4_A2_TX   = 1,
  MSP432_DMA_CH4_B2_TX0  = 2,
  MSP432_DMA_CH4_B1_TX1  = 3,
  MSP432_DMA_CH4_B0_TX2  = 4,
  MSP432_DMA_CH4_B3_TX3  = 5,
  MSP432_DMA_CH4_TA2CCR0 = 6,

  MSP432_DMA_CH5_A2_RX   = 1,
  MSP432_DMA_CH5_B2_RX0  = 2,
  MSP432_DMA_CH5_B1_RX1  = 3,
  MSP432_DMA_CH5_B0_RX2  = 4,
  MSP432_DMA_CH5_B3_RX3  = 5,
  MSP432_DMA_CH5_TA2CCR2 = 6,

  MSP432_DMA_CH6_A3_TX   = 1,
  MSP432_DMA_CH6_B3_TX0  = 2,
  MSP432_DMA_CH6_B2_TX1  = 3,
  MSP432_DMA_CH6_B1_TX2  = 4,
  MSP432_DMA_CH6_B0_TX3  = 5,
  MSP432_DMA_CH6_TA3CCR0 = 6,
  MSP432_DMA_CH6_DMAE0   = 7,

  MSP432_DMA_CH7_A3_RX   = 1,
  MSP432_DMA_CH7_B3_RX0  = 2,
  MSP432_DMA_CH7_B2_RX1  = 3,
  MSP432_DMA_CH7_B1_RX2  = 4,
  MSP432_DMA_CH7_B0_RX3  = 5,
  MSP432_DMA_CH7_TA3CCR2 = 6,
  MSP432_DMA_CH7_ADC14   = 7,
} msp432_dma_trigger_t;

#define MSP432_DMA_SIZE_8       0x00000000
#define MSP432_DMA_SIZE_16      0x11000000
#define MSP432_DMA_SIZE_32      0x22000000

#define MSP432_DMA_MODE_NONE            0
#define MSP432_DMA_MODE_BASIC           1
#define MSP432_DMA_MODE_AUTO            2
#define MSP432_DMA_MODE_PINGPONG        3
#define MSP432_DMA_MODE_MEM_SG          4
#define MSP432_DMA_MODE_MEM_SG_ALT      5
#define MSP432_DMA_MODE_PER_SG          6
#define MSP432_DMA_MODE_PER_SG_ALT      7

#endif          /* __MSP432DMA_H__ */
