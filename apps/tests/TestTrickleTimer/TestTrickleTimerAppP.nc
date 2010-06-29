// $Id: TestTrickleTimerAppP.nc,v 1.6 2010-06-29 22:07:25 scipio Exp $
/*
 * Copyright (c) 2006 Stanford University. All rights reserved.
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
 */

/*
 * Test of the trickle timers.
 * @author Philip Levis
 * @date   Jan 7 2006
 */ 

module TestTrickleTimerAppP {
  provides interface Init;
  uses {
    interface Boot;
    interface TrickleTimer as TimerA;
    interface TrickleTimer as TimerB;
    interface TrickleTimer as TimerC;
    interface TrickleTimer as TimerD;
    interface Random;
  }
}
implementation {

  bool a = 0;
  bool b = 0;
  bool c = 0;
  bool d = 0;

  command error_t Init.init() {return SUCCESS;}
  
  event void Boot.booted() {
    a = 1;
    call TimerA.reset();
    call TimerA.start();
  }

  event void TimerA.fired() {
    dbg("TestTrickle", "   Timer A fired at %s\n", sim_time_string());
    if (!b) {
      call TimerB.reset();
      call TimerB.start();
      b = 1;
    }
  }
  

  event void TimerB.fired() {
    dbg("TestTrickle", "  Timer B fired at %s\n", sim_time_string());
    if (!c) {
    call TimerC.reset();
      call TimerC.start();
      b = 1;
    }
  }
  
  
  event void TimerC.fired() {
    dbg("TestTrickle", " Timer C fired at %s\n", sim_time_string());
    if (!d) {
      call TimerD.reset();
      call TimerD.start();
      b = 1;
    }
  }

  uint16_t i = 0;
  event void TimerD.fired() {
    dbg("TestTrickle", "Timer D fired at %s\n", sim_time_string());
    i = call Random.rand16();
    i = i % 4;
    switch (i) {
    case 0:
      call TimerA.reset();
      break;
    case 1:
      call TimerB.reset();
      break;
    case 2:
      call TimerC.reset();
      break;
    case 3:
      call TimerD.reset();
      break;
    }
  }

  
  
}

  
