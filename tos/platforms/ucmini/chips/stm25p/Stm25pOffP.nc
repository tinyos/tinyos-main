/*
 * Copyright (c) 2010, University of Szeged
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
 * Author: Zsolt Szabo
 */

module Stm25pOffP {
  provides interface Init as Stm25pOff;
  #if !defined(UCMINI_REV) || (UCMINI_REV > 100)
  uses interface GeneralIO as Toggle;
  #else
  uses interface Resource as SpiResource;
  uses interface GeneralIO as CSN;
  uses interface GeneralIO as Hold;
  uses interface SpiByte;
  #endif 
}
implementation {

  command error_t Stm25pOff.init() {
    #if !defined(UCMINI_REV) || (UCMINI_REV > 100)
      call Toggle.makeOutput();
      #if !defined(UCMINI_REV) || (UCMINI_REV > 101)
        call Toggle.clr();
      #else
        call Toggle.set();
      #endif
    #else
    call CSN.makeOutput();
    call Hold.makeOutput();
    if(!uniqueCount("Stm25pOn")) {
      call SpiResource.request();
    }
    #endif
    return SUCCESS;
  }

	#if (defined(UCMINI_REV) && UCMINI_REV<101)
  event void SpiResource.granted() {
    if(!uniqueCount("Stm25pOn")) {//we got the granted event if the real driver asks for the resource
      call CSN.clr();
      call Hold.clr();
      call SpiByte.write(0xb9);//deep sleep
      call CSN.set();
      call Hold.set();
      call SpiResource.release();
    }
  }
  #endif
}
