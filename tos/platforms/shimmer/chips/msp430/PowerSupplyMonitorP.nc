/*
 * Copyright (c) 2007, Intel Corporation
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 * Redistributions of source code must retain the above copyright notice, 
 * this list of conditions and the following disclaimer. 
 *
 * Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution. 
 *
 * Neither the name of the Intel Corporation nor the names of its contributors
 * may be used to endorse or promote products derived from this software 
 * without specific prior written permission. 
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
 * POSSIBILITY OF SUCH DAMAGE.
 *
 * @author  Steve Ayer
 * @date    March, 2007
 *
 * support for interface to msp430 SVSCTL functionality
 */

//#include "PowerSupplyMonitor.h"

module PowerSupplyMonitorP {
  provides {
    interface Init;
    interface StdControl;
    interface PowerSupplyMonitor;
  }
  uses{
    interface Timer<TMilli> as Timer;
    interface Leds;
  }
}

implementation {
  uint8_t threshold;
  uint32_t monitor_interval;
  bool started, spurious_check;

  /* 
   * sets svs to first voltage level beneath regulator (2.9v), 
   * no reset, 15 minute polling 
   */
  void init() {
    threshold = THREE_7V;
    monitor_interval = 900000;  

    SVSCTL = 0;
    //    CLR_FLAG(SVSCTL, 0xff);
  }
  
  /* turns on svs to highest voltage level (3.7v), no reset */
  command error_t Init.init(){
    started = FALSE;
    spurious_check = FALSE;

    init();
    
    return SUCCESS;
  }

  command error_t StdControl.start(){
    CLR_FLAG(SVSCTL, VLD_EXT);
    SET_FLAG(SVSCTL, threshold);

    started = TRUE;
    call Timer.startPeriodic(monitor_interval);
    return SUCCESS;
  }

  command error_t StdControl.stop(){
    call PowerSupplyMonitor.disable();

    started = FALSE;
    return SUCCESS;
  }


  task void spurious_test(){
    call Timer.stop();
    started = FALSE;

    atomic{
      CLR_FLAG(SVSCTL, VLD_EXT);  // set vld to zero to stop detection
      CLR_FLAG(SVSCTL, SVSFG);
    }

    spurious_check = TRUE;
    call Timer.startOneShot(5000);
  }

  task void recheck(){
    spurious_check = FALSE;

    SET_FLAG(SVSCTL, threshold);  // set vld back to threshold, restart detection

    TOSH_uwait(1000);  // wait for svs to settle back down (max time ~ 50us, but hey)

    atomic if(READ_FLAG(SVSCTL, SVSFG)){
      CLR_FLAG(SVSCTL, threshold);  // set vld back to threshold, restart detection
      signal PowerSupplyMonitor.voltageThresholdReached(threshold);
    }
  }
      
  event void Timer.fired(){
    if(spurious_check)
      post recheck();
    else{
      atomic if(READ_FLAG(SVSCTL, SVSFG))
	post spurious_test();
    }
  }

  command void PowerSupplyMonitor.resetOnLowVoltage(bool reset){
    if(reset)
      SET_FLAG(SVSCTL, PORON);
    else
      CLR_FLAG(SVSCTL, PORON);
  }

  /* enum in PowerSupplyVoltage.h for this */
  command void PowerSupplyMonitor.setVoltageThreshold(uint8_t t){
    threshold = t;
    if(started){
      CLR_FLAG(SVSCTL, VLD_EXT);  
      SET_FLAG(SVSCTL, t);
    }
  }

  command error_t PowerSupplyMonitor.isSupplyMonitorEnabled(){
    return READ_FLAG(SVSCTL, SVSON);
  }

  command error_t PowerSupplyMonitor.queryLowVoltageCondition(){
    return READ_FLAG(SVSCTL, SVSFG);
  }


  command void PowerSupplyMonitor.setMonitorInterval(uint32_t interval_ms){
    monitor_interval = interval_ms;
    if(started){
      call Timer.stop();
      call Timer.startPeriodic(monitor_interval);
    }
  }

  command void PowerSupplyMonitor.clearLowVoltageCondition(){
    CLR_FLAG(SVSCTL, SVSFG);
  }

  command void PowerSupplyMonitor.stopVoltageMonitor() {
    call Timer.stop();
  }

  command void PowerSupplyMonitor.disable(){
    CLR_FLAG(SVSCTL, 0xf0);

    started = FALSE;

    call Timer.stop();
  }
}
