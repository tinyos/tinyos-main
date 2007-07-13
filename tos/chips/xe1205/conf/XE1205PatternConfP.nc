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

/**
 * Implementation of XE1205PatternConf interface.
 *
 * @author Henri Dubois-Ferriere
 */



module XE1205PatternConfP {

  provides interface XE1205PatternConf;
  provides interface Init @atleastonce();

  uses interface Resource as SpiResource;
  uses interface XE1205Register as RXParam10;
  uses interface XE1205Register as Pattern13;
  uses interface XE1205Register as Pattern14;
  uses interface XE1205Register as Pattern15;
  uses interface XE1205Register as Pattern16;
} 
implementation {

#include "xe1205debug.h"

  task void initTask() {
    atomic {
      xe1205check(1, call SpiResource.immediateRequest()); // should always succeed: task happens after softwareInit, before interrupts are enabled

      call RXParam10.write(0x10 | 2 << 2); // pattern detection enabled, error tolerance=0, pattern length 3
      call Pattern13.write((data_pattern >> 16) & 0xff);
      call Pattern14.write((data_pattern >> 8) & 0xff);
      call Pattern15.write(data_pattern & 0xff);
      call SpiResource.release();
    }
  }

  command error_t Init.init() 
  {
    post initTask();
    return SUCCESS;
  }
  
  event void SpiResource.granted() {  }

  async command error_t XE1205PatternConf.setDetectLen(uint8_t len) 
  {
    uint8_t reg;
    error_t status;

    if (len == 0 || len > 4)  return EINVAL;

    if (call SpiResource.isOwner()) return EBUSY;
    status = call SpiResource.immediateRequest();
    xe1205check(2, status);
    if (status != SUCCESS) return status;

    call RXParam10.read(&reg);
    
    reg &= ~(3 << 2);
    reg |= (len << 2);
    
    call RXParam10.write(reg);
    call SpiResource.release();
    return SUCCESS;
  }
  async command error_t XE1205PatternConf.loadDataPatternHasBus() {
      
      call Pattern13.write((data_pattern >> 16) & 0xff);
      call Pattern14.write((data_pattern >> 8) & 0xff);
      call Pattern15.write(data_pattern & 0xff);
     
    return SUCCESS;

  }

  async command error_t XE1205PatternConf.loadAckPatternHasBus() {

      call Pattern13.write((ack_pattern >> 16) & 0xff);
      call Pattern14.write((ack_pattern >> 8) & 0xff);
      call Pattern15.write(ack_pattern & 0xff);

    return SUCCESS;

  }

  async command error_t XE1205PatternConf.loadPattern(uint8_t* pattern, uint8_t len) 
  {
    error_t status;

    if (len == 0 || len > 4) return EINVAL;

    if (call SpiResource.isOwner()) return EBUSY;
    status = call SpiResource.immediateRequest();
    xe1205check(3, status);
    if (status != SUCCESS) return status;

    call Pattern13.write(*pattern++);
    if (len == 1) goto done;

    call Pattern14.write(*pattern++);
    if (len == 2) goto done;

    call Pattern15.write(*pattern++);
    if (len == 3) goto done;

    call Pattern16.write(*pattern);

  done:
      call SpiResource.release();
      return SUCCESS;

  }    



  async command error_t XE1205PatternConf.setDetectErrorTol(uint8_t nerrors) 
  {
    uint8_t reg;
    error_t status;

    if (nerrors > 3) return EINVAL;
    
    if (call SpiResource.isOwner()) return EBUSY;
    status = call SpiResource.immediateRequest();
    xe1205check(4, status);
    if (status != SUCCESS) return status;

    call RXParam10.read(&reg);
    
    reg &= ~(0x03);
    reg |= nerrors;
    
    call RXParam10.write(reg);
    call SpiResource.release();
    return SUCCESS;
  }
}
