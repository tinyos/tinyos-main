/*
 * Copyright (c) 2010, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
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