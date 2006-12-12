// $Id: TestTrickleTimerAppP.nc,v 1.4 2006-12-12 18:22:51 vlahan Exp $
/*
 * "Copyright (c) 2006 Stanford University. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 * 
 * IN NO EVENT SHALL STANFORD UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF STANFORD UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 * 
 * STANFORD UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND STANFORD UNIVERSITY
 * HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES,
 * ENHANCEMENTS, OR MODIFICATIONS."
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

  uint8_t i = 0;
  event void TimerD.fired() {
    dbg("TestTrickle", "Timer D fired at %s\n", sim_time_string());
    i++;
    i = i % 3;
    switch (i) {
    case 0:
      //      call TimerA.reset();
      break;
    case 1:
      //      call TimerB.reset();
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

  
