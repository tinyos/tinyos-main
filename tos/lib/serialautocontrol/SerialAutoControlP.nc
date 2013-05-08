/** Copyright (c) 2011, University of Szeged
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
* Author: Andras Biro
*/
module SerialAutoControlP{
  provides interface SplitControl as SerialControl;
  uses interface SplitControl;
  uses interface GpioInterrupt as ControlInt;
  uses interface GeneralIO as ControlPin;
  provides interface Init as SoftwareInit;
  #ifdef SERIAL_AUTO_DEBUG
  uses interface Leds;
  #endif
}
implementation{
  
  bool isSerialOn;
  
  command error_t SerialControl.start() {
    if(call ControlPin.get()) {
      error_t err = call SplitControl.start();
      
      if(err == SUCCESS)
       isSerialOn = TRUE;

      return err;
    } else
      return FAIL;
  }
  
  command error_t SerialControl.stop() {
    error_t err = call SplitControl.stop();
     
    if(err == SUCCESS)
      isSerialOn = FALSE;
    
    return err;
  }
  
  task void turnOn(){
    error_t err=call SplitControl.start();  
    if(err!=SUCCESS&&err!=EALREADY)
      post turnOn();
    else{
      #ifdef SERIAL_AUTO_DEBUG
      call Leds.led1On();
      #endif
    }
  }
  
  task void turnOff(){
    error_t err=call SplitControl.stop();
    if(err!=SUCCESS&&err!=EALREADY)
      post turnOff();
    else{
      #ifdef SERIAL_AUTO_DEBUG
      call Leds.led1Off();
      #endif
    }
  }
  
  event void SplitControl.startDone(error_t err){
    if(err!=SUCCESS)
      call SplitControl.start();
  }
  
  event void SplitControl.stopDone(error_t err){
    if(err!=SUCCESS)
      call SplitControl.stop();
  }
  
  
  command error_t SoftwareInit.init(){
    if(call ControlPin.get()){
      isSerialOn=TRUE;
      post turnOn();
      call ControlInt.enableFallingEdge();
    } else {
      isSerialOn=FALSE;
      post turnOff();
      call ControlInt.enableRisingEdge();
    }     
    return SUCCESS;
  }
  
  async event void ControlInt.fired(){
    bool pinState=call ControlPin.get();
    if(pinState && !isSerialOn ){
      isSerialOn=TRUE;
      post turnOn();
      call ControlInt.enableFallingEdge();
    } else if ( !pinState && isSerialOn){
      isSerialOn=FALSE;
      post turnOff();
      call ControlInt.enableRisingEdge();
    }     
    #ifdef SERIAL_AUTO_DEBUG
    call Leds.led0Toggle();
    #endif
  }
}