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

#include "HplAtmegaExtInterrupt.h"

generic module AtmegaExtInterruptP(bool lowLevel){
  uses interface HplAtmegaExtInterrupt;
  provides interface GpioInterrupt;
}
implementation{
  
  async command error_t GpioInterrupt.enableRisingEdge(){
    atomic{
      call HplAtmegaExtInterrupt.setMode(ATMEGA_EXTINT_RISING_EDGE);
      call HplAtmegaExtInterrupt.enable();
      call HplAtmegaExtInterrupt.reset();
    }
    return SUCCESS;
  }
  
  async command error_t GpioInterrupt.enableFallingEdge(){
    atomic{
      call HplAtmegaExtInterrupt.setMode(lowLevel ? ATMEGA_EXTINT_LOW_LEVEL : ATMEGA_EXTINT_FALLING_EDGE);
      call HplAtmegaExtInterrupt.enable();
      call HplAtmegaExtInterrupt.reset();
    }
    return SUCCESS;
  }
  
  async command error_t GpioInterrupt.disable(){
    call HplAtmegaExtInterrupt.disable();
    return SUCCESS;
  }
  
  async event void HplAtmegaExtInterrupt.fired(){
    signal GpioInterrupt.fired();
  }
  
  default async event void GpioInterrupt.fired(){}
}
