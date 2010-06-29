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
 
#include <Msp430HybridAlarmCounter.h>

configuration Msp430HybridAlarmCounterC {
	provides {
		interface Counter<T2ghz,uint32_t> as Counter2ghz; 
		interface Alarm<T2ghz,uint32_t> as Alarm2ghz; 	
	}
}
implementation {
	components Msp430HybridAlarmCounterP
		,McuSleepC
		,Msp430CounterMicroC
		,Msp430Counter32khzC
		,new Alarm32khz16C()
		,new AlarmMicro16C()		
		;
		

	Msp430HybridAlarmCounterP.Counter32khz -> Msp430Counter32khzC;
	Msp430HybridAlarmCounterP.CounterMicro -> Msp430CounterMicroC;
	Msp430HybridAlarmCounterP.Alarm32khz -> Alarm32khz16C;
	Msp430HybridAlarmCounterP.AlarmMicro -> AlarmMicro16C;
	
  	Msp430HybridAlarmCounterP.McuPowerOverride <- McuSleepC; 	
	
	Msp430HybridAlarmCounterP.Counter2ghz = Counter2ghz;
	Msp430HybridAlarmCounterP.Alarm2ghz = Alarm2ghz;

}