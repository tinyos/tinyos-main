/*
* Copyright (c) 2009 Johns Hopkins University.
* All rights reserved.
*
* Permission to use, copy, modify, and distribute this software and its
* documentation for any purpose, without fee, and without written
* agreement is hereby granted, provided that the above copyright
* notice, the (updated) modification history and the author appear in
* all copies of this source code.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS  `AS IS'
* AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED  TO, THE
* IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR  PURPOSE
* ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR  CONTRIBUTORS
* BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
* CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, LOSS OF USE,  DATA,
* OR PROFITS) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
* CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR  OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
* THE POSSIBILITY OF SUCH DAMAGE.
*/

/**
 * @author JeongGil Ko
 */

#include "sam3uDmahardware.h"

module HplSam3uDmaP {

  provides interface HplSam3uDmaControl as DmaControl;
  provides interface HplSam3uDmaInterrupt as Interrupt;
  uses interface HplNVICInterruptCntl as HDMAInterrupt;
  uses interface HplSam3uPeripheralClockCntl as HDMAClockControl;
  uses interface FunctionWrapper as DmacInterruptWrapper;
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
    call DmacInterruptWrapper.preamble();
    signal Interrupt.fired();
    call DmacInterruptWrapper.postamble();
  }
}
