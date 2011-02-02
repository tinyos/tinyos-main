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
 * Pin abstraction on the SAM3.
 *
 * @author Wanja Hofer <wanja@cs.fau.de>
 */

generic module HplSam3GeneralIOPinP(uint32_t pio_addr, uint8_t bit)
{
	provides
	{
		interface GeneralIO as IO;
        interface GpioInterrupt as Interrupt;
        interface GpioCapture as Capture;
		interface HplSam3GeneralIOPin as HplPin;
	}
    uses
    {
        interface HplSam3GeneralIOPort as HplPort;
    }
}
implementation
{
	async command bool IO.get()
	{
		if ((call IO.isInput()) == 1) {
			/* Read bit from Pin Data Status Register */
			uint32_t currentport = *((volatile uint32_t *) (pio_addr + 0x03c));
			uint32_t currentpin = (currentport & (1 << bit)) >> bit;
			return ((currentpin & 1) == 1);
		} else {
			/* Read bit from Output Data Status Register */
			uint32_t currentport = *((volatile uint32_t *) (pio_addr + 0x038));
			uint32_t currentpin = (currentport & (1 << bit)) >> bit;
			return ((currentpin & 1) == 1);
		}
	}

	async command void IO.set()
	{
		/* Set bit in Set Output Data Register */
		*((volatile uint32_t *) (pio_addr + 0x030)) = (1 << bit);
	}

	async command void IO.clr()
	{
		/* Set bit in Clear Output Data Register */
		*((volatile uint32_t *) (pio_addr + 0x034)) = (1 << bit);
	}

	async command void IO.toggle()
	{
		if ((call IO.get()) == 1) {
			call IO.clr();
		} else {
			call IO.set();
		}
	}

	async command void IO.makeInput()
	{
		/* Set bit in Output Disable Register */
		*((volatile uint32_t *) (pio_addr + 0x014)) = (1 << bit);

        call HplPort.enableClock();
    }

	async command void IO.makeOutput()
	{
		/* Set bit in Output Enable Register */
		*((volatile uint32_t *) (pio_addr + 0x010)) = (1 << bit);

        // we don't need the clock in output mode
        call HplPort.disableClock();
    }

	async command bool IO.isOutput()
	{
		/* Read bit from Output Status Register */
		uint32_t currentport = *((volatile uint32_t *) (pio_addr + 0x018));
		uint32_t currentpin = (currentport & (1 << bit)) >> bit;
		return ((currentpin & 1) == 1);
	}

	async command bool IO.isInput()
	{
		return (! (call IO.isOutput()));
	}

	async command void HplPin.enablePioControl()
	{
		/* Set bit in PIO Enable Register */
		*((volatile uint32_t *) (pio_addr + 0x000)) = (1 << bit);
	}

	async command void HplPin.disablePioControl()
	{
		/* Set bit in PIO Disable Register */
		*((volatile uint32_t *) (pio_addr + 0x004)) = (1 << bit);
	}

	async command bool HplPin.isEnabledPioControl()
	{
		/* Read bit from PIO Status Register */
		uint32_t currentport = *((volatile uint32_t *) (pio_addr + 0x008));
		uint32_t currentpin = (currentport & (1 << bit)) >> bit;
		return ((currentpin & 1) == 1);
	}

	async command void HplPin.enableMultiDrive()
	{
		/* Set bit in Multi-Driver Enable Register */
		*((volatile uint32_t *) (pio_addr + 0x050)) = (1 << bit);
	}

	async command void HplPin.disableMultiDrive()
	{
		/* Set bit in Multi-Driver Disable Register */
		*((volatile uint32_t *) (pio_addr + 0x054)) = (1 << bit);
	}

	async command bool HplPin.isEnabledMultiDrive()
	{
		/* Read bit from Multi-Driver Status Register */
		uint32_t currentport = *((volatile uint32_t *) (pio_addr + 0x058));
		uint32_t currentpin = (currentport & (1 << bit)) >> bit;
		return ((currentpin & 1) == 1);
	}

	async command void HplPin.enablePullUpResistor()
	{
		/* Set bit in Pull-Up Enable Register */
		*((volatile uint32_t *) (pio_addr + 0x064)) = (1 << bit);
	}

	async command void HplPin.disablePullUpResistor()
	{
		/* Set bit in Pull-Up Disable Register */
		*((volatile uint32_t *) (pio_addr + 0x060)) = (1 << bit);
	}

	async command bool HplPin.isEnabledPullUpResistor()
	{
		/* Read bit from Pull-Up Status Register */
		uint32_t currentport = *((volatile uint32_t *) (pio_addr + 0x068));
		uint32_t currentpin = (currentport & (1 << bit)) >> bit;
		return ((currentpin & 1) == 0);
	}

	async command void HplPin.selectPeripheralA()
	{
		/* Read in Peripheral AB Select Register */
		uint32_t currentport = *((volatile uint32_t *) (pio_addr + 0x070));
		/* Clear bit */
		currentport &= ~ (1 << bit);
		/* Write back to register */
		*((volatile uint32_t *) (pio_addr + 0x070)) = currentport;
#ifdef CHIP_SAM3_HAS_PERIPHERAL_CD
		currentport = *((volatile uint32_t *) (pio_addr + 0x074));
		currentport &= ~ (1 << bit);
		*((volatile uint32_t *) (pio_addr + 0x074)) = currentport;
#endif
	}

	async command void HplPin.selectPeripheralB()
	{
		/* Read in Peripheral AB Select Register */
		uint32_t currentport = *((volatile uint32_t *) (pio_addr + 0x070));
		/* Set bit */
		currentport |= (1 << bit);
		/* Write back to register */
		*((volatile uint32_t *) (pio_addr + 0x070)) = currentport;
#ifdef CHIP_SAM3_HAS_PERIPHERAL_CD
		currentport = *((volatile uint32_t *) (pio_addr + 0x074));
		/* clear bit */
		currentport &= ~(1 << bit);
		/* Write back to register */
		*((volatile uint32_t *) (pio_addr + 0x074)) = currentport;
#endif
	}

#ifdef CHIP_SAM3_HAS_PERIPHERAL_CD
	async command void HplPin.selectPeripheralC()
	{
		/* Read in Peripheral AB Select Register */
		uint32_t currentport = *((volatile uint32_t *) (pio_addr + 0x070));
		/* clear bit */
		currentport &= ~(1 << bit);
		/* Write back to register */
		*((volatile uint32_t *) (pio_addr + 0x070)) = currentport;
		currentport = *((volatile uint32_t *) (pio_addr + 0x074));
		/* set bit */
		currentport |= (1 << bit);
		/* Write back to register */
		*((volatile uint32_t *) (pio_addr + 0x074)) = currentport;
	}

	async command void HplPin.selectPeripheralD()
	{
		/* Read in Peripheral AB Select Register */
		uint32_t currentport = *((volatile uint32_t *) (pio_addr + 0x070));
		/* set bit */
		currentport |= (1 << bit);
		/* Write back to register */
		*((volatile uint32_t *) (pio_addr + 0x070)) = currentport;
		currentport = *((volatile uint32_t *) (pio_addr + 0x074));
		/* set bit */
		currentport |= (1 << bit);
		/* Write back to register */
		*((volatile uint32_t *) (pio_addr + 0x074)) = currentport;
	}
#endif

	async command bool HplPin.isSelectedPeripheralA()
	{
		/* Read bit from Peripheral AB Select Register */
		uint32_t currentport = *((volatile uint32_t *) (pio_addr + 0x070));
		uint32_t currentpin = (currentport & (1 << bit)) >> bit;
#ifdef CHIP_SAM3_HAS_PERIPHERAL_CD
		uint32_t currentport2 = *((volatile uint32_t *) (pio_addr + 0x074));
        uint32_t currentpin2 = (currentport2 & (1 << bit)) >> bit;
        return (((currentpin & 1) == 0) && (currentpin2 & 1) == 0);
#else
		return ((currentpin & 1) == 0);
#endif
	}

    // interrupt
    async command void HplPin.enableInterrupt()
    {
        *((volatile uint32_t *) (pio_addr + 0x040)) = 1 << bit;
        call HplPort.enableInterrupt();
    }
    async command void HplPin.disableInterrupt()
    {
        *((volatile uint32_t *) (pio_addr + 0x044)) = 1 << bit;
        call HplPort.disableInterrupt();
    }
    async command bool HplPin.isEnabledInterrupt()
    {
		uint32_t currentport = *((volatile uint32_t *) (pio_addr + 0x048));
        uint32_t currentpin = (currentport & (1 << bit)) >> bit;
        return ((currentpin & 1) == 1);
    }

    // edge selection
    async command void HplPin.enableEdgeDetection()
    {
        *((volatile uint32_t *) (pio_addr + 0x0C0)) = 1 << bit;
        // for precaution, reset additional interrupt modes register
        // so that we can do just edge detection (rising and falling)
        *((volatile uint32_t *) (pio_addr + 0x0B4)) = 1 << bit;

    }
    async command bool HplPin.isEnabledEdgeDetection()
    {
		uint32_t currentport = *((volatile uint32_t *) (pio_addr + 0x0C8));
        uint32_t currentpin = (currentport & (1 << bit)) >> bit;
        return ((currentpin & 1) == 0);
    }
    async command void HplPin.fallingEdgeDetection()
    {
        // set the bit in falling edge register
        *((volatile uint32_t *) (pio_addr + 0x0D0)) = 1 << bit;
        // enable additional interrupt modes
        *((volatile uint32_t *) (pio_addr + 0x0B0)) = 1 << bit;
    }
    async command bool HplPin.isFallingEdgeDetection()
    {
		uint32_t currentport = *((volatile uint32_t *) (pio_addr + 0x0D8));
        uint32_t currentpin = (currentport & (1 << bit)) >> bit;
        return ((currentpin & 1) == 0);
    }
    async command void HplPin.risingEdgeDetection()
    {
        // set the bit in the rising edge detection
		*((volatile uint32_t *) (pio_addr + 0x0D4)) = 1 << bit;
        // enable additional interrupt modes
        *((volatile uint32_t *) (pio_addr + 0x0B0)) = 1 << bit;
    }

    async event void HplPort.fired(uint32_t time)
    {
        signal Interrupt.fired();
        signal Capture.captured((uint16_t)time);
    }

    async command error_t Interrupt.disable()
    {
        call HplPin.disableInterrupt();
        return SUCCESS;
    }
    async command error_t Interrupt.enableFallingEdge()
    {
        call HplPin.enablePioControl();
        call HplPin.enableEdgeDetection();
        call HplPin.fallingEdgeDetection();
        call HplPin.enableInterrupt();
        return SUCCESS;
    }
    async command error_t Interrupt.enableRisingEdge()
    {
        call HplPin.enablePioControl();
        call HplPin.enableEdgeDetection();
        call HplPin.risingEdgeDetection();
        call HplPin.enableInterrupt();
        return SUCCESS;
    }

    async command error_t Capture.captureRisingEdge()
    {
        return call Interrupt.enableRisingEdge();
    }
    async command error_t Capture.captureFallingEdge()
    {
        return call Interrupt.enableFallingEdge();
    }
    async command void Capture.disable()
    {
        call Interrupt.disable();
    }

    default async event void Interrupt.fired() {}
    default async event void Capture.captured(uint16_t time) {}
}

