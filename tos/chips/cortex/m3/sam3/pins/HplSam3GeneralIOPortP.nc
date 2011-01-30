/**
 * "Copyright (c) 2009 The Regents of the University of California.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
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
