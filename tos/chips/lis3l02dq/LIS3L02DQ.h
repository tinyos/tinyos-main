/*
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
 * Types and definitions for the ST LIS3L02DQ 3-axis Accelerometer
 *
 * @author Phil Buonadonna <pbuonadonna@archrock.com>
 * @version $Revision: 1.3 $ $Date: 2006-11-07 19:30:54 $
 */

#ifndef _LIS3L02DQ_H
#define _LIS3L02DQ_H

#define LIS3L02DQ_OFFSET_X		(0x16)
#define LIS3L02DQ_OFFSET_Y		(0x17)
#define LIS3L02DQ_OFFSET_Z		(0x18)
#define LIS3L02DQ_GAIN_X		(0x19)
#define LIS3L02DQ_GAIN_Y		(0x1A)
#define LIS3L02DQ_GAIN_Z		(0x1B)

#define LIS3L02DQ_CTRL_REG1		(0x20)
#define LIS3L02DQ_CTRL_REG2		(0x21)

#define LIS3L02DQ_WAKE_UP_CFG		(0x23)
#define LIS3L02DQ_WAKE_UP_SRC		(0x24)
#define LIS3L02DQ_WAKE_UP_ACK		(0x25)

#define LIS3L02DQ_STATUS_REG		(0x27)

#define LIS3L02DQ_OUTX_L		(0x28)
#define LIS3L02DQ_OUTX_H		(0x29)
#define LIS3L02DQ_OUTY_L		(0x2A)
#define LIS3L02DQ_OUTY_H		(0x2B)
#define LIS3L02DQ_OUTZ_L		(0x2C)
#define LIS3L02DQ_OUTZ_H		(0x2D)

#define LIS3L02DQ_THS_L			(0x2E)
#define LIS3L02DQ_THS_H			(0x2F)

#define LIS3L01DQ_CTRL_REG1_PD(_x)	(((_x) & 0x3) << 6)
#define LIS3L01DQ_CTRL_REG1_DF(_x)	(((_x) & 0x3) << 4)
#define LIS3L01DQ_CTRL_REG1_ST		(1 << 3)
#define LIS3L01DQ_CTRL_REG1_ZEN		(1 << 2)
#define LIS3L01DQ_CTRL_REG1_YEN		(1 << 1)
#define LIS3L01DQ_CTRL_REG1_XEN		(1 << 0)

#define LIS3L01DQ_CTRL_REG2_RES		(1 << 7)
#define LIS3L01DQ_CTRL_REG2_BDU		(1 << 6)
#define LIS3L01DQ_CTRL_REG2_BLE		(1 << 5)
#define LIS3L01DQ_CTRL_REG2_BOOT	(1 << 4)
#define LIS3L01DQ_CTRL_REG2_IEN		(1 << 3)
#define LIS3L01DQ_CTRL_REG2_DRDY	(1 << 2)
#define LIS3L01DQ_CTRL_REG2_SIM		(1 << 1)
#define LIS3L01DQ_CTRL_REG2_DAS		(1 << 0)

#define LIS3L02DQ_WAKE_UP_CFG_AOI	(1 << 7)
#define LIS3L02DQ_WAKE_UP_CFG_LIR	(1 << 6)
#define LIS3L02DQ_WAKE_UP_CFG_ZHIE	(1 << 5)
#define LIS3L02DQ_WAKE_UP_CFG_ZLIE	(1 << 4)
#define LIS3L02DQ_WAKE_UP_CFG_YHIE	(1 << 3)
#define LIS3L02DQ_WAKE_UP_CFG_YLIE	(1 << 2)
#define LIS3L02DQ_WAKE_UP_CFG_XHIE	(1 << 1)
#define LIS3L02DQ_WAKE_UP_CFG_XLIE	(1 << 0)

typedef enum {
  LIS_AFLAGS_NONE,
  LIS_AFLAGS_HIGH,
  LIS_AFLAGS_LOW,
  LIS_AFLAGS_BOTH
} lis_alertflags_t;

#endif /* _LIS3L02DQ_H */
