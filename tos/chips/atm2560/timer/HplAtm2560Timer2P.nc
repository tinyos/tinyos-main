/*
 * Copyright (c) 2004-2005 Crossbow Technology, Inc.  All rights reserved.
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
 */

/*
 * Copyright (c) 2007, Vanderbilt University
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
 */

/**
 * HPL interface to Atmega2560 timer 2 in ASYNC mode. This is a specialised
 * HPL component that assumes that timer 2 is used in ASYNC mode and
 * includes some workarounds for some of the weirdnesses (delayed overflow
 * interrupt) of that mode.
 *
 * @author Martin Turon <mturon@xbow.com>
 * @author David Gay <dgay@intel-research.net>
 * @author Janos Sallai <janos.sallai@vanderbilt.edu>
 */

#include <Atm128Timer.h>

module HplAtm2560Timer2P @safe() {
	provides {
		// 8-bit Timers
		interface HplAtm128Timer<uint8_t>   as Timer;
		interface HplAtm128TimerCtrl8       as TimerCtrl;
		interface HplAtm128Compare<uint8_t> as Compare;
		interface McuPowerOverride;
	}
}

implementation {
//  bool inOverflow;

//	command error_t Init.init() {
//		SET_BIT(ASSR, AS2);  // set Timer/Counter2 to asynchronous mode
//		return SUCCESS;
//	}

	//=== Read the current timer value. ===================================
	async command uint8_t  Timer.get() { return TCNT2; }

	//=== Set/clear the current timer value. ==============================
	async command void Timer.set(uint8_t t)  {
		while (ASSR & 1 << TCN2UB)
			;
		TCNT2 = t;
	}

	//=== Read the current timer scale. ===================================
	async command uint8_t Timer.getScale() { return TCCR2B & 0x7; }

	//=== Turn off the timers. ============================================
	async command void Timer.off() { call Timer.setScale(AVR_CLOCK_OFF); }

	//=== Write a new timer scale. ========================================
	async command void Timer.setScale(uint8_t s)  {
		Atm128_TCCR2B_t x = (Atm128_TCCR2B_t) call TimerCtrl.getControlB();
		x.bits.cs = s;
		call TimerCtrl.setControlB(x.flat);
	}

	//=== Read the control registers. =====================================
	async command uint8_t TimerCtrl.getControlA() {
		return TCCR2A;
	}

	async command uint8_t TimerCtrl.getControlB() {
		return TCCR2B;
	}

	//=== Write the control registers. ====================================
	async command void TimerCtrl.setControlA( uint8_t x ) {
		while (ASSR & 1 << TCR2AUB)
			;
		TCCR2A = ((Atm128_TCCR2A_t)x).flat;
	}

	async command void TimerCtrl.setControlB( uint8_t x ) {
		while (ASSR & 1 << TCR2BUB)
			;
		TCCR2B = ((Atm128_TCCR2B_t)x).flat;
	}

	//=== Read the interrupt mask. =====================================
	async command uint8_t TimerCtrl.getInterruptMask() {
		return TIMSK2;
	}

	//=== Write the interrupt mask. ====================================
	async command void TimerCtrl.setInterruptMask( uint8_t x ) {
		TIMSK2 = x;
	}

	//=== Read the interrupt flags. =====================================
	async command uint8_t TimerCtrl.getInterruptFlag() {
		return TIFR2;
	}

	//=== Write the interrupt flags. ====================================
	async command void TimerCtrl.setInterruptFlag( uint8_t x ) {
		TIFR2 = x;
	}

	//=== Timer 8-bit implementation. ====================================
	async command void Timer.reset() { TIFR2 = 1 << TOV2; }
	async command void Timer.start() { SET_BIT(TIMSK2, TOIE2); }
	async command void Timer.stop()  { CLR_BIT(TIMSK2, TOIE2); }

	bool overflowed() {
		return ((Atm128_TIFR2_t)call TimerCtrl.getInterruptFlag()).bits.tov;
	}

	async command bool Timer.test()  {
		return overflowed();
	}

	async command bool Timer.isOn()  {
		return ((Atm128_TIMSK2_t)call TimerCtrl.getInterruptMask()).bits.toie;
	}

	async command void Compare.reset() { TIFR2 = 1 << OCF2A; }
	async command void Compare.start() { SET_BIT(TIMSK2,OCIE2A); }
	async command void Compare.stop()  { CLR_BIT(TIMSK2,OCIE2A); }
	async command bool Compare.test()  {
		return ((Atm128_TIFR2_t)call TimerCtrl.getInterruptFlag()).bits.ocfa;
	}
	async command bool Compare.isOn()  {
		return ((Atm128_TIMSK2_t)call TimerCtrl.getInterruptMask()).bits.ociea;
	}

	//=== Read the compare registers. =====================================
	async command uint8_t Compare.get(){ return OCR2A; }

	//=== Write the compare registers. ====================================
	async command void Compare.set(uint8_t t)   {
		atomic
		{
			while (ASSR & 1 << OCR2AUB)
				;
			OCR2A = t;
		}
	}

	//=== Timer interrupts signals ========================================
	inline void stabiliseTimer2() {
		TCCR2A = TCCR2A;
		while (ASSR & 1 << TCR2AUB)
			;
	}

	/**
	 * On the atm128, there is a small latency when waking up from
	 * POWER_SAVE mode. So if a timer is going to go off very soon, it's
	 * better to drop down until EXT_STANDBY, which has a 6 cycle wakeup
	 * latency. This function calculates whether staying in EXT_STANDBY
	 * is needed. If the timer is not running it returns POWER_DOWN.
	 * Please refer to TEP 112 and the atm128 datasheet for details.
	 */

	async command mcu_power_t McuPowerOverride.lowestState() {
		uint8_t diff;

		// We need to make sure that the sleep wakeup latency will not
		// cause us to miss a timer. POWER_SAVE
		if (TIMSK2 & (1 << OCIE2A | 1 << TOIE2)) {
			// need to wait for timer 2 updates propagate before sleeping
			// (we don't need to worry about reentering sleep mode too early,
			// as the wake ups from timer2 wait at least one TOSC1 cycle
			// anyway - see the stabiliseTimer2 function)
			while (ASSR & (1 << TCN2UB | 1 << OCR2AUB | 1 << TCR2AUB))
				;

			diff = OCR2A - TCNT2;
			if (diff < EXT_STANDBY_T0_THRESHOLD || TCNT2 > 256 - EXT_STANDBY_T0_THRESHOLD) {
				return ATM128_POWER_EXT_STANDBY;
			}

			return ATM128_POWER_SAVE;
		} else {
			return ATM128_POWER_DOWN;
		}
	}

	default async event void Compare.fired() { }
		AVR_ATOMIC_HANDLER(SIG_OUTPUT_COMPARE2A) {
		stabiliseTimer2();
		//    __nesc_enable_interrupt();

		signal Compare.fired();
	}

	default async event void Timer.overflow() { }
		AVR_ATOMIC_HANDLER(SIG_OVERFLOW2) {
		stabiliseTimer2();
		//    inOverflow = TRUE;
		signal Timer.overflow();
		//    inOverflow = FALSE;
	}
}

