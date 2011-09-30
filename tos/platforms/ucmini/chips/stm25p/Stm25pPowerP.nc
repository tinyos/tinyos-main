/*
 * Copyright (c) 2011, University of Szeged
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holder nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Author: Andras Biro
 */

module Stm25pPowerP{
  provides interface Init;
  uses interface GeneralIO as Power;  
  #ifndef STM25P_HW_POWER_DISABLE
  provides interface SplitControl;
  uses interface SplitControl as SpiControl;
  uses interface Timer<TMilli>;
  #endif
}
implementation{
#ifdef STM25P_HW_POWER_DISABLE
  
  command error_t Init.init(){
    call Power.makeOutput();
    call Power.clr();
    return SUCCESS;
  }
  
#else

  bool spiOn=FALSE;
  bool powerOn=TRUE;
  
  command error_t Init.init(){
    call Power.makeOutput();
    call Power.set();
    powerOn=FALSE;
    return SUCCESS;
  }
  
  command error_t SplitControl.start(){
    error_t err;
    if(spiOn&&powerOn)
      return EALREADY;
    else if(spiOn||powerOn)
      return EBUSY;
    err=call SpiControl.start();
    if(err==SUCCESS){
      call Power.clr();
      call Timer.startOneShot(10);
    }
    return err;
  }
  
  event void Timer.fired(){
    powerOn=TRUE;
    if(spiOn)
      signal SplitControl.startDone(SUCCESS);
  }
  
  event void SpiControl.startDone(error_t err){
    if(err==SUCCESS){
      spiOn=TRUE;
      if(powerOn)
        signal SplitControl.startDone(SUCCESS);
    } else {
      call Timer.stop();
      call Power.set();
      signal SplitControl.startDone(err);
    }
  }
  
  task void signalStopDone(){
    signal SplitControl.stopDone(SUCCESS);
  }
  
  command error_t SplitControl.stop(){
    if((!spiOn)&&(!powerOn))
      return EALREADY;
    else if((!spiOn)||(!powerOn))
      return EBUSY;
    return call SpiControl.stop();
  }
  
  event void SpiControl.stopDone(error_t err){
    if(err==SUCCESS){
      spiOn=FALSE;
      call Power.set();
      powerOn=FALSE;
    }
    signal SplitControl.stopDone(err);
  }
#endif
}
