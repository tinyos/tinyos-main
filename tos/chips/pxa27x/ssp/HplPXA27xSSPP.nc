/* $Id: HplPXA27xSSPP.nc,v 1.5 2008-06-11 00:42:13 razvanm Exp $ */
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
 *
 * @author Phil Buonadonna
 */

module HplPXA27xSSPP 
{
  provides {
    interface Init[uint8_t chnl];
    interface HplPXA27xSSP[uint8_t chnl];
  }
  uses {
    interface HplPXA27xInterrupt as SSP1Irq;
    interface HplPXA27xInterrupt as SSP2Irq;
    interface HplPXA27xInterrupt as SSP3Irq;
  }
}

implementation 
{

  command error_t Init.init[uint8_t chnl]() {
    error_t error = SUCCESS;
    
    switch (chnl) {
    case 1:
      CKEN |= CKEN23_SSP1;
      call SSP1Irq.enable(); 
      break;
    case 2: 
      CKEN |= CKEN3_SSP2;
      call SSP2Irq.enable(); 
      break;
    case 3: 
      CKEN |= CKEN4_SSP3;
      //call SSP3Irq.allocate();
      call SSP3Irq.enable(); 
      break;
    default: 
      error = FAIL;
      break;
    }

    return error;
  }

  async command void HplPXA27xSSP.setSSCR0[uint8_t chnl](uint32_t val) {
    switch (chnl) {
    case 1: SSCR0_1 = val; break;
    case 2: SSCR0_2 = val; break;
    case 3: SSCR0_3 = val; break;
    default: break;
    }
    return;
  }

  async command uint32_t HplPXA27xSSP.getSSCR0[uint8_t chnl]() {
    switch (chnl) {
    case 1: return SSCR0_1; break;
    case 2: return SSCR0_2; break;
    case 3: return SSCR0_3; break;
    default: return 0;
    }
   }

  async command void HplPXA27xSSP.setSSCR1[uint8_t chnl](uint32_t val) {
    switch (chnl) {
    case 1: SSCR1_1 = val; break;
    case 2: SSCR1_2 = val; break;
    case 3: SSCR1_3 = val; break;
    default: break;
    }
    return;
  }
  async command uint32_t HplPXA27xSSP.getSSCR1[uint8_t chnl]() {
    switch (chnl) {
    case 1: return SSCR1_1; break;
    case 2: return SSCR1_2; break;
    case 3: return SSCR1_3; break;
    default: return 0;
    }
  }
  
  async command void HplPXA27xSSP.setSSSR[uint8_t chnl](uint32_t val) {
    switch (chnl) {
    case 1: SSSR_1 = val; break;
    case 2: SSSR_2 = val; break;
    case 3: SSSR_3 = val; break;
    default: break;
    }
    return;
  }
  async command uint32_t HplPXA27xSSP.getSSSR[uint8_t chnl]() {
    switch (chnl) {
    case 1: return SSSR_1; break;
    case 2: return SSSR_2; break;
    case 3: return SSSR_3; break;
    default: return 0;
    }
  }

  async command void HplPXA27xSSP.setSSITR[uint8_t chnl](uint32_t val) {
    switch (chnl) {
    case 1: SSITR_1 = val; break;
    case 2: SSITR_2 = val; break;
    case 3: SSITR_3 = val; break;
    default: break;
    }
    return;
  }
  async command uint32_t HplPXA27xSSP.getSSITR[uint8_t chnl]() {
    switch (chnl) {
    case 1: return SSITR_1; break;
    case 2: return SSITR_2; break;
    case 3: return SSITR_3; break;
    default: return 0;
    }
  }

  async command void HplPXA27xSSP.setSSDR[uint8_t chnl](uint32_t val) {
    switch (chnl) {
    case 1: SSDR_1 = val; break;
    case 2: SSDR_2 = val; break;
    case 3: SSDR_3 = val; break;
    default: break;
    }
    return;
  }
  async command uint32_t HplPXA27xSSP.getSSDR[uint8_t chnl]() {
    switch (chnl) {
    case 1: return SSDR_1; break;
    case 2: return SSDR_2; break;
    case 3: return SSDR_3; break;
    default: return 0;
    }
  }

  async command void HplPXA27xSSP.setSSTO[uint8_t chnl](uint32_t val) {
    switch (chnl) {
    case 1: SSTO_1 = val; break;
    case 2: SSTO_2 = val; break;
    case 3: SSTO_3 = val; break;
    default: break;
    }
    return;
  }
  async command uint32_t HplPXA27xSSP.getSSTO[uint8_t chnl]() {
    switch (chnl) {
    case 1: return SSTO_1; break;
    case 2: return SSTO_2; break;
    case 3: return SSTO_3; break;
    default: return 0;
    }
  }

  async command void HplPXA27xSSP.setSSPSP[uint8_t chnl](uint32_t val) {
    switch (chnl) {
    case 1: SSPSP_1 = val; break;
    case 2: SSPSP_2 = val; break;
    case 3: SSPSP_3 = val; break;
    default: break;
    }
    return;
  }
  async command uint32_t HplPXA27xSSP.getSSPSP[uint8_t chnl]() {
    switch (chnl) {
    case 1: return SSPSP_1; break;
    case 2: return SSPSP_2; break;
    case 3: return SSPSP_3; break;
    default: return 0;
    }
  }

  async command void HplPXA27xSSP.setSSTSA[uint8_t chnl](uint32_t val) {
    switch (chnl) {
    case 1: SSTSA_1 = val; break;
    case 2: SSTSA_2 = val; break;
    case 3: SSTSA_3 = val; break;
    default: break;
    }
    return;
  }
  async command uint32_t HplPXA27xSSP.getSSTSA[uint8_t chnl]() {
    switch (chnl) {
    case 1: return SSTSA_1; break;
    case 2: return SSTSA_2; break;
    case 3: return SSTSA_3; break;
    default: return 0;
    }
  }

  async command void HplPXA27xSSP.setSSRSA[uint8_t chnl](uint32_t val) {
    switch (chnl) {
    case 1: SSRSA_1 = val; break;
    case 2: SSRSA_2 = val; break;
    case 3: SSRSA_3 = val; break;
    default: break;
    }
    return;
  }
  async command uint32_t HplPXA27xSSP.getSSRSA[uint8_t chnl]() {
    switch (chnl) {
    case 1: return SSRSA_1; break;
    case 2: return SSRSA_2; break;
    case 3: return SSRSA_3; break;
    default: return 0;
    }
  }

  async command void HplPXA27xSSP.setSSTSS[uint8_t chnl](uint32_t val) {
    switch (chnl) {
    case 1: SSTSS_1 = val; break;
    case 2: SSTSS_2 = val; break;
    case 3: SSTSS_3 = val; break;
    default: break;
    }
    return;
  }
  async command uint32_t HplPXA27xSSP.getSSTSS[uint8_t chnl]() {
    switch (chnl) {
    case 1: return SSTSS_1; break;
    case 2: return SSTSS_2; break;
    case 3: return SSTSS_3; break;
    default: return 0;
    }
  }

  async command void HplPXA27xSSP.setSSACD[uint8_t chnl](uint32_t val) {
    switch (chnl) {
    case 1: SSACD_1 = val; break;
    case 2: SSACD_2 = val; break;
    case 3: SSACD_3 = val; break;
    default: break;
    }
    return;  
  }
  async command uint32_t HplPXA27xSSP.getSSACD[uint8_t chnl]() {
    switch (chnl) {
    case 1: return SSACD_1; break;
    case 2: return SSACD_2; break;
    case 3: return SSACD_3; break;
    default: return 0;
    }
  }

  default async event void HplPXA27xSSP.interruptSSP[uint8_t chnl]() {
    call HplPXA27xSSP.setSSSR[chnl](SSSR_BCE | SSSR_TUR | SSSR_EOC | SSSR_TINT | 
		     SSSR_PINT | SSSR_ROR );
    return;
  }

  async event void SSP1Irq.fired() {
    signal HplPXA27xSSP.interruptSSP[1]();
  }
  async event void SSP2Irq.fired() {
    signal HplPXA27xSSP.interruptSSP[2]();
  }
  async event void SSP3Irq.fired() {
    signal HplPXA27xSSP.interruptSSP[3]();
  }

  default async command void SSP1Irq.enable() {return;}
  default async command void SSP2Irq.enable() {return;}
  default async command void SSP3Irq.enable() {return;}

}

