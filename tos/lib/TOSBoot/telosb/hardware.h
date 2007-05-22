// $Id: hardware.h,v 1.1 2007-05-22 20:34:22 razvanm Exp $

/*									tab:2
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
 */

#ifndef __HARDWARE_H__
#define __HARDWARE_H__

#include "msp430hardware.h"

// internal flash is 16 bits in width
typedef uint16_t in_flash_addr_t;
// external flash is 32 bits in width
typedef uint32_t ex_flash_addr_t;

void wait(uint16_t t) {
  for ( ; t > 0; t-- );
}

// LEDs
TOSH_ASSIGN_PIN(RED_LED, 5, 4);
TOSH_ASSIGN_PIN(GREEN_LED, 5, 5);
TOSH_ASSIGN_PIN(YELLOW_LED, 5, 6);

// UART pins
TOSH_ASSIGN_PIN(SOMI0, 3, 2);
TOSH_ASSIGN_PIN(SIMO0, 3, 1);
TOSH_ASSIGN_PIN(UCLK0, 3, 3);
TOSH_ASSIGN_PIN(UTXD0, 3, 4);
TOSH_ASSIGN_PIN(URXD0, 3, 5);

// User Interupt Pin
TOSH_ASSIGN_PIN(USERINT, 2, 7);

// FLASH
TOSH_ASSIGN_PIN(FLASH_PWR, 4, 3);
TOSH_ASSIGN_PIN(FLASH_CS, 4, 4);
TOSH_ASSIGN_PIN(FLASH_HOLD, 4, 7);

void TOSH_SET_PIN_DIRECTIONS(void)
{
  P3SEL = 0x0E; // set SPI and I2C to mod func
  
  P1DIR = 0xe0;
  P1OUT = 0x00;
  
  P2DIR = 0x7b;
  P2OUT = 0x10;
  
  P3DIR = 0xf1;
  P3OUT = 0x00;
  
  P4DIR = 0xfd;
  P4OUT = 0xdd;
  
  P5DIR = 0xff;
  P5OUT = 0xff;
  
  P6DIR = 0xff;
  P6OUT = 0x00;
}

#endif
