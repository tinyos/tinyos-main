// $Id: hardware.h,v 1.2 2010-06-29 22:07:51 scipio Exp $

/*
 *
 *
 * Copyright (c) 2000-2005 The Regents of the University  of California.  
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
