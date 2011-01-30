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

module Sam3uDmaControlP {

  provides interface Sam3uDmaControl as Control;
  uses interface HplSam3uDmaControl as DmaControl;
  //uses interface HplSam3uDmaChannel as DmaChannel0;
  //uses interface HplSam3uDmaChannel as DmaChannel1;
  //uses interface HplSam3uDmaChannel as DmaChannel2;
  //uses interface HplSam3uDmaChannel as DmaChannel3;
  //uses interface HplSam3uDmaInterrupt as Interrupt;
}

implementation {

  async command error_t Control.init(){
    call DmaControl.init();
    return SUCCESS;
  }

  async command error_t Control.setArbitor(bool roundRobin){
    if(roundRobin){
      return call DmaControl.setRoundRobin();
    }else{
      return call DmaControl.setFixedPriority();
    }
  }
  /*
  async event void DmaChannel0.transferDone(error_t err){}
  async event void DmaChannel1.transferDone(error_t err){}
  async event void DmaChannel2.transferDone(error_t err){}
  async event void DmaChannel3.transferDone(error_t err){}
  */
}
