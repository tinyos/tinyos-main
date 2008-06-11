// $Id: HalPXA27xSoftCaptureP.nc,v 1.5 2008-06-11 00:42:13 razvanm Exp $
/*
 * Copyright (c) 2005 Arch Rock Corporation 
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
 *   Neither the name of the Arch Rock Corporation nor the names of its
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
 * Emulates GPIO capture functionality using GpioInterrupt and the 
 * standard 32khz counter. Provides a method to capture on BOTH edges of
 * a GPIO transition.
 *
 * @author Phil Buonadonna
 */
generic module HalPXA27xSoftCaptureP ()
{
  provides interface HalPXA27xGpioCapture;
  uses {
    interface HalPXA27xGpioInterrupt;
    interface Counter<T32khz,uint32_t> as Counter32khz32;
  }
}

implementation 
{

  async command error_t HalPXA27xGpioCapture.captureRisingEdge() {
    return (call HalPXA27xGpioInterrupt.enableRisingEdge());
  }

  async command error_t HalPXA27xGpioCapture.captureFallingEdge() {
    return (call HalPXA27xGpioInterrupt.enableFallingEdge());
  }

  async command error_t HalPXA27xGpioCapture.captureBothEdge() {
    return (call HalPXA27xGpioInterrupt.enableBothEdge());
  }

  async command void HalPXA27xGpioCapture.disable() {
    call HalPXA27xGpioInterrupt.disable();
    return;
  }
  
  async event void HalPXA27xGpioInterrupt.fired() {
    uint16_t captureTime;

    captureTime = (uint16_t) call Counter32khz32.get();
    signal HalPXA27xGpioCapture.captured(captureTime);
    return;
  }

  async event void Counter32khz32.overflow() {
    return;
  }

  default async event void HalPXA27xGpioCapture.captured(uint16_t time) {
    return;
  }
}
