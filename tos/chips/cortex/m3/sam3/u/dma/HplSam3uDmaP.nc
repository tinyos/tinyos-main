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

#include "sam3uDmahardware.h"

module HplSam3uDmaP {

  provides interface HplSam3uDmaControl as DmaControl;
  provides interface HplSam3uDmaInterrupt as Interrupt;
  uses interface HplNVICInterruptCntl as HDMAInterrupt;
  uses interface HplSam3PeripheralClockCntl as HDMAClockControl;
  uses interface McuSleep;
  uses interface Leds;
}

implementation {

  async command error_t DmaControl.init(){
    call HDMAInterrupt.disable();
    call HDMAInterrupt.configure(IRQ_PRIO_DMAC);
    call HDMAInterrupt.enable();
    call HDMAClockControl.enable();
    return SUCCESS;
  }

  async command error_t DmaControl.setRoundRobin(){
    volatile dmac_gcfg_t *GCFG = (volatile dmac_gcfg_t *) 0x400B0000;
    dmac_gcfg_t gcfg = *GCFG;
    gcfg.bits.arb_cfg = 1;
    *GCFG = gcfg;
    return SUCCESS;
  }

  async command error_t DmaControl.setFixedPriority(){
    volatile dmac_gcfg_t *GCFG = (volatile dmac_gcfg_t *) 0x400B0000;
    dmac_gcfg_t gcfg = *GCFG;
    gcfg.bits.arb_cfg = 0;
    *GCFG = gcfg;
    return SUCCESS;
  }

  async command void DmaControl.reset(){
    
  }

  void DmacIrqHandler() @C() @spontaneous() {
    call McuSleep.irq_preamble();
    signal Interrupt.fired();
    call McuSleep.irq_postamble();
  }
}
