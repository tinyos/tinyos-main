// $Id: TestTda5250ControlP.nc,v 1.5 2010-06-29 22:07:32 scipio Exp $

/*                                  tab:4
 * Copyright (c) 2000-2003 The Regents of the University  of California.
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
 * - Neither the name of the copyright holders nor the names of
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

module TestTda5250ControlP {
  uses {
    interface Boot;
    interface Alarm<TMilli, uint32_t> as ModeTimer;
    interface Leds;
    interface Tda5250Control;
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
  
  
  /* tasks and helper functions*/
  void setTimer() {
    call ModeTimer.start(call Random.rand16() % MODE_TIMER_RATE);     
  }
  task void RxModeTask() {
    if (call Tda5250Control.RxMode() != SUCCESS)
      post RxModeTask();
  }
  task void TxModeTask() {
  if (call Tda5250Control.TxMode() != SUCCESS)
    post TxModeTask();
  }
  task void SleepModeTask() {
    if (call Tda5250Control.SleepMode() != SUCCESS)
      post SleepModeTask();
  }
  
  /***********************************************************************
   * Commands and events
   ***********************************************************************/   

  async event void ModeTimer.fired() {
    switch(mode) {
/*      case 0:
       call Tda5250Control.TimerMode(call Random.rand16() % MODE_TIMER_RATE/20, 
                                     call Random.rand16() % MODE_TIMER_RATE/20);
        break;
      case 1:
        call Tda5250Control.SelfPollingMode(call Random.rand16() % MODE_TIMER_RATE/20, 
                                            call Random.rand16() % MODE_TIMER_RATE/20);        
        break;
 */      
      case 2:
        if (call Tda5250Control.RxMode() != SUCCESS)
          post RxModeTask();
        break;
      case 3:
        if (call Tda5250Control.TxMode() != SUCCESS)
          post TxModeTask();
        break;
      default:
        if (call Tda5250Control.SleepMode() != SUCCESS)
          post SleepModeTask();
        break;
    }
  }
  
  async event void Tda5250Control.PWDDDInterrupt() {
    call Tda5250Control.RxMode();
  }
  
  async event void Tda5250Control.TimerModeDone(){
    atomic mode = call Random.rand16() % 6;
    call Leds.led0On();
    call Leds.led1On();
    call Leds.led2On(); 
    setTimer();
  }
  async event void Tda5250Control.SelfPollingModeDone(){
    atomic mode = call Random.rand16() % 6;
    call Leds.led0On();
    call Leds.led1On();
    call Leds.led2Off();   
    setTimer();
  }  
  async event void Tda5250Control.RxModeDone(){
    atomic mode = call Random.rand16() % 6;
    call Leds.led0On();
    call Leds.led1Off();
    call Leds.led2On();  
    setTimer();
  }
  async event void Tda5250Control.TxModeDone(){
    atomic mode = call Random.rand16() % 6;
    call Leds.led0Off();
    call Leds.led1On();
    call Leds.led2On();  
    setTimer();
  }    
  async event void Tda5250Control.SleepModeDone(){
    atomic mode = call Random.rand16() % 6;
    call Leds.led0Off();
    call Leds.led1Off();
    call Leds.led2On();  
    setTimer();
  }
  async event void Tda5250Control.RssiStable(){
    atomic mode = call Random.rand16() % 6;
    call Leds.led0On();
    call Leds.led1Off();
    call Leds.led2Off();
  }  
  
}


