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
 * This components maps requested timer resources connected using the
 * 'PXA27xOSTimer.Resource' flag to physical timer resource of the PXA27x.
 * 
 * @author Phil Buonadonna
 *
 */

configuration HalPXA27xOSTimerMapC {

  provides {
    interface Init;
    interface HplPXA27xOSTimer as OSTChnl[uint8_t id];
  }
}

implementation {
  components HplPXA27xOSTimerC;

  Init = HplPXA27xOSTimerC;

  OSTChnl[0] = HplPXA27xOSTimerC.OST4;
  OSTChnl[1] = HplPXA27xOSTimerC.OST5;
  OSTChnl[2] = HplPXA27xOSTimerC.OST6;
  OSTChnl[3] = HplPXA27xOSTimerC.OST7;
  OSTChnl[4] = HplPXA27xOSTimerC.OST8;
  OSTChnl[5] = HplPXA27xOSTimerC.OST9;
  OSTChnl[6] = HplPXA27xOSTimerC.OST10;
  OSTChnl[7] = HplPXA27xOSTimerC.OST11;

}
