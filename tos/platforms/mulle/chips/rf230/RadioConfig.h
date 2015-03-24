/*
 * Copyright (c) 2011 Lulea University of Technology
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

/*
 * Copyright (c) 2007, Vanderbilt University
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
 * - Neither the name of the copyright holder nor the names of
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
 * Author: Miklos Maroti
 */

/**
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 */
#ifndef __RADIOCONFIG_H__
#define __RADIOCONFIG_H__

#include <RF230DriverLayer.h>
#include "Timer.h"

enum
{
	/**
	 * This is the value of the TRX_CTRL_0 register
	 * which configures the output pin currents and the CLKM clock
	 */
	RF230_TRX_CTRL_0_VALUE = 0,

	/**
	 * This is the default value of the CCA_MODE field in the PHY_CC_CCA register
	 * which is used to configure the default mode of the clear channel assessment
	 */
	RF230_CCA_MODE_VALUE = RF230_CCA_MODE_3,

	/**
	 * This is the value of the CCA_THRES register that controls the
	 * energy levels used for clear channel assessment
	 */
	RF230_CCA_THRES_VALUE = 0xC7,
};

/* This is the default value of the TX_PWR field of the PHY_TX_PWR register. 0-15*/
#ifndef RF230_DEF_RFPOWER
#define RF230_DEF_RFPOWER	0
#endif

/* This is the default value of the CHANNEL field of the PHY_CC_CCA register. 11-26*/
#ifndef RF230_DEF_CHANNEL
#define RF230_DEF_CHANNEL	26
#endif

/*
 * This is the command used to calculate the CRC for the RF230 chip. 
 * TODO: Check why the default crcByte implementation is in a different endianness
 */
inline uint16_t RF230_CRCBYTE_COMMAND(uint16_t crc, uint8_t data)
{
    uint8_t lo8 = crc & 0x00FF;
    uint8_t hi8 = (crc >> 8) & 0x00FF;
    data ^= lo8; //lo8 (crc);
    data ^= data << 4;

    return ((((uint16_t)data << 8) | hi8 /*hi8 (crc)*/) ^ (uint8_t)(data >> 4) 
        ^ ((uint16_t)data << 3));
}

/**
 * This is the timer type of the radio alarm interface
 */
typedef TMicro TRadio;
typedef uint16_t tradio_size;

/**
 * The number of alarm ticks per one second
 */
#define RADIO_ALARM_SEC 2500000 // 20MHz / 8

#define RADIO_ALARM_MICROSEC	2.5// RADIO_ALARM_SEC/1000000

/**
 * The base two logarithm of the number of radio alarm ticks per one millisecond
 */
#define RADIO_ALARM_MILLI_EXP	11

/**
 * This sets the number of neighbors the radio stack stores information (like sequence number)
 */
#define RF230_NEIGHBORHOOD_SIZE 5

/**
 * Make PACKET_LINK automaticaly enabled for Ieee154MessageC
 */
#if !defined(TFRAMES_ENABLED) && !defined(PACKET_LINK)
#define PACKET_LINK
#endif

#endif  //__RADIOCONFIG_H__
