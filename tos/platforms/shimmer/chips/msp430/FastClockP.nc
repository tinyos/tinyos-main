/*
 * Copyright (c) 2010, Shimmer Research, Ltd.
 * All rights reserved
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:

 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer in the documentation and/or other materials provided
 *       with the distribution.
 *     * Neither the name of Shimmer Research, Ltd. nor the names of its
 *       contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.

 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * @author Steve Ayer
 * @date   August, 2010
 *
 * finally sick of duplicating the same ti msp430 routine to initialize the
 * xt2 crystal on this family of platforms, a module to do it for us.
 *
 * **********************  APP WARNING NOTE: **************************************
 *
 * by default this uses an smclk divisor of 2, so the smclk will 
 * run at 4mhz, breaking some bus timings.  to fix this, simply add the line
 * PFLAGS += -DSMCLK_4MHZ
 * to your app's Makefile and see SDP.nc for how this is handled in a driver.  
 * Alternatively, you can set the smclk back to 1mhz by changing DIVS_1 to DIVS_7
 *
 * ********************************************************************************                   
 */

#include "msp430hardware.h"

module FastClockP{
  provides{
    interface Init;
    interface FastClock;
  }
  uses interface Leds;
}

implementation {
  command error_t Init.init() {
    register uint8_t i;
    /* 
     * set up 8mhz clock to max out 
     * msp430 throughput 
     */

    atomic{

      CLR_FLAG(BCSCTL1, XT2OFF); // basic clock system control reg, turn off XT2 osc

      call Leds.led0On();
      do{
	CLR_FLAG(IFG1, OFIFG);

	__delay_cycles(50);  

      }
      while(READ_FLAG(IFG1, OFIFG));
      call Leds.led0Off();

      for(i = 0; i < 100; i++)
	TOSH_uwait(500);

      /* 
       * select master clock source, XT2CLK when XT2 oscillator present
       * on-chip. LFXT1CLK when XT2 oscillator not present on-chip. 
       */
      BCSCTL2 = 0; 
      SET_FLAG(BCSCTL2, SELM_2); 

      SET_FLAG(BCSCTL2, SELS);  // smclk from xt2
      SET_FLAG(BCSCTL2, DIVS_1);  // divide it by 2
 
    }

    return SUCCESS;
  }
  
  command void FastClock.disable() {
    atomic {
      SET_FLAG(BCSCTL2, SELM_0);
      SET_FLAG(BCSCTL1, XT2OFF);
    }
  }
  
  command void FastClock.setSMCLK(uint8_t mhz){
    switch(mhz) {
    case 1:
      SET_FLAG(BCSCTL2, DIVS_3);  // divide 8mhz xt2 by 8
      break;
    case 2:
      SET_FLAG(BCSCTL2, DIVS_2);  // divide by 4
      CLR_FLAG(BCSCTL2, DIVS_1);
      break;
    case 4:
      SET_FLAG(BCSCTL2, DIVS_1);  // divide by 2
      CLR_FLAG(BCSCTL2, DIVS_2);
      break;
    default:
      SET_FLAG(BCSCTL2, DIVS_3);  // divide by 8
      break;
    }
  }
}

