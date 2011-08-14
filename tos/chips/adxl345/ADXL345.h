/*
 * Copyright (c) 2009 DEXMA SENSORS SL
 * Copyright (c) 2011 ZOLERTIA LABS
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
 */

/*
 * Implementation of ADXL345 accelerometer, as a part of Zolertia Z1 mote
 *
 * Credits goes to DEXMA SENSORS SL
 * @author: Xavier Orduna <xorduna@dexmatech.com>
 * @author: Jordi Soucheiron <jsoucheiron@dexmatech.com>
 * @author: Antonio Linan <alinan@zolertia.com>
 * 
 */

#ifndef ADXL345_H

#define ADXL345_H
  
#define ADXL345_ADDRESS		0x53

//ADXL345 Registers Start
#define ADXL345_DEVID		0x00	// R  // Device ID.
#define ADXL345_THRESH_TAP	0x1D	// RW // Tap Threshold 62.5mg/LSB (0xFF = +16g)
#define ADXL345_OFSX		0x1E	// RW // X-axis Offset 15.6mg/LSB
#define ADXL345_OFSY		0x1F	// RW // Y-axis Offset 15.6mg/LSB
#define ADXL345_OFSZ		0x20	// RW // Z-axis Offset 15.6mg/LSB
#define ADXL345_DUR		0x21	// RW // Tap Duration 625us/LSB
#define ADXL345_LATENT		0x22	// RW // Tap Latency 1.25ms/LSB
#define ADXL345_WINDOW		0x23	// RW // Tap Window 1.25ms/LSB
#define ADXL345_THRESH_ACT	0x24	// RW // Activity threshold 62.5mg/LSB
#define ADXL345_THRESH_INACT	0x25	// RW // Inactivity Threshold 62.5mg/LSB
#define ADXL345_TIME_INACT	0x26	// RW // Inactivity Time. 1s/LSB
#define ADXL345_ACT_INACT_CTL	0x27	// RW // xis enable control for activity and inactivity detection.
#define ADXL345_THRESH_FF	0x28	// RW // Free-fall threshold. 62.5mg/LSB
#define ADXL345_TIME_FF		0x29	// RW // Free-fall Time 5ms/LSB (values 0x14 to 0x46 are recommended)
#define ADXL345_TAP_AXES	0x2A	// RW // Axis control for tap/double tap
#define ADXL345_ACT_TAP_STATUS	0x2B	// R  // Source of tap/double tap
#define ADXL345_BW_RATE		0x2C	// RW // Data rate and power control mode (default 0xA)
#define ADXL345_POWER_CTL 	0x2D	// RW // Power saving features control
#define ADXL345_INT_ENABLE	0x2E	// RW // Interrupt enable control
#define ADXL345_INT_MAP		0x2F	// RW // Interrupt mapping control
#define ADXL345_INT_SOURCE	0x30	// R  // Source of interrupts
#define ADXL345_DATAFORMAT	0x31	// RW // Data format control
#define ADXL345_DATAX0		0x32	// R  // X-Axis
#define ADXL345_DATAY0		0x34	// R  // Y-Axis
#define ADXL345_DATAZ0		0x36	// R  // Z-Axis
#define ADXL345_FIFO_CTL	0x38	// RW // FIFO control
#define ADXL345_FIFO_STATE 	0x39	// R  // FIFO status
//ADXL Registers End


#define ADXL345_MEASURE_MODE	0x08
#define ADXL345_STANDBY_MODE	0xF7
#define ADXL345_SLEEP_MODE	0x04

#define ADXL345_RANGE_2G	0
#define ADXL345_RANGE_4G	1
#define ADXL345_RANGE_8G	2
#define ADXL345_RANGE_16G	3
  
#define ADXL345_LOWRES		0
#define ADXL345_FULLRES		1

#define ADXL345_START_TIMEOUT	2000

//ADXL345 Driver States States

typedef enum {
  ADXLCMD_START,
  ADXLCMD_READ_REGISTER,
  ADXLCMD_READ_DURATION,
  ADXLCMD_READ_LATENT,
  ADXLCMD_READ_WINDOW,
  ADXLCMD_READ_THRESH_ACT,	//TODO
  ADXLCMD_READ_THRESH_INACT,	//TODO
  ADXLCMD_READ_TIME_INACT,	//TODO
  ADXLCMD_READ_ACT_INACT_CTL,	//TODO
  ADXLCMD_READ_THRESH_FF,	//TODO
  ADXLCMD_READ_TIME_FF,		//TODO
  ADXLCMD_READ_TAP_AXES,	//TODO
  ADXLCMD_READ_ACT_TAP_STATUS,	//TODO
  ADXLCMD_READ_BW_RATE,		//TODO
  ADXLCMD_READ_POWER_CTL,	//TODO
  ADXLCMD_READ_INT_ENABLE,
  ADXLCMD_READ_INT_MAP,
  ADXLCMD_READ_INT_SOURCE,
  ADXLCMD_READ_X,
  ADXLCMD_READ_Y,
  ADXLCMD_READ_Z,
  ADXLCMD_READ_XYZ,
  ADXLCMD_SET_RANGE,
  ADXLCMD_STOP,
  ADXLCMD_SLEEP,
  ADXLCMD_INT,
  ADXLCMD_SET_REGISTER,
  ADXLCMD_SET_DURATION,
  ADXLCMD_SET_LATENT,
  ADXLCMD_SET_WINDOW,
  ADXLCMD_SET_INT_MAP,
} adxl345_commands;

//ADXL345 Interruptions


typedef enum {
  ADXLINT_NONE =	0x00,
  ADXLINT_OVERRUN = 	0x01,
  ADXLINT_WATERMARK = 	0x02,
  ADXLINT_FREE_FALL = 	0x04,
  ADXLINT_INACTIVITY = 	0x08,
  ADXLINT_ACTIVITY = 	0x10,
  ADXLINT_DOUBLE_TAP = 	0x20,
  ADXLINT_SINGLE_TAP = 	0x40,
  ADXLINT_DATA_READY = 	0x80,
} adxlint_state_t;

typedef struct {
  uint16_t x_axis;
  uint16_t y_axis;
  uint16_t z_axis;
} adxl345_readxyt_t;
  
#endif
