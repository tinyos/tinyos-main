// $Id: TestTDA5250ControlM.nc,v 1.1.1.1 2005-11-04 18:20:16 kristinwright Exp $

/*                                  tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.
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

module TestTDA5250ControlM {
  uses {
    interface Boot;
    interface Alarm<TMilli, uint32_t> as ModeTimer;
    interface Leds;
    interface TDA5250Control;
    interface Random;
    interface SplitControl as RadioSplitControl;
  }
}

implementation {
  
  #define MODE_TIMER_RATE 500
  
  uint8_t mode;
  
  event void Boot.booted() {
    atomic mode = 0;
    call RadioSplitControl.start();
  }
  
  event void RadioSplitControl.startDone(error_t error) {
    call ModeTimer.start(MODE_TIMER_RATE);
  }
  
  event void RadioSplitControl.stopDone(error_t error) {
    call ModeTimer.stop();
  }  

  /***********************************************************************
   * Commands and events
   ***********************************************************************/   

  async event void ModeTimer.fired() {
    switch(mode) {
      case 0:
        call TDA5250Control.TimerMode(call Random.rand16() % MODE_TIMER_RATE/20, 
                                      call Random.rand16() % MODE_TIMER_RATE/20);
        break;
      case 1:
        call TDA5250Control.SelfPollingMode(call Random.rand16() % MODE_TIMER_RATE/20, 
                                            call Random.rand16() % MODE_TIMER_RATE/20);        
        break;
      case 2:
        call TDA5250Control.RxMode();
        break;
      case 3:
        call TDA5250Control.TxMode();
        break;
      case 4:
        call TDA5250Control.SleepMode();
        break;
      case 5:
        call TDA5250Control.CCAMode();
        break;
    }
  }
  
  async event void TDA5250Control.PWDDDInterrupt() {
    //call TDA5250Control.RxMode();
  }
  
  async event void TDA5250Control.TimerModeDone(){
    atomic mode = call Random.rand16() % 6;
    call Leds.led0On();
    call Leds.led1On();
    call Leds.led2On();   
    call ModeTimer.start(call Random.rand16() % MODE_TIMER_RATE);     
  }
  async event void TDA5250Control.SelfPollingModeDone(){
    atomic mode = call Random.rand16() % 6;
    call Leds.led0On();
    call Leds.led1On();
    call Leds.led2Off();   
    call ModeTimer.start(call Random.rand16() % MODE_TIMER_RATE);           
  }  
  async event void TDA5250Control.RxModeDone(){
    atomic mode = call Random.rand16() % 6;
    call Leds.led0On();
    call Leds.led1Off();
    call Leds.led2On();  
    call ModeTimer.start(call Random.rand16() % MODE_TIMER_RATE);      
  }
  async event void TDA5250Control.TxModeDone(){
    atomic mode = call Random.rand16() % 6;
    call Leds.led0Off();
    call Leds.led1On();
    call Leds.led2On();  
    call ModeTimer.start(call Random.rand16() % MODE_TIMER_RATE);  
  }    
  async event void TDA5250Control.SleepModeDone(){
    atomic mode = call Random.rand16() % 6;
    call Leds.led0Off();
    call Leds.led1Off();
    call Leds.led2On();  
    call ModeTimer.start(call Random.rand16() % MODE_TIMER_RATE);          
  }
  async event void TDA5250Control.CCAModeDone(){
    atomic mode = call Random.rand16() % 6;
    call Leds.led0On();
    call Leds.led1Off();
    call Leds.led2Off();
    call ModeTimer.start(call Random.rand16() % MODE_TIMER_RATE);    
  }  
  
}


