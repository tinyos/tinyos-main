// $Id: TestUARTPhyP.nc,v 1.5 2010-06-29 22:07:32 scipio Exp $

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

module TestUARTPhyP {
  uses {
	  interface Boot;
	  interface Alarm<TMilli, uint32_t> as TxTimer;
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
  
#define TX_TIMER_RATE 500
#define NUM_BYTES     36
  
  uint8_t bytes_sent;
  
  event void Boot.booted() {
	  bytes_sent = 0;
	  call RadioSplitControl.start();
  }
  
  event void RadioSplitControl.startDone(error_t error) {
	  // call TDA5250Control.TxMode();
	  call TDA5250Control.RxMode();
  }
  
  event void RadioSplitControl.stopDone(error_t error) {
	  call TxTimer.stop();
  }  

  /***********************************************************************
  * Commands and events
  ***********************************************************************/   

  async event void TxTimer.fired() {
	  call TDA5250Control.TxMode();
  }
    
  async event void TDA5250Control.TxModeDone(){
	  call PhyPacketTx.sendHeader();
  }
  
  async event void PhyPacketTx.sendHeaderDone(error_t error) {
	  call RadioByteComm.txByte(call Random.rand16() / 2);
  }
  
  async event void RadioByteComm.txByteReady(error_t error) {
	  if(++bytes_sent < NUM_BYTES) {
      		  call RadioByteComm.txByte(call Random.rand16() / 2);
    	  } else { 
		  bytes_sent = 0;  
		  call PhyPacketTx.sendFooter();    
	  }
  } 
  
  async event void PhyPacketTx.sendFooterDone(error_t error) {
	  call TDA5250Control.SleepMode();
	  call TxTimer.start(call Random.rand16() % TX_TIMER_RATE);   
	  call Leds.led0Toggle();
  }  

  async event void PhyPacketRx.recvHeaderDone() {
	  call Leds.led2On();
  }    
  
  async event void PhyPacketRx.recvFooterDone(bool error) {
  }  
  
  async event void RadioByteComm.rxByteReady(uint8_t data) {
	  call Leds.led2Toggle();
  }  
  
  async event void TDA5250Control.PWDDDInterrupt() {
  }
  async event void TDA5250Control.TimerModeDone(){ 
  }
  async event void TDA5250Control.SelfPollingModeDone(){       
  }  
  async event void TDA5250Control.RxModeDone(){ 
  }
  async event void TDA5250Control.SleepModeDone(){  
  }
  async event void TDA5250Control.CCAModeDone(){ 
  }  
  
}


