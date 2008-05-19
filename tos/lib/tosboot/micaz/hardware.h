// $Id: hardware.h,v 1.2 2008-05-19 21:25:09 razvanm Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */
/*
 *
 * $Id: hardware.h,v 1.2 2008-05-19 21:25:09 razvanm Exp $
 *
 */

#ifndef __HARDWARE_H__
#define __HARDWARE_H__

#include <atm128hardware.h>
#include <avrhardware.h>

typedef uint32_t in_flash_addr_t;
typedef uint32_t ex_flash_addr_t;

static inline void wait( uint16_t dt ) {
  /* In most cases (constant arg), the test is elided at compile-time */
  if (dt)
    /* loop takes 8 cycles. this is 1uS if running on an internal 8MHz
       clock, and 1.09uS if running on the external crystal. */
    asm volatile (
      "1:       sbiw    %0,1\n"
      " adiw    %0,1\n"
      " sbiw    %0,1\n"
      " brne    1b" : "+w" (dt));
}

// LED assignments
TOSH_ASSIGN_PIN(RED_LED, A, 2);
TOSH_ASSIGN_PIN(GREEN_LED, A, 1);
TOSH_ASSIGN_PIN(YELLOW_LED, A, 0);

TOSH_ASSIGN_PIN(SERIAL_ID, A, 4);

// Flash assignments
TOSH_ASSIGN_PIN(FLASH_CS, A, 3);
TOSH_ASSIGN_PIN(FLASH_CLK,  D, 5);
TOSH_ASSIGN_PIN(FLASH_OUT,  D, 3);
TOSH_ASSIGN_PIN(FLASH_IN,  D, 2);

// power control assignments
TOSH_ASSIGN_PIN(PW0, C, 0);
TOSH_ASSIGN_PIN(PW1, C, 1);
TOSH_ASSIGN_PIN(PW2, C, 2);
TOSH_ASSIGN_PIN(PW3, C, 3);
TOSH_ASSIGN_PIN(PW4, C, 4);
TOSH_ASSIGN_PIN(PW5, C, 5);
TOSH_ASSIGN_PIN(PW6, C, 6);
TOSH_ASSIGN_PIN(PW7, C, 7);

void TOSH_SET_PIN_DIRECTIONS(void)
{
  TOSH_MAKE_RED_LED_OUTPUT();
  TOSH_MAKE_YELLOW_LED_OUTPUT();
  TOSH_MAKE_GREEN_LED_OUTPUT();
      
  TOSH_MAKE_PW7_OUTPUT();
  TOSH_MAKE_PW6_OUTPUT();
  TOSH_MAKE_PW5_OUTPUT();
  TOSH_MAKE_PW4_OUTPUT();
  TOSH_MAKE_PW3_OUTPUT(); 
  TOSH_MAKE_PW2_OUTPUT();
  TOSH_MAKE_PW1_OUTPUT();
  TOSH_MAKE_PW0_OUTPUT();

  TOSH_MAKE_SERIAL_ID_INPUT();
  TOSH_CLR_SERIAL_ID_PIN();  // Prevent sourcing current

  TOSH_MAKE_FLASH_CS_OUTPUT();
  TOSH_MAKE_FLASH_OUT_OUTPUT();
  TOSH_MAKE_FLASH_CLK_OUTPUT();
  TOSH_SET_FLASH_CS_PIN();
}

enum {
  VOLTAGE_PORT = 30,
  VTHRESH = 0x1cf, // 2.7V
};

#endif




