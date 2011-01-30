/*
 * Copyright (c) 2009 Stanford University.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Stanford University nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL STANFORD
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * Basic application to test thread isolation.
 *
 * @author Wanja Hofer <wanja@cs.fau.de>
 **/

// Depending on if MPU protection is enabled or not, thread 1 will be able to
// write to thread 0's data or not, and, therefore, after LED 0 lights up, either
// LED 1 should light up (not protected) or LED 2 (red) should light up (protected)

typedef struct
{
	uint32_t word1;
	uint32_t word2;
	uint32_t word3;
	uint32_t word4;
	uint32_t word5;
	uint32_t word6;
	uint32_t word7;
	uint32_t word8;
} struct32bytes;

module TestMpuProtectionC
{
	uses interface Leds;
	uses interface Boot;
	uses interface Thread as Thread0;
	uses interface Thread as Thread1;
}
implementation
{
	// does not normally have to be volatile, but here it does
	// so that the compiler does not optimize the artificial check
	// for manipulation in the test case
	volatile struct32bytes data0 __attribute__((section(".bssthread0"))); // belongs to thread 0

	volatile struct32bytes data1 __attribute__((section(".bssthread1"))); // belongs to thread 1

	void fatal();

	void wait() {
		volatile unsigned int i; 
		for (i = 0; i < 1000000; i++);
	}  

	event void Boot.booted()
	{
		call Thread0.start(NULL);
		call Thread1.start(NULL);
	}

	event void Thread0.run(void* arg)
	{
		// initialize own data
		data0.word1 = 1;
		data0.word2 = 1;
		data0.word3 = 1;
		data0.word4 = 1;
		data0.word5 = 1;
		data0.word6 = 1;
		data0.word7 = 1;
		data0.word8 = 1;

		// check if data has been manipulated
		while (1) {
			if (data0.word1 != 1) {
				call Leds.led1On(); // LED 1 (green): data has been manipulated
			}
		}
	}

	event void Thread1.run(void* arg)
	{
		volatile uint32_t i;

		for (i = 0; i < 4; i++) {
			// wait for some time
			wait();
		}

		// then manipulate foreign data
		call Leds.led0On(); // LED 0 (green): manipulation attempt about to happen
		data0.word1 = 2;

		while (1); // wait forever
	}

	void fatal()
	{
		while (1) {
			volatile int i;
			for (i = 0; i < 100000; i++);
			call Leds.led2Toggle(); // Led 2 (red) blinking: fatal
		}
	}
}
