// $Id: TestTimerC.nc,v 1.1 2007-04-10 01:23:13 scipio Exp $

/*									tab:4
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
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
      dbg("TestTimer", "Timer %c is off. Should have fired in %u, fired in %u.\n", name, interval, (uint32_t)elapsed);
    }
    else {
      dbg("TestTimer", "Timer %c is good.\n", name);
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
    call C.startOneShot(cTime);
    call D.startOneShot(dTime);
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
      aTime = call Random.rand32() & 0x3ff;
      call A.startPeriodic(aTime);
    }
  }
  
  event void B.fired() {
    check('B', bStart, bTime);
    call B.stop();
    bTime = call Random.rand32() & 0x3ff;
    call B.startPeriodic(bTime);
    bStart = sim_time();
  }
  
  event void C.fired() {
    check('C', cStart, cTime);
    if (cTime & 0xff) {
      call C.stop();
      cTime = call Random.rand32() & 0x3ff;
    }
    call C.startOneShot(cTime);
    cStart = sim_time();
  }
  
  event void D.fired() {
    check('D', dStart, dTime);
    dTime = call Random.rand32() & 0x3ff;
    call D.startOneShot(dTime);
    dStart = sim_time();
  }
  
}




