// $Id: TestUARTPhyP.nc,v 1.4 2006-12-12 18:22:51 vlahan Exp $

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

module TestUARTPhyP {
  uses {
    interface Boot;
    interface Alarm<TMilli, uint32_t> as TxTimer;
    interface Alarm<TMilli, uint32_t> as RxTimer;
    interface Alarm<TMilli, uint32_t> as TimerTimer;
    interface Alarm<TMilli, uint32_t> as CCATimer;
//     interface Alarm<TMilli, uint32_t> as SelfPollingTimer;    
//     interface Alarm<TMilli, uint32_t> as SleepTimer;
    interface Leds;
    interface TDA5250Control;
    interface Random;
    interface SplitControl as RadioSplitControl;
    interface PhyPacketTx;
    interface PhyPacketRx;
    interface RadioByteComm;
  }
}

implementation {
  
  #define TIMER_RATE 500
  #define NUM_BYTES     36
  
  uint8_t bytes_sent;
  bool sending;
  
  event void Boot.booted() {
    bytes_sent = 0;
    sending = FALSE;
    call RadioSplitControl.start();
  }
  
  event void RadioSplitControl.startDone(error_t error) {
    call TxTimer.start(call Random.rand16() % TIMER_RATE);
    call TimerTimer.start(call Random.rand16() % TIMER_RATE); 
    call RxTimer.start(call Random.rand16() % TIMER_RATE); 
    call CCATimer.start(call Random.rand16() % TIMER_RATE); 
  }
  
  event void RadioSplitControl.stopDone(error_t error) {
    call TxTimer.stop();
  }  

  /***********************************************************************
   * Commands and events
   ***********************************************************************/   

  async event void TxTimer.fired() {
    atomic {
      if(call TDA5250Control.TxMode() != FAIL) {
        bytes_sent = 0;
        sending = TRUE;
        call Leds.led0On();
        call Leds.led1On();
        call Leds.led2On();
        return;
      }
    }
    call TxTimer.start(call Random.rand16() % TIMER_RATE); 
  }
  
  async event void RxTimer.fired() {
    if(sending == FALSE)
      if(call TDA5250Control.RxMode() != FAIL)
        return;
    call RxTimer.start(call Random.rand16() % TIMER_RATE); 
  }
  
  async event void CCATimer.fired() {
    if(sending == FALSE)  
      if(call TDA5250Control.CCAMode() != FAIL)
        return;
    call CCATimer.start(call Random.rand16() % TIMER_RATE); 
  }
  
  async event void TimerTimer.fired() {
    if(sending == FALSE)  
      if(call TDA5250Control.TimerMode(call Random.rand16() % TIMER_RATE/20, 
                                       call Random.rand16() % TIMER_RATE/20) != FAIL)                        
        return;
    call TimerTimer.start(call Random.rand16() % TIMER_RATE);                   
  }
  
//   async event void SelfPollingTimer.fired() {
//     if(sending == FALSE)
//       if(call TDA5250Control.SelfPollingMode(call Random.rand16() % TIMER_RATE/20, 
//                                              call Random.rand16() % TIMER_RATE/20) != FAIL)
//         return;
//     call SelfPollingTimer.start(call Random.rand16() % TIMER_RATE); 
//   }
  
//   async event void SleepTimer.fired() {
//     if(sending == FALSE)  
//       if(call TDA5250Control.SleepMode() != FAIL)
//          return;
//     call SleepTimer.start(call Random.rand16() % TIMER_RATE); 
//   }  
          
    
  async event void TDA5250Control.TxModeDone(){
    call PhyPacketTx.sendHeader();
  }
  
  async event void PhyPacketTx.sendHeaderDone(error_t error) {
    call RadioByteComm.txByte(call Random.rand16() / 2);
  }
  
  async event void RadioByteComm.txByteReady(error_t error) {
    if(++bytes_sent < NUM_BYTES)
      call RadioByteComm.txByte(call Random.rand16() / 2);
    else {
      bytes_sent = 0;  
      call PhyPacketTx.sendFooter();    
    }
  } 
  
  async event void PhyPacketTx.sendFooterDone(error_t error) {
    call TDA5250Control.SleepMode();
    sending = FALSE;    
    call TxTimer.start(call Random.rand16() % TIMER_RATE);
  }  
  
  async event void TDA5250Control.TimerModeDone(){ 
    call TimerTimer.start(call Random.rand16() % TIMER_RATE); 
    call Leds.led0On();
    call Leds.led1On();
    call Leds.led2Off();    
  }
  async event void TDA5250Control.SelfPollingModeDone(){ 
//     call SelfPollingTimer.start(call Random.rand16() % TIMER_RATE);   
//     call Leds.led0On();
//     call Leds.led1Off();
//     call Leds.led2On();        
  }  
  async event void TDA5250Control.RxModeDone(){ 
    call RxTimer.start(call Random.rand16() % TIMER_RATE);   
    call Leds.led0Off();
    call Leds.led1On();
    call Leds.led2On();  
  }
  async event void TDA5250Control.SleepModeDone(){ 
//     call SleepTimer.start(call Random.rand16() % TIMER_RATE);   
    call Leds.led0Off();
    call Leds.led1Off();
    call Leds.led2On();
  }
  async event void TDA5250Control.CCAModeDone(){ 
    call CCATimer.start(call Random.rand16() % TIMER_RATE);   
    call Leds.led0On();
    call Leds.led1Off();
    call Leds.led2Off();  
  }    
  
  async event void TDA5250Control.PWDDDInterrupt() {
  }
  async event void PhyPacketRx.recvHeaderDone() {}    
  async event void PhyPacketRx.recvFooterDone(bool error) {}  
  async event void RadioByteComm.rxByteReady(uint8_t data) {}
  
}


