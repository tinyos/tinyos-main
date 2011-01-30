/**
 * "Copyright (c) 2009 The Regents of the University of California.
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
 * - Neither the name of the copyright holders nor the names of its
 *   contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
 * AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 * WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * @author Thomas Schmid
 */

uint32_t clocks = 0;
generic module HplSam3GeneralIOPortP(uint32_t pio_addr)
{
    provides
    {
        interface HplSam3GeneralIOPort as Bits [uint8_t bit];
    }
    uses
    {
        interface HplSam3GeneralIOPort as HplPort;
        interface HplNVICInterruptCntl as PIOIrqControl;
        interface HplSam3PeripheralClockCntl as PIOClockControl;
    }
}
implementation
{
    uint32_t isr = 0;

    bool isPending(uint8_t bit)
    {
        uint32_t currentpin;
        // make sure to not loose state for other bits!
        atomic
        {
            isr |= *((volatile uint32_t *) (pio_addr + 0x04C));
            currentpin = (isr & (1 << bit)) >> bit;
            // remove bit
            isr &= ~( 1 << bit);
        }
        return ((currentpin & 1) == 1);
    }

    async event void HplPort.fired(uint32_t time)
    {
        uint8_t i;
        uint32_t isrMasked;

        atomic
        {
            // make sure to not loose state for other bits!
            isr |= *((volatile uint32_t *) (pio_addr + 0x04C));

            // only look at pins where the interrupt is enabled
            isrMasked = isr & *((volatile uint32_t *) (pio_addr + 0x048));

            // find out which port
            for(i=0; i<32; i++){
                if(isrMasked & (1 << i))
                {
                    signal Bits.fired[i](time);
                }
            } 
            // remove signaled bits from isr
            isr &= ~isrMasked;
        }
    }

    async command void Bits.enableInterrupt[uint8_t bit]()
    {
        // Enable the PIO clock if not already enabled (state checked internally)
        call Bits.enableClock[bit]();
        // check if the NVIC is already enabled
        if(call PIOIrqControl.getActive() == 0)
        {
            call PIOIrqControl.configure(IRQ_PRIO_PIO);
            call PIOIrqControl.enable();
        }
    }

    async command void Bits.disableInterrupt[uint8_t bit]()
    {
        // Disable the PIO clock if no one else needs it (state checked internally)
        call Bits.disableClock[bit]();
        // if all the interrupts are disabled, disable the NVIC.
        if(*((volatile uint32_t *) (pio_addr + 0x048)) == 0)
        {
            call PIOIrqControl.disable();
        }
    }

    async command void Bits.enableClock[uint8_t bit]()
    {
        atomic 
        {
            // only enable the peripheral clock if no one else has enabled it.
            if(!clocks)
              call PIOClockControl.enable();
            clocks |= (1<<bit);
        }
    }

    async command void Bits.disableClock[uint8_t bit]()
    {
        atomic
        {
            clocks &= ~(1<<bit);
            // only disable the peripheral clock if no one else uses it.
            if(!clocks)
                call PIOClockControl.disable();
        }
    }

    default async event void Bits.fired[uint8_t bit](uint32_t time) {}
}
