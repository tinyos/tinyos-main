// $Id: SoftCaptureP.nc,v 1.6 2008-06-11 00:46:24 razvanm Exp $

/*
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

/**
 * Emulates GPIO capture functionality using GpioInterrupt and the 
 * standard 32khz counter
 *
 * @author Phil Buonadonna
 */
generic module SoftCaptureP ()
{
  provides interface GpioCapture;
  uses {
    interface GpioInterrupt;
    interface Counter<T32khz,uint32_t> as Counter32khz32;
  }
}

implementation 
{

  async command error_t GpioCapture.captureRisingEdge() {
    return (call GpioInterrupt.enableRisingEdge());
  }

  async command error_t GpioCapture.captureFallingEdge() {
    return (call GpioInterrupt.enableFallingEdge());
  }

  async command void GpioCapture.disable() {
    call GpioInterrupt.disable();
    return;
  }
  
  async event void GpioInterrupt.fired() {
    uint16_t captureTime;

    captureTime = (uint16_t) call Counter32khz32.get();
    signal GpioCapture.captured(captureTime);
    return;
  }

  async event void Counter32khz32.overflow() {
    return;
  }

  default async event void GpioCapture.captured(uint16_t time) {
    return;
  }
}
