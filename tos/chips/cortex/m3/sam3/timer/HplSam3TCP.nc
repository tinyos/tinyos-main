/**
 * Copyright (c) 2009 The Regents of the University of California.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holders nor the names of its
 *   contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
 * AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 * WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * Provides the functionality of the SAM3U TC. It enables and disables the
 * whole unit and initializes the default configuration.
 *
 * @author Thomas Schmid
 */

#include "sam3tchardware.h"

generic module HplSam3TCP(uint32_t tc_base) @safe()
{
    provides {
        interface Init;
        interface HplSam3TC as TC;
    }
    uses {
        interface HplSam3TCChannel as TC0;
        interface HplSam3TCChannel as TC1;
        interface HplSam3TCChannel as TC2;

        interface HplSam3Clock as ClockConfig;
    }
}
implementation
{
  volatile tc_t *TC_P = (volatile tc_t*)tc_base;

    command error_t Init.init()
    {
        uint32_t mck;
        uint8_t clockSource;

        call TC0.setMode(TC_CMR_CAPTURE);
        call TC1.setMode(TC_CMR_CAPTURE);
        call TC2.setMode(TC_CMR_CAPTURE);

        // check the speed of the master clock
        mck = call ClockConfig.getMainClockSpeed(); // in kHz
        // convert to MHz to find the right divider
        mck = mck / 1000;

        if(mck >= 128)
          clockSource = TC_CMR_CLK_TC4;
        else if (mck >= 32)
          clockSource = TC_CMR_CLK_TC3;
        else if (mck >= 8)
          clockSource = TC_CMR_CLK_TC2;
        else if (mck >= 2)
          clockSource = TC_CMR_CLK_TC1;
        else
          clockSource = TC_CMR_CLK_SLOW;

        call TC0.setClockSource(clockSource);
        call TC1.setClockSource(clockSource);
        call TC2.setClockSource(clockSource);

        call TC2.enableEvents();

        return SUCCESS;
    }

  command void TC.enableTC0(){
    call TC0.setMode(TC_CMR_CAPTURE);
    call TC0.setClockSource(TC_CMR_CLK_SLOW);
    call TC0.enableEvents();
  }

  command void TC.enableTC1(){
    call TC1.setMode(TC_CMR_CAPTURE);
    call TC1.setClockSource(TC_CMR_CLK_SLOW);
    call TC1.enableEvents();
  }

  command void TC.enableTC2(){
    uint32_t mck;
    call TC2.setMode(TC_CMR_CAPTURE);

    // check the speed of the master clock
    mck = call ClockConfig.getMainClockSpeed(); // in kHz
    // convert to MHz to find the right divider
    mck = mck / 1000;

    if(mck >= 128)
      call TC2.setClockSource(TC_CMR_CLK_TC4);
    else if (mck >= 32)
      call TC2.setClockSource(TC_CMR_CLK_TC3);
    else if (mck >= 8)
      call TC2.setClockSource(TC_CMR_CLK_TC2);
    else if (mck >= 2)
      call TC2.setClockSource(TC_CMR_CLK_TC1);
    else
      call TC2.setClockSource(TC_CMR_CLK_SLOW);

    call TC2.enableEvents();
  }

  command void TC.disableTC0(){
    call TC0.disableEvents();
  }

  command void TC.disableTC1(){
    call TC1.disableEvents();
  }

  command void TC.disableTC2(){
     call TC2.disableEvents();
  }

  command void TC.sync(){
    tc_bcr_t bcr = TC_P->bcr;
    bcr.bits.sync = 1;
    TC_P->bcr = bcr;
  }

  async event void ClockConfig.mainClockChanged() {};
  async event void TC0.overflow() {};
  async event void TC1.overflow() {};
  async event void TC2.overflow() {};
}


