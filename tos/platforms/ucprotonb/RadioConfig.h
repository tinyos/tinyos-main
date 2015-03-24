/*
 * Copyright (c) 2007, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * Author: Miklos Maroti
 */

#ifndef __RADIOCONFIG_H__
#define __RADIOCONFIG_H__

#include <RF212DriverLayer.h>
#include <RFA1DriverLayer.h>
#include <TimerConfig.h>
//#define RADIO_DEBUG
//#define RADIO_DEBUG_MESSAGES
/* * common part  */

/**
 * This is the timer type of the radio alarm interface
 */
typedef T62khz TRadio;
typedef uint32_t tradio_size;

/**
 * The number of radio alarm ticks per one microsecond
 */
#define RADIO_ALARM_MICROSEC	0.0625

/**
 * The base two logarithm of the number of radio alarm ticks per one millisecond
 */
#define RADIO_ALARM_MILLI_EXP	6

/* The number of microseconds a sending mote will wait for an acknowledgement */
#ifdef DEFAULT_RADIO_RF212
	#ifndef SOFTWAREACK_TIMEOUT_PLUS
	#define SOFTWAREACK_TIMEOUT_PLUS	3000
	#endif
#else
	#ifndef SOFTWAREACK_TIMEOUT
	#define SOFTWAREACK_TIMEOUT	1000
	#endif
#endif

//RFA1 part
enum
{
	/**
	 * This is the default value of the CCA_MODE field in the PHY_CC_CCA register
	 * which is used to configure the default mode of the clear channel assesment
	 */
	RFA1_CCA_MODE_VALUE = CCA_CS<<CCA_MODE0,

	/**
	 * This is the value of the CCA_THRES register that controls the
	 * energy levels used for clear channel assesment
	 */
	RFA1_CCA_THRES_VALUE = 0xC7,	//TODO to avr-libc values
	
	RFA1_PA_BUF_LT=3<<PA_BUF_LT0,
	RFA1_PA_LT=0<<PA_LT0,
};

/* This is the default value of the TX_PWR field of the PHY_TX_PWR register. */
#ifndef RFA1_DEF_RFPOWER
#define RFA1_DEF_RFPOWER	0
#endif

/* This is the default value of the CHANNEL field of the PHY_CC_CCA register. */
#ifndef RFA1_DEF_CHANNEL
#define RFA1_DEF_CHANNEL	26
#endif

/**
 * This sets the number of neighbors the radio stack stores information (like sequence number)
 */
#define RFA1_NEIGHBORHOOD_SIZE 5

//RF212 Part
#ifndef RF212_PHY_MODE
	/*
	 *  American (915Mhz) compatible data rates
	 */ 
	
// 	#define RF212_PHY_MODE RF212_DATA_MODE_BPSK_40 
// 	#define RF212_PHY_MODE RF212_DATA_MODE_OQPSK_SIN_250 
// 	#define RF212_PHY_MODE RF212_DATA_MODE_OQPSK_SIN_500 
// 	#define RF212_PHY_MODE RF212_DATA_MODE_OQPSK_SIN_1000

	/*
	 *  European (868Mhz) compatible data rates
	 */ 

// 	#define RF212_PHY_MODE RF212_DATA_MODE_BPSK_20
	#define RF212_PHY_MODE RF212_DATA_MODE_OQPSK_SIN_RC_100
//	#define RF212_PHY_MODE RF212_DATA_MODE_OQPSK_SIN_RC_200
// 	#define RF212_PHY_MODE RF212_DATA_MODE_OQPSK_SIN_RC_400
	
	/*
	 *  Chinese (780Mhz) compatible data rates
	 */ 
	
// 	#define RF212_PHY_MODE RF212_DATA_MODE_OQPSK_SIN_250 
// 	#define RF212_PHY_MODE RF212_DATA_MODE_OQPSK_SIN_500 
// 	#define RF212_PHY_MODE RF212_DATA_MODE_OQPSK_SIN_1000
#endif
enum
{
	/**
	 * This is the value of the TRX_CTRL_0 register
	 * which configures the output pin currents and the CLKM clock
	 */
	RF212_TRX_CTRL_0_VALUE = 0,
	
	/**
	 * This is the value of the TRX_CTRL_2 register which configures the 
	 * data rate and modulation type. Use the constants from RF212DriverLayer.h
	 */
	
	RF212_TRX_CTRL_2_VALUE = RF212_PHY_MODE,


	/**
	 * This is the default value of the CCA_MODE field in the PHY_CC_CCA register
	 * which is used to configure the default mode of the clear channel assesment
	 */
	RF212_CCA_MODE_VALUE = RF212_CCA_MODE_3,

	/**
	 * This is the value of the CCA_THRES register that controls the
	 * energy levels used for clear channel assesment
	 */
	RF212_CCA_THRES_VALUE = 0x77,
};

#ifndef RF212_GC_TX_OFFS
#define RF212_GC_TX_OFFS 2 //recommended modes by the datasheet Table 7-16 BPSK: 3, QPSK: 2
#endif

/* This is the default value of the TX_PWR field of the PHY_TX_PWR register. */
#ifndef RF212_DEF_RFPOWER
#define RF212_DEF_RFPOWER	0xE8
#endif

/* This is the default value of the CHANNEL field of the PHY_CC_CCA register. */
#ifndef RF212_DEF_CHANNEL
#define RF212_DEF_CHANNEL	0
#endif

/**
 * This sets the number of neighbors the radio stack stores information (like sequence number)
 */
#define RF212_NEIGHBORHOOD_SIZE 5

#endif//__RADIOCONFIG_H__
