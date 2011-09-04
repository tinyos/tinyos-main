/*
 * Copyright (c) 2010, University of Szeged
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
 * Author: Miklos Maroti
 */

#include "HplAtmRfa1Timer.h"

module HplAtmRfa1TimerMacP @safe()
{
	provides
	{
		interface AtmegaCounter<uint32_t> as Counter;
		interface AtmegaCompare<uint32_t> as CompareA;
		interface AtmegaCompare<uint32_t> as CompareB;
		interface AtmegaCompare<uint32_t> as CompareC;
		interface AtmegaCapture<uint32_t> as SfdCapture;
		interface McuPowerOverride;
	}

	uses
	{
		interface McuPowerState;
	}
}

implementation
{
	typedef union reg32_t
	{
		uint32_t full;
		struct 
		{
			uint8_t ll;
			uint8_t lh;
			uint8_t hl;
			uint8_t hh;
		};
	} reg32_t;

// ----- COUNTER: symbol counter register (SCCNT)

	async command uint32_t Counter.get()
	{
		reg32_t time;

		atomic
		{
			time.ll = SCCNTLL;
			time.lh = SCCNTLH;
			time.hl = SCCNTHL;
			time.hh	= SCCNTHH;
		}

		return time.full;
	}

	async command void Counter.set(uint32_t value)
	{
		reg32_t time;
		
		time.full = value;

		atomic
		{
			SCCNTHH = time.hh;
			SCCNTHL = time.hl;
			SCCNTLH = time.lh;
			SCCNTLL = time.ll;
		}

		while( SCSR & (1 << SCBSY) )
			;
	}

// ----- COUNTER: symbol counter interrupt status register (SCIRQS), overflow flag (IRQSOF)

	default async event void Counter.overflow() { }

	AVR_ATOMIC_HANDLER(SCNT_OVFL_vect) { signal Counter.overflow(); }

	async command bool Counter.test() { return SCIRQS & (1 << IRQSOF); }

	async command void Counter.reset() { SCIRQS = 1 << IRQSOF; }

// ----- COUNTER: symbol counter interrupt mask register (SCIRQM), overflow interrupt enable (IRQMOF)

	async command void Counter.start()
	{
		SET_BIT(SCIRQM, IRQMOF);
	}

	async command void Counter.stop()
	{
		CLR_BIT(SCIRQM, IRQMOF);
	}

	async command bool Counter.isOn() { return SCIRQM & (1 << IRQMOF); }

// ----- COUNTER: symbol counter control register (SCCR), counter enable (SCEN) and clock select (SCCKSEL)

	async command void Counter.setMode(uint8_t mode)
	{
		mode &= (1 << SCEN) | (1 << SCCKSEL);

		// RTC needs to be enabled, otherwise it does not work
		if( (mode & (1 << SCCKSEL)) != 0 )
			ASSR = 1 << AS2;

		atomic SCCR0 = (SCCR0 & ~((1 << SCEN) | (1 << SCCKSEL))) | mode;

		call McuPowerState.update();
	}

	async command uint8_t Counter.getMode()
	{
		return SCCR0 & ((1 << SCEN) | (1 << SCCKSEL));
	}


// ----- COMPARE A: symbol counter output compare register (SCOCR)

	async command uint32_t CompareA.get()
	{
		reg32_t time;

		atomic
		{
			time.ll = SCOCR1LL;
			time.lh = SCOCR1LH;
			time.hl = SCOCR1HL;
			time.hh	= SCOCR1HH;
		}

		return time.full;
	}

	async command void CompareA.set(uint32_t value)
	{
		reg32_t time;
		
		time.full = value;

		atomic
		{
			SCOCR1HH = time.hh;
			SCOCR1HL = time.hl;
			SCOCR1LH = time.lh;
			SCOCR1LL = time.ll;
		}
	}

// ----- COMPARE A: symbol counter interrupt status register (SCIRQS), comare match flag (IRQSCP)

	default async event void CompareA.fired() { }

	AVR_ATOMIC_HANDLER(SCNT_CMP1_vect) { signal CompareA.fired(); }

	async command bool CompareA.test() { return SCIRQS & (1 << IRQSCP1); }

	async command void CompareA.reset() { SCIRQS = 1 << IRQSCP1; }

// ----- COMPARE A: symbol counter interrupt mask register (SCIRQM), compare interrupt enable (IRQMCP)

	async command void CompareA.start()
	{
		SET_BIT(SCIRQM, IRQMCP1);

		call McuPowerState.update();
	}

	async command void CompareA.stop()
	{
		CLR_BIT(SCIRQM, IRQMCP1);

		call McuPowerState.update();
	}

	async command bool CompareA.isOn() { return SCIRQM & (1 << IRQMCP1); }

// ----- COMPARE A: symbol counter control register (SCCR), compare mode (SCCMP)

	async command void CompareA.setMode(uint8_t mode)
	{
		atomic
		{
			SCCR0 = (SCCR0 & ~(1 << SCCMP1)) 
				| (mode & 0x1) << SCCMP1;
		}
	}

	async command uint8_t CompareA.getMode()
	{
		return (SCCR0 >> SCCMP1) & 0x1;
	}

// ----- COMPARE A: ignore force for the symbol counter

	async command void CompareA.force() { }

// ----- COMPARE B: symbol counter output compare register (SCOCR)

	async command uint32_t CompareB.get()
	{
		reg32_t time;

		atomic
		{
			time.ll = SCOCR2LL;
			time.lh = SCOCR2LH;
			time.hl = SCOCR2HL;
			time.hh	= SCOCR2HH;
		}

		return time.full;
	}

	async command void CompareB.set(uint32_t value)
	{
		reg32_t time;
		
		time.full = value;

		atomic
		{
			SCOCR2HH = time.hh;
			SCOCR2HL = time.hl;
			SCOCR2LH = time.lh;
			SCOCR2LL = time.ll;
		}
	}

// ----- COMPARE B: symbol counter interrupt status register (SCIRQS), comare match flag (IRQSCP)

	default async event void CompareB.fired() { }

	AVR_ATOMIC_HANDLER(SCNT_CMP2_vect) { signal CompareB.fired(); }

	async command bool CompareB.test() { return SCIRQS & (1 << IRQSCP2); }

	async command void CompareB.reset() { SCIRQS = 1 << IRQSCP2; }

// ----- COMPARE B: symbol counter interrupt mask register (SCIRQM), compare interrupt enable (IRQMCP)

	async command void CompareB.start()
	{
		SET_BIT(SCIRQM, IRQMCP2);

		call McuPowerState.update();
	}

	async command void CompareB.stop()
	{
		CLR_BIT(SCIRQM, IRQMCP2);

		call McuPowerState.update();
	}

	async command bool CompareB.isOn() { return SCIRQM & (1 << IRQMCP2); }

// ----- COMPARE B: symbol counter control register (SCCR), compare mode (SCCMP)

	async command void CompareB.setMode(uint8_t mode)
	{
		atomic
		{
			SCCR0 = (SCCR0 & ~(1 << SCCMP2)) 
				| (mode & 0x1) << SCCMP2;
		}
	}

	async command uint8_t CompareB.getMode()
	{
		return (SCCR0 >> SCCMP2) & 0x1;
	}

// ----- COMPARE B: ignore force for the symbol counter

	async command void CompareB.force() { }

// ----- COMPARE C: symbol counter output compare register (SCOCR)

	async command uint32_t CompareC.get()
	{
		reg32_t time;

		atomic
		{
			time.ll = SCOCR3LL;
			time.lh = SCOCR3LH;
			time.hl = SCOCR3HL;
			time.hh	= SCOCR3HH;
		}

		return time.full;
	}

	async command void CompareC.set(uint32_t value)
	{
		reg32_t time;
		
		time.full = value;

		atomic
		{
			SCOCR3HH = time.hh;
			SCOCR3HL = time.hl;
			SCOCR3LH = time.lh;
			SCOCR3LL = time.ll;
		}
	}

// ----- COMPARE C: symbol counter interrupt status register (SCIRQS), comare match flag (IRQSCP)

	default async event void CompareC.fired() { }

	AVR_ATOMIC_HANDLER(SCNT_CMP3_vect) { signal CompareC.fired(); }

	async command bool CompareC.test() { return SCIRQS & (1 << IRQSCP3); }

	async command void CompareC.reset() { SCIRQS = 1 << IRQSCP3; }

// ----- COMPARE C: symbol counter interrupt mask register (SCIRQM), compare interrupt enable (IRQMCP)

	async command void CompareC.start()
	{
		SET_BIT(SCIRQM, IRQMCP3);

		call McuPowerState.update();
	}

	async command void CompareC.stop()
	{
		CLR_BIT(SCIRQM, IRQMCP3);

		call McuPowerState.update();
	}

	async command bool CompareC.isOn() { return SCIRQM & (1 << IRQMCP3); }

// ----- COMPARE C: symbol counter control register (SCCR), compare mode (SCCMP)

	async command void CompareC.setMode(uint8_t mode)
	{
		atomic
		{
			SCCR0 = (SCCR0 & ~(1 << SCCMP3)) 
				| (mode & 0x1) << SCCMP3;
		}
	}

	async command uint8_t CompareC.getMode()
	{
		return (SCCR0 >> SCCMP3) & 0x1;
	}

// ----- COMPARE C: ignore force for the symbol counter

	async command void CompareC.force() { }

// ----- SFD CAPTURE: symbol counter time stamp register (SCTSR)

	async command uint32_t SfdCapture.get()
	{
		reg32_t time;

		atomic
		{
			time.ll = SCTSRLL;
			time.lh = SCTSRLH;
			time.hl = SCTSRHL;
			time.hh	= SCTSRHH;
		}

		return time.full;
	}

	async command void SfdCapture.set(uint32_t value) 
	{ 
		// SCTSR is read only
	}

// ----- SFD CAPTURE: has no interrupt (use RX_START instead)

	async command bool SfdCapture.test() { return FALSE; }
	async command void SfdCapture.reset() { }
	async command void SfdCapture.start() { }
	async command void SfdCapture.stop() { }
	async command bool SfdCapture.isOn() { return FALSE; }

// ----- SFD CAPTURE: symbol counter control register (SCCR), timestamping enable (SCTES)

	async command void SfdCapture.setMode(uint8_t mode)
	{
		atomic
		{
			SCCR0 = (SCCR0 & ~(1 << SCTSE))
				| (mode & 0x1) << SCTSE;
		}
	}

	async command uint8_t SfdCapture.getMode()
	{
		return (SCCR0 >> SCTSE) & 0x1;
	}

// ----- MCUPOWER

	async command mcu_power_t McuPowerOverride.lowestState()
	{
		// TODO: check out why ATM128_POWER_DOWN does not work

		if( SCCR0 & (1 << SCEN) )
			return ATM128_POWER_SAVE;
		else
			return ATM128_POWER_DOWN;
	}
}
