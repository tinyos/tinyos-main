/*
* Copyright (c) 2010, University of Szeged
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions
* are met:
*
* - Redistributions of source code must retain the above copyright
* notice, this list of conditions and the following disclaimer.
* - Redistributions in binary form must reproduce the above
* copyright notice, this list of conditions and the following
* disclaimer in the documentation and/or other materials provided
* with the distribution.
* - Neither the name of University of Szeged nor the names of its
* contributors may be used to endorse or promote products derived
* from this software without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
* "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
* FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
* COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
* INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
* (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
* SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
* HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
* STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
* OF THE POSSIBILITY OF SUCH DAMAGE.
*
* Author: Zsolt Szabo
*/
module I2CBusP {
  provides interface SplitControl;
  uses interface SplitControl as TemphumSplit;
  uses interface SplitControl as LightSplit;
  uses interface SplitControl as PressureSplit;
  uses interface GeneralIO as Power;

  uses interface DiagMsg;
  uses interface Leds;
}
implementation {
/*
cnt bits:
1:Temphum started
2:Temphum startDone
4:Light started
8:Light startDone
16:Pressure started
32:Pressure startDone
64:bus is on:all lower bits should be 1
128:bus is off: all lower bits should be 0

*/
  uint8_t cnt=128;
  bool startError;
  
  command error_t SplitControl.start() {
    error_t error;
    if(cnt&64)
      return EALREADY;
    else if(!(cnt&128) )
      return EBUSY;
    cnt=0;
    startError=FALSE;
    call Power.makeOutput();
    call Power.set();

    error=call TemphumSplit.start(); 
    if(error==SUCCESS){
      cnt|=1; //call Leds.led0On();
      error=call LightSplit.start();
    }
    if(error==SUCCESS){
      cnt|=4; //call Leds.led1On();
      error=call PressureSplit.start();
    }
    if(error==SUCCESS){
      cnt|=16; //call Leds.led2On();
      return SUCCESS;
    }
    else {
      startError=TRUE;//we should go to OFF state
      call Power.clr();
      return error;
    }
  }
  
  task void stopDone(){
    cnt=128;
    signal SplitControl.stopDone(SUCCESS);
  }  

  command error_t SplitControl.stop() {
    if(cnt&128)
      return EALREADY;
    else if(!(cnt&64))
      return EBUSY;
    cnt=0;
    call Power.clr();
    post stopDone();
    return SUCCESS;
  }
  
  event void TemphumSplit.startDone(error_t error) {
    if(error!=SUCCESS){
      call TemphumSplit.start();
      return;
    } call Leds.led0On();
    if(startError){
      cnt&=~1;
      if(cnt==0)
	cnt=128;
      return;
    }
    cnt |= 2;
    if(cnt == 63){
      cnt|=64;
      signal SplitControl.startDone(SUCCESS);
    } else signal SplitControl.startDone(FAIL);
  }
  
  event void LightSplit.startDone(error_t error) {
    if(error!=SUCCESS){
      call LightSplit.start();
      return;
    } call Leds.led1On();
    if(startError){
      cnt&=~4;
      if(cnt==0)
	cnt=128;
      return;
    }
    cnt |= 8;
    if(cnt == 63){
      cnt|=64;
      signal SplitControl.startDone(SUCCESS);
    } else signal SplitControl.startDone(FAIL);
  }
  
  event void PressureSplit.startDone(error_t error) {
    if(error!=SUCCESS){
      call PressureSplit.start();
      return;
    } call Leds.led2On();
    if(startError){
      cnt&=~16;
      if(cnt==0)
	cnt=128;
      return;
    }
    cnt |= 32;
    if(cnt == 63){
      cnt|=64;
      signal SplitControl.startDone(SUCCESS);
    } else signal SplitControl.startDone(FAIL);
  }
  
  
  event void TemphumSplit.stopDone(error_t error) {}

  event void LightSplit.stopDone(error_t error) {}

  event void PressureSplit.stopDone(error_t error) {}
  
  default event void SplitControl.startDone(error_t error) {call Leds.led3On(); }
  default event void SplitControl.stopDone(error_t error) { }
}
