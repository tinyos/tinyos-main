// $Id: TestTimerC.nc,v 1.4 2010-06-29 22:07:25 scipio Exp $

/*									tab:4
 * Copyright (c) 2000-2005 The Regents of the University  of California.  
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
 * - Neither the name of the University of California nor the names of
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 *  Implementation of the TestTimer application.
 *
 *  @author Phil Levis
 *  @date   April 7 2007
 *
 **/

module TestTimerC {
  uses {
    interface Boot;
    interface Timer<TMilli> as A;
    interface Timer<TMilli> as B;
    interface Timer<TMilli> as C;
    interface Timer<TMilli> as D;
    interface Random;
  }
}
implementation {

  uint32_t aTime;
  uint32_t bTime;
  uint32_t cTime;
  uint32_t dTime;

  sim_time_t aStart;
  sim_time_t bStart;
  sim_time_t cStart;
  sim_time_t dStart;

  void check(char name, sim_time_t start, uint32_t interval) {
    sim_time_t now = sim_time();
    sim_time_t elapsed = now - start;
    elapsed /= (sim_ticks_per_sec() / 1024);
    if (elapsed != interval) {
      dbg("TestTimer", "Timer %c is off. Should have fired in %u, fired in %u @ %s.\n", name, interval, (uint32_t)elapsed, sim_time_string());
    }
    else {
      dbg("TestTimer", "Timer %c is good @ %s.\n", name, sim_time_string());
    }
  }
  
  void randomizeTimers() {
    aTime = call Random.rand32() & 0x3ff;
    bTime = call Random.rand32() & 0x3ff;
    cTime = call Random.rand32() & 0x3ff;
    dTime = call Random.rand32() & 0x3ff;
  }

  void startTimers() {
    call A.startPeriodic(aTime);
    call B.startPeriodic(bTime);
//    call C.startOneShot(cTime);
 //   call D.startOneShot(dTime);
    aStart = bStart = cStart = dStart = sim_time();
  }
  
  event void Boot.booted() {
    randomizeTimers();
    startTimers();
  }

  event void A.fired() {
    check('A', aStart, aTime);
    aStart = sim_time();
    if (aTime & 0xff) {
      call A.stop();
      aTime = 1 + (call Random.rand32() & 0x3ff);
      call A.startPeriodic(aTime);
    }
  }
  
  event void B.fired() {
    check('B', bStart, bTime);
    call B.stop();
    bTime = 1 + (call Random.rand32() & 0x3fff);
    call B.startPeriodic(bTime);
    bStart = sim_time();
  }
  
  event void C.fired() {
    check('C', cStart, cTime);
    if (cTime & 0xff) {
      call C.stop();
      cTime = 1 + (call Random.rand32() & 0x3ff);
    }
    call C.startOneShot(cTime);
    cStart = sim_time();
  }
  
  event void D.fired() {
    check('D', dStart, dTime);
    dTime = 1 + (call Random.rand32() & 0x3ff);
    call D.startOneShot(dTime);
    dStart = sim_time();
  }
  
}




