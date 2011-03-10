/*
 * Copyright (c) 2011 The Regents of the University  of California.
 * All rights reserved."
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
 *
 */

/**
 * types and register defs for ADE7753 energy meter
 * @author Fred Jiang <fxjiang@eecs.berkeley.edu>
 */

#ifndef __ADE7753_H__
#define __ADE7753_H__

// Register addresses
#define ADE7753_WAVEFORM   0x01
#define ADE7753_AENERGY    0x02
#define ADE7753_RAENERGY   0x03
#define ADE7753_LAENERGY   0x04
#define ADE7753_VAENERGY   0x05
#define ADE7753_RVAENERGY  0x06
#define ADE7753_LVAENERGY  0x07
#define ADE7753_LVARENERGY 0x08
#define ADE7753_MODE       0x09
#define ADE7753_IRQEN      0x0A 
#define ADE7753_STATUS     0x0B
#define ADE7753_RSTATUS    0x0C
#define ADE7753_CH1OS      0x0D
#define ADE7753_CH2OS      0x0E
#define ADE7753_GAIN       0x0F
#define ADE7753_PHCAL      0x10
#define ADE7753_APOS       0x11
#define ADE7753_WGAIN      0x12
#define ADE7753_WDIV       0x13
#define ADE7753_CFNUM      0x14
#define ADE7753_CFDEN      0x15
#define ADE7753_IRMS       0x16
#define ADE7753_VRMS       0x17
#define ADE7753_IRMSOS     0x18
#define ADE7753_VRMSOS     0x19
#define ADE7753_VGAIN      0x1A
#define ADE7753_VADIV      0x1B
#define ADE7753_LINECYC    0x1C
#define ADE7753_ZXTOUT     0x1D
#define ADE7753_SAGCYC     0x1E
#define ADE7753_SAGLVL     0x1F
#define ADE7753_IPKLVL     0x20
#define ADE7753_VPKLVL     0x21
#define ADE7753_IPEAK      0x22
#define ADE7753_RSTIPEAK   0x23
#define ADE7753_VPEAK      0x24
#define ADE7753_RSTVPEAK   0x25
#define ADE7753_TEMP       0x26


// gain settings
#define ADE7753_GAIN_PGA_CH1   0
#define ADE7753_GAIN_SCALE_CH1 3
#define ADE7753_GAIN_PGA_CH2   5

#define ADE7753_GAIN_1  0
#define ADE7753_GAIN_2  1
#define ADE7753_GAIN_4  2
#define ADE7753_GAIN_8  3
#define ADE7753_GAIN_16 4

#define ADE7753_GAIN_SCALE_05   0
#define ADE7753_GAIN_SCALE_025  1
#define ADE7753_GAIN_SCALE_0125 2


// mode settings
#define ADE7753_MODE_DISHPF     0    
#define ADE7753_MODE_DISHLPF2   1
#define ADE7753_MODE_DISCF      2
#define ADE7753_MODE_DISSAG     3
#define ADE7753_MODE_ASUSPEND   4
#define ADE7753_MODE_TEMPSEL    5
#define ADE7753_MODE_SWRST      6
#define ADE7753_MODE_CYCMODE    7
#define ADE7753_MODE_DISH1      8
#define ADE7753_MODE_DISH2      9
#define ADE7753_MODE_SWAP      10
#define ADE7753_MODE_DTRT      11
#define ADE7753_MODE_WAVSEL    13
#define ADE7753_MODE_POAM      15


#define ADE7753_IRQ_AEHF    0
#define ADE7753_IRQ_SAG     1
#define ADE7753_IRQ_CYCEND  2
#define ADE7753_IRQ_WSMP    3
#define ADE7753_IRQ_ZX      4
#define ADE7753_IRQ_TEMP    5
#define ADE7753_IRQ_RESET   6
#define ADE7753_IRQ_AEOF    7
#define ADE7753_IRQ_PKV     8
#define ADE7753_IRQ_PKI     9
#define ADE7753_IRQ_VAEHF  10
#define ADE7753_IRQ_VAEOF  11
#define ADE7753_IRQ_ZXTO   12
#define ADE7753_IRQ_PPOS   13
#define ADE7753_IRQ_PNEG   14

#endif // __ADE7753_H__
