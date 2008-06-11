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
 * @author Phil Buonadonna
 *
 */


module HplPXA27xOSTimerM {
  provides {
    interface Init;
    interface HplPXA27xOSTimer as PXA27xOST[uint8_t chnl_id];
    interface HplPXA27xOSTimerWatchdog as PXA27xWD;
  }
  uses {
    interface HplPXA27xInterrupt as OST0Irq;
    interface HplPXA27xInterrupt as OST1Irq;
    interface HplPXA27xInterrupt as OST2Irq;
    interface HplPXA27xInterrupt as OST3Irq;
    interface HplPXA27xInterrupt as OST4_11Irq;
  }
}

implementation {

  bool gfInitialized = FALSE;

  void DispatchOSTInterrupt(uint8_t id)
  {
    signal PXA27xOST.fired[id]();
    return;
  }

  command error_t Init.init()
  {
    bool initflag;
    atomic {
      initflag = gfInitialized;
      gfInitialized = TRUE;
    }
    
    if (!initflag) {
      OIER = 0x0UL;
      OSSR = 0xFFFFFFFF; // Clear all status bits.
      call OST0Irq.allocate();
      call OST1Irq.allocate();
      call OST2Irq.allocate();
      call OST3Irq.allocate();
      call OST4_11Irq.allocate();
      call OST0Irq.enable();
      call OST1Irq.enable();
      call OST2Irq.enable();
      call OST3Irq.enable();
      call OST4_11Irq.enable();
    }

    return SUCCESS;
  }
  
  async command void PXA27xOST.setOSCR[uint8_t chnl_id](uint32_t val) 
  {
    uint8_t remap_id;

    remap_id = ((chnl_id < 4) ? (0) : (chnl_id));
    OSCR(remap_id) = val;

    return;
  }
  
  async command uint32_t PXA27xOST.getOSCR[uint8_t chnl_id]()
  {
    uint8_t remap_id;
    uint32_t val;

    remap_id = ((chnl_id < 4) ? (0) : (chnl_id));
    val = OSCR(remap_id);

    return val;
  }
  
  async command void PXA27xOST.setOSMR[uint8_t chnl_id](uint32_t val)
  {
    OSMR(chnl_id) = val;
    return;
  }

  async command uint32_t PXA27xOST.getOSMR[uint8_t chnl_id]()
  {
    uint32_t val;
    val = OSMR(chnl_id);
    return val;
  }

  async command void PXA27xOST.setOMCR[uint8_t chnl_id](uint32_t val)
  {
    if (chnl_id > 3) {
      OMCR(chnl_id) = val;
    }
    return;
  }

  async command uint32_t PXA27xOST.getOMCR[uint8_t chnl_id]()
  {
    uint32_t val = 0;
    if (chnl_id > 3) {
      val = OMCR(chnl_id);
    }
    return val;
  }

  async command bool PXA27xOST.getOSSRbit[uint8_t chnl_id]() 
  {
    bool bFlag = FALSE;
    
    if (((OSSR) & (1 << chnl_id)) != 0) {
      bFlag = TRUE;
    }

    return bFlag;
  }

  async command bool PXA27xOST.clearOSSRbit[uint8_t chnl_id]()
  {
    bool bFlag = FALSE;

    if (((OSSR) & (1 << chnl_id)) != 0) {
      bFlag = TRUE;
    }

    // Clear the bit value
    OSSR = (1 << chnl_id);

    return bFlag;
  }

  async command void PXA27xOST.setOIERbit[uint8_t chnl_id](bool flag)
  {
    if (flag == TRUE) {
      OIER |= (1 << chnl_id);
    }
    else {
      OIER &= ~(1 << chnl_id);      
    }
    return;
  }
  
  async command bool PXA27xOST.getOIERbit[uint8_t chnl_id]()
  {
    return ((OIER & (1 << chnl_id)) != 0);
  }

  async command uint32_t PXA27xOST.getOSNR[uint8_t chnl_id]() 
  {
    uint32_t val;
    val = OSNR;
    return val;
  }

  async command void PXA27xWD.enableWatchdog() 
  {
    OWER = OWER_WME;
  }


  // All interrupts are funneled through DispatchOSTInterrupt.
  // This should not have any impact on performance and simplifies
  // the software implementation.

  async event void OST0Irq.fired() 
  {
    DispatchOSTInterrupt(0);
  }
  
  async event void OST1Irq.fired() 
  {
    DispatchOSTInterrupt(1);
  }
  
  async event void OST2Irq.fired() 
  {
    DispatchOSTInterrupt(2);
  }

  async event void OST3Irq.fired() 
  {
    DispatchOSTInterrupt(3);
  }

  async event void OST4_11Irq.fired() 
  {
    uint32_t statusReg;
    uint8_t chnl;

    statusReg = OSSR;
    statusReg &= ~(OSSR_M3 | OSSR_M2 | OSSR_M1 | OSSR_M0);

    while (statusReg) {
      chnl = 31 - _pxa27x_clzui(statusReg);
      DispatchOSTInterrupt(chnl); 
      statusReg &= ~(1 << chnl);
    }
      
    return;
  }

  default async event void PXA27xOST.fired[uint8_t chnl_id]() 
  {
    call PXA27xOST.setOIERbit[chnl_id](FALSE);
    call PXA27xOST.clearOSSRbit[chnl_id]();
    return;
  }

}
  
