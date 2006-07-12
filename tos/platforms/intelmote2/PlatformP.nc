/*
 * Copyright (c) 2005 Arch Rock Corporation 
 * All rights reserved. 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *	Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 *  
 *   Neither the name of the Arch Rock Corporation nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE ARCHED
 * ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */
/**
 * @author Philip Buonadonna
 */

#include "hardware.h"

module PlatformP {
  provides interface Init;
  provides interface PlatformReset;
  uses {
    interface Init as InitL0;
    interface Init as InitL1;
    interface Init as InitL2;
    interface Init as InitL3;
    interface Init as PMICInit;
  }
  uses interface HplPXA27xOSTimer as OST0M3;
  uses interface HplPXA27xOSTimerWatchdog as PXA27xWD;
}
implementation {

  //void enableICache() @C();
  command error_t Init.init() {

    // Enable clocks to critical components 
    CKEN = (CKEN22_MEMC | CKEN20_IMEM | CKEN15_PMI2C | CKEN9_OST);
    // Set the arbiter to something meaningful for this platform
    ARB_CNTL = (ARB_CNTL_CORE_PARK | 
		ARB_CNTL_LCD_WT(0) | ARB_CNTL_DMA_WT(1) | ARB_CNTL_CORE_WT(4));


    OSCC = (OSCC_OON);
    while ((OSCC & OSCC_OOK) == 0);
    
    TOSH_SET_PIN_DIRECTIONS();

    // Enable access to CP6 (Interrupt Controller processor)
    // Enable access to Intel WMMX enhancements
    asm volatile ("mcr p15,0,%0,c15,c1,0\n\t": : "r" (0x43));

#ifdef PXA27X_13M
     // Place PXA27X into 13M w/ PPLL enabled...
    // other bits are ignored...but might be useful later
    CCCR = (CCCR_CPDIS | CCCR_L(8) | CCCR_2N(2) | CCCR_A);
    asm volatile (
		  "mcr p14,0,%0,c6,c0,0\n\t"
		  :
		  : "r" (CLKCFG_F)
		  );

#else
    // Place PXA27x into 104/104 MHz mode
    CCCR = CCCR_L(8) | CCCR_2N(2) | CCCR_A; 
    asm volatile (
		  "mcr p14,0,%0,c6,c0,0\n\t"
		  :
		  : "r" (CLKCFG_B | CLKCFG_F | CLKCFG_T)
		  );
#endif

    // Initialize Memory/Flash subsystems
    SA1110 = SA1110_SXSTACK(1);
    MSC0 = MSC0 | MSC_RBW024 | MSC_RBUFF024 | MSC_RT024(2) ;
    MSC1 = MSC1 | MSC_RBW024;
    MSC2 = MSC2 | MSC_RBW024;
    MECR = 0;
    // PXA271 Required initialization settings
    MDCNFG = (MDCNFG_SETALWAYS | MDCNFG_DTC2(0x3) | 
	      MDCNFG_STACK0 | MDCNFG_DTC0(0x3) | MDCNFG_DNB0 | 
	      MDCNFG_DRAC0(0x2) | MDCNFG_DCAC0(0x1) | MDCNFG_DWID0 /* |
								      MDCNFG_DE0 */);
    MDREFR = (MDREFR & ~(MDREFR_K0DB4 | MDREFR_K0DB2)) | MDREFR_K0DB2;

    enableICache();
    initSyncFlash();

    // Place all global platform initialization before this command.
    // return call SubInit.init();
    call InitL0.init();
    call InitL1.init();
    call InitL2.init();
    call InitL3.init();

    //call PMICInit.init();
    return SUCCESS;
  }

  async command void PlatformReset.reset() {
    call OST0M3.setOSMR(call OST0M3.getOSCR() + 1000);
    call PXA27xWD.enableWatchdog();
    while (1);
    return; // Should never get here.
  }

  async event void OST0M3.fired() 
  {
    call OST0M3.setOIERbit(FALSE);
    call OST0M3.clearOSSRbit();
    return;
  }

  default command error_t InitL0.init() { return SUCCESS; }
  default command error_t InitL1.init() { return SUCCESS; }
  default command error_t InitL2.init() { return SUCCESS; }
  default command error_t InitL3.init() { return SUCCESS; }

}

