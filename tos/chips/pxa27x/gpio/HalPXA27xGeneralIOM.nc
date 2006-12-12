// $Id: HalPXA27xGeneralIOM.nc,v 1.4 2006-12-12 18:23:12 vlahan Exp $

/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */

//@author Phil Buonadonna
module HalPXA27xGeneralIOM {
  provides {
    interface GeneralIO[uint8_t pin];
    interface HalPXA27xGpioInterrupt[uint8_t pin];
    interface GpioInterrupt[uint8_t pin];
  }
  uses {
    interface HplPXA27xGPIOPin[uint8_t pin];
  }
}

implementation {
  async command void GeneralIO.set[uint8_t pin]() {
    
    atomic call HplPXA27xGPIOPin.setGPSRbit[pin]();
    return;
  }

  async command void GeneralIO.clr[uint8_t pin]() {
    atomic call HplPXA27xGPIOPin.setGPCRbit[pin]();
    return;
  }

  async command void GeneralIO.toggle[uint8_t pin]() {
    atomic {
      if (call HplPXA27xGPIOPin.getGPLRbit[pin]()) {
	call HplPXA27xGPIOPin.setGPCRbit[pin]();
      }
      else {
	call HplPXA27xGPIOPin.setGPSRbit[pin]();
      }
    }
    return;
  }

  async command bool GeneralIO.get[uint8_t pin]() {
    bool result;
    result = call HplPXA27xGPIOPin.getGPLRbit[pin]();
    return result;
  }

  async command void GeneralIO.makeInput[uint8_t pin]() {
    atomic call HplPXA27xGPIOPin.setGPDRbit[pin](FALSE);
    return;
  }
  
  async command bool GeneralIO.isInput[uint8_t pin]() {
    bool result;
    result = !call HplPXA27xGPIOPin.getGPLRbit[pin]();
    return result;
  }
  
  async command void GeneralIO.makeOutput[uint8_t pin]() {
    atomic call HplPXA27xGPIOPin.setGPDRbit[pin](TRUE);
    return;
  }

  async command bool GeneralIO.isOutput[uint8_t pin]() {
    bool result;
    result = call HplPXA27xGPIOPin.getGPDRbit[pin]();
    return result;
  }
  
  async command error_t HalPXA27xGpioInterrupt.enableRisingEdge[uint8_t pin]() {
    atomic {
      call HplPXA27xGPIOPin.setGRERbit[pin](TRUE);
      call HplPXA27xGPIOPin.setGFERbit[pin](FALSE);
    }
    return SUCCESS;
  }

  async command error_t HalPXA27xGpioInterrupt.enableFallingEdge[uint8_t pin]() {
    atomic {
      call HplPXA27xGPIOPin.setGRERbit[pin](FALSE);
      call HplPXA27xGPIOPin.setGFERbit[pin](TRUE);
    }
    return SUCCESS;
  }

  async command error_t HalPXA27xGpioInterrupt.enableBothEdge[uint8_t pin]() {
    atomic {
      call HplPXA27xGPIOPin.setGRERbit[pin](TRUE);
      call HplPXA27xGPIOPin.setGFERbit[pin](TRUE);
    }
    return SUCCESS;
  }

  async command error_t HalPXA27xGpioInterrupt.disable[uint8_t pin]() {
    atomic {
      call HplPXA27xGPIOPin.setGRERbit[pin](FALSE);
      call HplPXA27xGPIOPin.setGFERbit[pin](FALSE);
      call HplPXA27xGPIOPin.clearGEDRbit[pin]();
    }
    return SUCCESS;
  }

  async command error_t GpioInterrupt.enableRisingEdge[uint8_t pin]() {
    return call HalPXA27xGpioInterrupt.enableRisingEdge[pin]();
  }

  async command error_t GpioInterrupt.enableFallingEdge[uint8_t pin]() {
    return call HalPXA27xGpioInterrupt.enableFallingEdge[pin]();
  }

  async command error_t GpioInterrupt.disable[uint8_t pin]() {
    return call HalPXA27xGpioInterrupt.disable[pin]();
  }

  async event void HplPXA27xGPIOPin.interruptGPIOPin[uint8_t pin]() {
    call HplPXA27xGPIOPin.clearGEDRbit[pin]();
    signal HalPXA27xGpioInterrupt.fired[pin]();
    signal GpioInterrupt.fired[pin]();
    return;
  }
  

  default async event void HalPXA27xGpioInterrupt.fired[uint8_t pin]() {
    return;
  }

  default async event void GpioInterrupt.fired[uint8_t pin]() {
    return;
  }

}
