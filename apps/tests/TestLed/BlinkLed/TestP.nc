/* 
 * Copyright (c) 2009-2010 People Power Company
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
 * - Neither the name of the People Power Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * PEOPLE POWER CO. OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

/**
 * Much like Blink, but uses the Led interface. 
 *
 * TESTS: Led interface
 * TESTS: Timer<TMilli>
 *
 * @author David Moss
 * @author Peter A. Bigot <pab@peoplepowerco.com> */
module TestP {
  uses {
    interface Boot;
    interface Timer<TMilli> as Timer1;
    interface Timer<TMilli> as Timer2;
    interface Timer<TMilli> as Timer3;
    interface Led as Led1;
    interface Led as Led2;
    interface Led as Led3;
  }
} implementation {

  event void Boot.booted() {
    call Led1.on();
    call Timer1.startPeriodic(256);
    call Timer2.startPeriodic(512);
    call Timer3.startPeriodic(1024);
  }
  
  event void Timer1.fired() {
    call Led1.toggle();
  }
  
  event void Timer2.fired() {
    call Led2.toggle();
  }    

  event void Timer3.fired() {
    call Led3.toggle();
  }    

}
