/*
 * Copyright (c) 2009 Johns Hopkins University.
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
 * @author JeongGil Ko
 */

#include "pdchardware.h"

generic module HplSam3PdcP(uint32_t BASE_ADDR){
  provides interface HplSam3Pdc as Pdc;
}
implementation{

  uint32_t PDC_BASE_ADDR = (BASE_ADDR + 0x100);

  async command void Pdc.setRxPtr(void* addr){
    volatile periph_rpr_t* RPR = (volatile periph_rpr_t*) (PDC_BASE_ADDR + 0x0);
    periph_rpr_t rpr;
    rpr.bits.rxptr = (uint32_t)addr;
    *RPR = rpr;
  }

  async command void Pdc.setTxPtr(void* addr){
    volatile periph_tpr_t* TPR = (volatile periph_tpr_t*) (PDC_BASE_ADDR + 0x8);
    periph_tpr_t tpr;
    tpr.bits.txptr = (uint32_t)addr;
    *TPR = tpr;
  }

  async command void Pdc.setNextRxPtr(void* addr){
    volatile periph_rnpr_t* RNPR = (volatile periph_rnpr_t*) (PDC_BASE_ADDR + 0x10);
    periph_rnpr_t rnpr;
    rnpr.bits.rxnptr = (uint32_t)addr;
    *RNPR = rnpr;
  }

  async command void Pdc.setNextTxPtr(void* addr){
    volatile periph_tnpr_t* TNPR = (volatile periph_tnpr_t*) (PDC_BASE_ADDR + 0x18);
    periph_tnpr_t tnpr;
    tnpr.bits.txnptr = (uint32_t)addr;
    *TNPR = tnpr;
  }

  async command uint32_t Pdc.getRxPtr(){
    volatile periph_rpr_t* RPR = (volatile periph_rpr_t*) (PDC_BASE_ADDR + 0x0);
    return RPR->bits.rxptr;
  }

  async command uint32_t Pdc.getTxPtr(){
    volatile periph_tpr_t* TPR = (volatile periph_tpr_t*) (PDC_BASE_ADDR + 0x8);
    return TPR->bits.txptr;
  }

  async command uint32_t Pdc.getNextRxPtr(){
    volatile periph_rnpr_t* RNPR = (volatile periph_rnpr_t*) (PDC_BASE_ADDR + 0x10);
    return RNPR->bits.rxnptr;
  }

  async command uint32_t Pdc.getNextTxPtr(){
    volatile periph_tnpr_t* TNPR = (volatile periph_tnpr_t*) (PDC_BASE_ADDR + 0x18);
    return TNPR->bits.txnptr;
  }

  async command uint16_t Pdc.getRxCounter(){
    volatile periph_rcr_t* RCR = (volatile periph_rcr_t*) (PDC_BASE_ADDR + 0x4);
    return RCR->bits.rxctr;
  }

  async command uint16_t Pdc.getTxCounter(){
    volatile periph_tcr_t* TCR = (volatile periph_tcr_t*) (PDC_BASE_ADDR + 0xC);
    return TCR->bits.txctr;
  }

  async command uint16_t Pdc.getNextRxCounter(){
    volatile periph_rncr_t* RNCR = (volatile periph_rncr_t*) (PDC_BASE_ADDR + 0x14);
    return RNCR->bits.rxnctr;
  }

  async command uint16_t Pdc.getNextTxCounter(){
    volatile periph_tncr_t* TNCR = (volatile periph_tncr_t*) (PDC_BASE_ADDR + 0x1C);
    return TNCR->bits.txnctr;
  }

  async command void Pdc.setRxCounter(uint16_t counter){
    volatile periph_rcr_t* RCR = (volatile periph_rcr_t*) (PDC_BASE_ADDR + 0x4);
    periph_rcr_t rcr;
    rcr.bits.rxctr = counter;
    *RCR = rcr;
  }

  async command void Pdc.setTxCounter(uint16_t counter){
    volatile periph_tcr_t* TCR = (volatile periph_tcr_t*) (PDC_BASE_ADDR + 0xC);
    periph_tcr_t tcr;
    tcr.bits.txctr = counter;
    *TCR = tcr;
  }

  async command void Pdc.setNextRxCounter(uint16_t counter){
    volatile periph_rncr_t* RNCR = (volatile periph_rncr_t*) (PDC_BASE_ADDR + 0x14);
    periph_rncr_t rncr;
    rncr.bits.rxnctr = counter;
    *RNCR = rncr;
  }

  async command void Pdc.setNextTxCounter(uint16_t counter){
    volatile periph_tncr_t* TNCR = (volatile periph_tncr_t*) (PDC_BASE_ADDR + 0x1C);
    periph_tncr_t tncr;
    tncr.bits.txnctr = counter;
    *TNCR = tncr;
  }

  async command void Pdc.enablePdcRx(){
    volatile periph_ptcr_t* PTCR = (volatile periph_ptcr_t*) (PDC_BASE_ADDR + 0x20);
    periph_ptcr_t ptcr;
    ptcr.bits.rxten = 1;
    *PTCR = ptcr;
  }

  async command void Pdc.enablePdcTx(){
    volatile periph_ptcr_t* PTCR = (volatile periph_ptcr_t*) (PDC_BASE_ADDR + 0x20);
    periph_ptcr_t ptcr;
    ptcr.bits.txten = 1;
    *PTCR = ptcr;
  }

  async command void Pdc.disablePdcRx(){
    volatile periph_ptcr_t* PTCR = (volatile periph_ptcr_t*) (PDC_BASE_ADDR + 0x20);
    periph_ptcr_t ptcr;
    ptcr.bits.rxtdis = 1;
    *PTCR = ptcr;
  }

  async command void Pdc.disablePdcTx(){
    volatile periph_ptcr_t* PTCR = (volatile periph_ptcr_t*) (PDC_BASE_ADDR + 0x20);
    periph_ptcr_t ptcr;
    ptcr.bits.txtdis = 1;
    *PTCR = ptcr;
  }

  async command bool Pdc.rxEnabled(){
    volatile periph_ptsr_t* PTSR = (volatile periph_ptsr_t*) (PDC_BASE_ADDR + 0x24);
    periph_ptsr_t ptsr = *PTSR;
    if(ptsr.bits.rxten){
      return TRUE;
    }else{
      return FALSE;
    }
  }

  async command bool Pdc.txEnabled(){
    volatile periph_ptsr_t* PTSR = (volatile periph_ptsr_t*) (PDC_BASE_ADDR + 0x24);
    periph_ptsr_t ptsr = *PTSR;
    if(ptsr.bits.txten){
      return TRUE;
    }else{
      return FALSE;
    }
  }

}
