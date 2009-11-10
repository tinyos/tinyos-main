// $Id: hardware.h,v 1.1 2009-11-10 07:03:34 rflury Exp $

/*
 *
 *
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */

/**
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 * @author Roland Flury <roland.flury@shockfish.com>
 */

#ifndef __HARDWARE_H__
#define __HARDWARE_H__

#include "msp430hardware.h"

// internal flash is 16 bits in width
typedef uint16_t in_flash_addr_t;
// external flash is 32 bits in width
typedef uint32_t ex_flash_addr_t;

void wait(uint16_t t) {
  for(; t > 0; t--);
}
enum {
  VTHRESH = 0xE66, // 2.7V - threshold for reprogramming the node, if voltage is below, don't reprogram
};

// LEDs
TOSH_ASSIGN_PIN(RED_LED2, 1, 5);		// on tinynode
TOSH_ASSIGN_PIN(RED_LED, 1, 6);	// external
TOSH_ASSIGN_PIN(GREEN_LED, 2, 3);
TOSH_ASSIGN_PIN(YELLOW_LED, 2, 4);

// FLASH at45db041
TOSH_ASSIGN_PIN(FLASH_CS, 4, 7); // inverted
TOSH_ASSIGN_PIN(FLASH_RESET, 4, 6); // inverted
TOSH_ASSIGN_PIN(FLASH_CLK, 3, 3);
TOSH_ASSIGN_PIN(FLASH_OUT, 3, 1); // MOSI - master OUT slave IN
TOSH_ASSIGN_PIN(FLASH_IN, 3, 2); // MISO - master IN slave OUT

void TOSH_SET_PIN_DIRECTIONS(void) {
	
	// FLASH at45db041
  TOSH_SET_FLASH_CS_PIN(); // inverted 
  TOSH_MAKE_FLASH_CS_OUTPUT();
  TOSH_MAKE_FLASH_OUT_OUTPUT();
  TOSH_MAKE_FLASH_CLK_OUTPUT();
	TOSH_MAKE_FLASH_IN_INPUT();
	TOSH_SET_FLASH_RESET_PIN(); // inverted
	TOSH_MAKE_FLASH_RESET_OUTPUT();

	// LEDs
	TOSH_CLR_RED_LED2_PIN();
	TOSH_CLR_RED_LED_PIN();
	TOSH_CLR_YELLOW_LED_PIN();
	TOSH_CLR_GREEN_LED_PIN();
	TOSH_MAKE_RED_LED2_OUTPUT();		
	TOSH_MAKE_RED_LED_OUTPUT();		
	TOSH_MAKE_YELLOW_LED_OUTPUT();		
	TOSH_MAKE_GREEN_LED_OUTPUT();		
}

#endif
