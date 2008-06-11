/*
 * Copyright (c) 2005 Arched Rock Corporation 
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
 *   Neither the name of the Arched Rock Corporation nor the names of its
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
 * Implements a TOS 2.0 Counter on the PXA27x HPL. The PXA27x does not 
 * have an explicit overflow notification. We emulate one by using 
 * the associated match register set to 0. This requires we initialize
 * the counter to 1 to avoid a false notification at startup.
 * 
 *  @author Phil Buonadonna
 */
#include "Timer.h"

generic module HalPXA27xCounterM(typedef frequency_tag, uint8_t resolution) 
{
  provides {
    interface Init;
    interface Counter<frequency_tag,uint32_t> as Counter;
    interface LocalTime<frequency_tag> as LocalTime;
  }
  uses {
    interface Init as OSTInit;
    interface HplPXA27xOSTimer as OSTChnl;
  }
}

implementation
{
  command error_t Init.init() {

    call OSTInit.init(); 

    // Continue on match, Non-periodic, w/ given resolution
    atomic {
      call OSTChnl.setOMCR(OMCR_C | OMCR_P | OMCR_CRES(resolution));
      call OSTChnl.setOSMR(0);
      call OSTChnl.setOSCR(1);
      call OSTChnl.clearOSSRbit();
      call OSTChnl.setOIERbit(TRUE);
    }
    return SUCCESS;

  }
  
  async command uint32_t Counter.get() {
    uint32_t cntr;

    cntr = call OSTChnl.getOSCR();
    return cntr;
  }

  async command bool Counter.isOverflowPending() {
    bool flag;

    atomic flag = call OSTChnl.getOSSRbit();
    return flag;
  }

  async command void Counter.clearOverflow() {

    atomic call OSTChnl.clearOSSRbit();
  }

  async event void OSTChnl.fired() {
    call OSTChnl.clearOSSRbit();
    signal Counter.overflow();
    return;
  }

  async command uint32_t LocalTime.get() {
    uint32_t cntr;

    cntr = call OSTChnl.getOSCR();
    return cntr;
  }

  default async event void Counter.overflow() {
    return;
  }

}

