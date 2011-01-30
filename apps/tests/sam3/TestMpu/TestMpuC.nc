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
 * Basic application to test the MPU and the corresponding exception.
 *
 * @author Wanja Hofer <wanja@cs.fau.de>
 **/

// choose exactly one of the following
#define TEST_WRITE_PROTECTION
//#define TEST_EXECUTE_PROTECTION

// choose exactly one of the following
#define PROTECTED
//#define UNPROTECTED

/* Running either one of the write/execute tests *with* protection should first light up LED 0 (green),
 * then LED 2 (red) to indicate an MPU fault. LED 1 (green) should not light up,
 * since that would indicate a successful write/execution despite MPU protection.
 * Running either one of the write/execute tests *without* protection should first light up LED 0 (green),
 * then LED 1 (green) to indicate a successful write/execution. LED 2 (red) should not light up,
 * since that would indicate an MPU fault. */

/* Caveat: currently, the linker ignores the alignment for the function and spits out
 * warning: `aligned' attribute directive ignored
 * When setting up the region, the function address is aligned, and the first instruction of the function
 * will be protected, triggering the trap if protected. */

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

volatile struct32bytes __attribute__((aligned(32))) structure; // 32 bytes aligned

void  __attribute__((noinline)) __attribute__((aligned(32))) protected();

void protected()
{
	volatile int i = 0;
	for (; i < 50; i++);
}

module TestMpuC
{
	uses interface Leds;
	uses interface Boot;
	uses interface HplSam3uMpu;
}
implementation
{
	void fatal();

	event void Boot.booted()
	{
		// setup MPU
		call HplSam3uMpu.enableDefaultBackgroundRegion();
		call HplSam3uMpu.disableMpuDuringHardFaults();

		// first iteration should be successful, MPU not yet active
#ifdef TEST_WRITE_PROTECTION
		structure.word1 = 13;
#endif
#ifdef TEST_EXECUTE_PROTECTION
		protected();
#endif

		call Leds.led0On(); // LED 0: successful write/execute (should always happen)

#ifdef TEST_WRITE_PROTECTION
#ifdef PROTECTED
		// activate MPU and write-protect structure
		if ((call HplSam3uMpu.setupRegion(0, TRUE, (void *) &structure, 32, FALSE, TRUE, FALSE, TRUE, FALSE, TRUE, TRUE, 0)) == FAIL) {
			fatal();
		}
#endif
#endif
#ifdef TEST_EXECUTE_PROTECTION
#ifdef PROTECTED
		// activate MPU and execute-protect protected()
		if ((call HplSam3uMpu.setupRegion(0, TRUE, (void *) (((uint32_t) &protected) & (~ (32 - 1))), 32, FALSE, FALSE, FALSE, FALSE, FALSE, TRUE, TRUE, 0)) == FAIL) { // aligned
			fatal();
		}
#endif
#endif

#ifdef PROTECTED
		call HplSam3uMpu.enableMpu();
#endif

#ifdef TEST_WRITE_PROTECTION
		structure.word1 = 42;
#endif
#ifdef TEST_EXECUTE_PROTECTION
		protected();
#endif

		call Leds.led1On(); // LED 1: successful protected write/execute (should not happen if protected)

		while(1);
	}

	void fatal()
	{
		while(1) {
			volatile int i;
			for (i = 0; i < 100000; i++);
			call Leds.led2Toggle(); // Led 2 (red) blinking: fatal
		}
	}

	async event void HplSam3uMpu.mpuFault()
	{
		call Leds.led2On(); // LED 2 (red): MPU fault
		while(1);
	}
}
