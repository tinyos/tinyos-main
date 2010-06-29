/*
 * Copyright (c) 2010, Vanderbilt University
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
 * - Neither the name of the copyright holder nor the names of
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
 * Author: Janos Sallai
 */  
 
module Msp430HybridAlarmCounterP {
	uses {
		interface Counter<TMicro,uint16_t> as CounterMicro; 
		interface Counter<T32khz,uint16_t> as Counter32khz;
		interface Alarm<TMicro,uint16_t> as AlarmMicro; 
		interface Alarm<T32khz,uint16_t> as Alarm32khz;
	}
	provides {
  		interface McuPowerOverride; 		
		interface Counter<T2ghz,uint32_t> as Counter2ghz; 
		interface Alarm<T2ghz,uint32_t> as Alarm2ghz; 	
	}
}
implementation {
	
  norace uint32_t fireTime;

  /*------------------------- UTILITY FUNCTIONS -------------------------*/
  inline uint16_t now32khz() {
  	return call Counter32khz.get();
  }

  inline uint16_t nowMicro() {
  	return call CounterMicro.get();
  }

  // return all three clock readings
  inline void now(uint16_t* t32khz, uint16_t* tMicro, uint32_t* t2ghz) {
   	uint16_t eMicro;
	
	atomic {
		// now from 32khz
		*t32khz = now32khz();
	
		// now from Micro
   		*tMicro = nowMicro();
   	
		// wait until the 32khz clock ticks
		while(*t32khz == now32khz());
	}
	
	// elapsed time since entering this function in Micro
   	eMicro = nowMicro() - *tMicro;

   	// hi byte of hybrid time is 32khz tick
   	*t2ghz = (uint32_t)(*t32khz) << 16;
   	
   	// adjust with the elapsed micro time
   	*t2ghz -= (uint32_t)eMicro << 11 ;
  }

  inline uint32_t now2ghz() {
   	uint16_t t32khz, tMicro;
	uint32_t t2ghz;	
	
	now(&t32khz, &tMicro, &t2ghz);
	
   	return t2ghz;
  }

  /*------------------------- COUNTER -------------------------*/
   
  /** 
   * Return counter value. May take up to 32us to complete.
   * @return Current counter value.
   */ 
   async command uint32_t Counter2ghz.get() {
	return now2ghz();
   }

  /** 
   * Return TRUE if an overflow event will occur after the outermost atomic
   * block is exits.  FALSE otherwise.
   * @return Counter pending overflow status.
   */
  async command bool Counter2ghz.isOverflowPending() {
  	return call Counter32khz.isOverflowPending();
  }

  /**
   * Cancel a pending overflow interrupt.
   */
  async command void Counter2ghz.clearOverflow() {
  	return call Counter32khz.clearOverflow();
  }

  /**
   * T2ghz timer overflows when T32khz timer does.
   */
  async event void Counter32khz.overflow() {
  	signal Counter2ghz.overflow();
  }

  async event void CounterMicro.overflow() {}
  default async event void Counter2ghz.overflow() {}


  /*------------------------- ALARM -------------------------*/
	
  /**
   * Set a single-short alarm to some time units in the future. Replaces
   * any current alarm time. Equivalent to start(getNow(), dt). The
   * <code>fired</code> will be signaled when the alarm expires.
   *
   * @param dt Time until the alarm fires.
   */
  async command void Alarm2ghz.start(uint32_t dt) {
   	uint16_t tMicro, t32khz;
	uint32_t t2ghz;
	
	// read all clocks
	now(&t32khz, &tMicro, &t2ghz);
	
	// stop running alarms
	call Alarm2ghz.stop();

	// absolute time of requested firing
	fireTime = t2ghz + dt;
	
	// if dt is close (less than 32 32khz ticks), set up Micro alarm
	if(dt < (1024ULL << 11)) {
		call AlarmMicro.startAt(tMicro, dt >> 11);
	} else {
		// set up 32khz alarm 8 ticks before it's time
		call Alarm32khz.startAt(t32khz, (dt >> 16) - 8);		
	}	
  }

  async event void Alarm32khz.fired() {
   	uint16_t tMicro, t32khz;
	uint32_t t2ghz, dt;
	
	// read all clocks
	now(&t32khz, &tMicro, &t2ghz);

	// compute time to firing
	dt = fireTime - t2ghz;
  	
	call AlarmMicro.startAt(tMicro, dt >> 11);
  }

  async event void AlarmMicro.fired() {
  	// signal Alarm2ghz.fired
	signal Alarm2ghz.fired();	
  }

  /**
   * Cancel an alarm. Note that the <code>fired</code> event may have
   * already been signaled (even if your code has not yet started
   * executing).
   */
  async command void Alarm2ghz.stop() {
	call Alarm32khz.stop();
	call AlarmMicro.stop();  	
  }

  default async event void Alarm2ghz.fired() {}

  /**
   * Check if alarm is running. Note that a FALSE return does not indicate
   * that the <code>fired</code> event will not be signaled (it may have
   * already started executing, but not reached your code yet).
   *
   * @return TRUE if the alarm is still running.
   */
  async command bool Alarm2ghz.isRunning() {
	return call Alarm32khz.isRunning()
		|| call AlarmMicro.isRunning();  	
  }

  /**
   * Set a single-short alarm to time t0+dt. Replaces any current alarm
   * time. The <code>fired</code> will be signaled when the alarm expires.
   * Alarms set in the past will fire "soon".
   * 
   * <p>Because the current time may wrap around, it is possible to use
   * values of t0 greater than the <code>getNow</code>'s result. These
   * values represent times in the past, i.e., the time at which getNow()
   * would last of returned that value.
   *
   * @param t0 Base time for alarm.
   * @param dt Alarm time as offset from t0.
   */
  async command void Alarm2ghz.startAt(uint32_t t0, uint32_t dt) {
   	uint16_t tMicro, t32khz;
	uint32_t t2ghz;
	
	// read all clocks
	now(&t32khz, &tMicro, &t2ghz);
	
	// stop running alarms
	call Alarm2ghz.stop();

	// absolute time of requested firing
	fireTime = t0 + dt;
	
	// time till requested firing
	dt = fireTime - t2ghz;

	// if dt is close (less than 32 32khz ticks), set up Micro alarm
	if(dt < (1024ULL << 11)) {
		call AlarmMicro.startAt(tMicro, dt >> 11);
	} else {
		// set up 32khz alarm 8 ticks before it's time
		call Alarm32khz.startAt(t32khz, (dt >> 16) - 8);		
	}	
  }

  /**
   * Return the current time.
   * @return Current time.
   */
  async command uint32_t Alarm2ghz.getNow(){
  	return now2ghz();
  }

  /**
   * Return the time the currently running alarm will fire or the time that
   * the previously running alarm was set to fire.
   * @return Alarm time.
   */
  async command uint32_t Alarm2ghz.getAlarm() {
  	return fireTime;
  }

  async command mcu_power_t McuPowerOverride.lowestState() {
  	if(call AlarmMicro.isRunning())
    		return MSP430_POWER_LPM0; // does LPM1 increase jitter???
	else
    		return MSP430_POWER_LPM3;
  }     
  
}

