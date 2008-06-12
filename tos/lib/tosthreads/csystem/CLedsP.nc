/*
 * Copyright (c) 2008 Stanford University.
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
 * - Neither the name of the Stanford University nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL STANFORD
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */
 
/**
 * @author Kevin Klues (klueska@cs.stanford.edu)
 */
 
module CLedsP {
  uses {
    interface Leds;
  }
}
implementation {
  void led0On() @C() @spontaneous(){
    call Leds.led0On();
  }
  void led0Off() @C() @spontaneous(){
    call Leds.led0Off();
  }
  void led0Toggle() @C() @spontaneous(){
    call Leds.led0Toggle();
  }

  void led1On() @C() @spontaneous(){
    call Leds.led1On();
  }
  void led1Off() @C() @spontaneous(){
    call Leds.led1Off();
  }
  void led1Toggle() @C() @spontaneous(){
    call Leds.led1Toggle();
  }
  
  void led2On() @C() @spontaneous(){
    call Leds.led2On();
  }
  void led2Off() @C() @spontaneous(){
    call Leds.led2Off();
  }
  void led2Toggle() @C() @spontaneous(){
    call Leds.led2Toggle();
  }

  uint8_t getLeds() @C() @spontaneous(){
    return call Leds.get();
  }
  void setLeds(uint8_t val) @C() @spontaneous(){
    call Leds.set(val);
  }
}
