/* 
 * Copyright (c) 2006, Ecole Polytechnique Federale de Lausanne (EPFL),
 * Switzerland.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Ecole Polytechnique Federale de Lausanne (EPFL) 
 *   nor the names of its contributors may be used to 
 *   endorse or promote products derived from this software without 
 *   specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * ========================================================================
 */

/*
 * Implementation of XE1205IrqConf interface.
 *
 * @author Henri Dubois-Ferriere
 */



module XE1205IrqConfP {

  provides interface XE1205IrqConf;
  provides interface Init @atleastonce();

  uses interface XE1205Register as IrqParam5;
  uses interface XE1205Register as IrqParam6;
  uses interface Resource as SpiResource;
}
implementation {

#include "xe1205debug.h"


  // norace is ok because protected by the isOwner() calls
  norace uint8_t irqparam5; 
  norace uint8_t irqparam6;

  task void initTask() 
  {
    atomic {

      xe1205check(1, call SpiResource.immediateRequest()); // should always succeed: task happens after softwareInit, before interrupts are enabled

      call IrqParam5.write(0x59); // IRQ0: Write_byte, IRQ1: fifofull, Tx_IRQ: TX_stopped.
      call IrqParam6.write(0x54); // fill fifo on pattern, clear pattern detect bit, start transmission when fifo not empty
      // no irq interrupt
      irqparam5=0x59;
      irqparam6=0x54;
      
      call SpiResource.release();
    }
  }

  command error_t Init.init() 
  {
    post initTask();
    return SUCCESS;
  }
  
  event void SpiResource.granted() {  }


  /* 
   * Set IRQ0 sources in Rx mode. 
   * @param src may be one of: irq_write_byte, irq_nFifoEmpty, or irq_Pattern.
   */
  async command error_t XE1205IrqConf.setRxIrq0Source(xe1205_rx_irq0_src_t src) 
  {
    error_t status;

    if (src > 3)  return EINVAL;

    if (call SpiResource.isOwner()) return EBUSY;

    status = call SpiResource.immediateRequest();
    xe1205check(2, status);
    if (status != SUCCESS) return status;

    irqparam5 &= ~(3 << 6);
    irqparam5 |= (src << 6);
    call IrqParam5.write(irqparam5);

    call SpiResource.release();
    return SUCCESS;
  }


  /* 
   * Set IRQ1 sources in Rx mode. 
   * @param src may be one of: irq_Rssi or irq_FifoFull.
   */
  async command error_t XE1205IrqConf.setRxIrq1Source(xe1205_rx_irq1_src_t src) 
  {
    error_t status;

    if (src > 2) return EINVAL;

    if (call SpiResource.isOwner()) return EBUSY;

    status = call SpiResource.immediateRequest();
    xe1205check(3, status);
    if (status != SUCCESS) return status;

    irqparam5 &= ~(3 << 4);
    irqparam5 |= (src << 4);
    call IrqParam5.write(irqparam5);
    call SpiResource.release();
    return SUCCESS;
  }

  /* 
   * Set IRQ1 sources in Tx mode. 
   * @param src my be one of: irq_FifoFull or irq_TxStopped.
   */
  async command error_t XE1205IrqConf.setTxIrq1Source(xe1205_tx_irq1_src_t src) 
  {
    error_t status;

    if (src > 1) return EINVAL;

    if (call SpiResource.isOwner()) return EBUSY;

    status = call SpiResource.immediateRequest();
    xe1205check(4, status);
    if (status != SUCCESS) return status;

    irqparam5 &= ~(1 << 3);
    irqparam5 |= (src << 3);
    call IrqParam5.write(irqparam5);
    call SpiResource.release();
    return SUCCESS;
  }


  void clearFifoOverrun() {
    irqparam5 |= 1;
    call IrqParam5.write(irqparam5);
  }

  /**
   * Clear FIFO overrun flag.
   */
  async command error_t XE1205IrqConf.clearFifoOverrun(bool haveResource) 
  {
    error_t status;

    if (haveResource) {
      clearFifoOverrun();
    } else {
      if (call SpiResource.isOwner()) return EBUSY;
      status = call SpiResource.immediateRequest();
      clearFifoOverrun();
      call SpiResource.release();
    }
    return SUCCESS;
    
  }

  bool getFifoOverrun() {
    uint8_t reg;
    call IrqParam5.read(&reg);
    return reg & 1;
  }

  async command error_t XE1205IrqConf.getFifoOverrun(bool haveResource, bool* fifooverrun) 
  {
    error_t status;

    if (haveResource) {
      *fifooverrun = getFifoOverrun();
    } else {
      if (call SpiResource.isOwner()) return EBUSY;
      status = call SpiResource.immediateRequest();
      xe1205check(5, status);
      if (status != SUCCESS) return status;
      *fifooverrun = getFifoOverrun();
      call SpiResource.release();
    }
    return SUCCESS;
  }
  
  void armPatternDetector() {
    irqparam6 |= (1 << 6);
    call IrqParam6.write(irqparam6);  
  }

  /**
   * Arm the pattern detector (clear Start_detect flag).
   */
  async command error_t XE1205IrqConf.armPatternDetector(bool haveResource)  
  {
    error_t status;

    if (haveResource) {
      armPatternDetector();
    } else {
      if (call SpiResource.isOwner()) return EBUSY;
      status = call SpiResource.immediateRequest();
      xe1205check(5, status);
      if (status != SUCCESS) return status;
      armPatternDetector();
      call SpiResource.release();
    }
    return SUCCESS;
  }
}
