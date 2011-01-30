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
 * Generic module representing an NVIC interrupt.
 *
 * @author Thomas Schmid
 */

#include "nvichardware.h"

generic module HplNVICInterruptP (irqn_t irqn) @safe()
{
        provides
        {
            interface HplNVICInterruptCntl as Cntl;
        }
}

implementation
{

    async command void Cntl.configure(uint32_t priority){
        unsigned int priGroup = __NVIC_PRIO_BITS;
        unsigned int nPre = 8 - priGroup;
        unsigned int nSub = priGroup;
        unsigned int preemptionPriority;
        unsigned int subPriority;
        unsigned int IRQpriority;

        preemptionPriority = (priority & 0xff00) >> 8;
        subPriority = (priority & 0xff);

        // Disable the interrupt first
        call Cntl.disable();

        // Clear any pending status
        call Cntl.clearPending();

        if (subPriority >= (0x01 << nSub))
            subPriority = (0x01 << nSub) - 1;
        if (preemptionPriority >= (0x01 << nPre))
            preemptionPriority = (0x01 << nPre) - 1;

        IRQpriority = (subPriority | (preemptionPriority << nSub));
        call Cntl.setPriority(IRQpriority);
    }

    inline async command void Cntl.enable(){
        NVIC->iser0 = (1 << ((uint32_t)(irqn) & 0x1F));                             /* enable interrupt */
    }

    inline async command void Cntl.disable(){
        NVIC->icer0 = (1 << ((uint32_t)(irqn) & 0x1F));                             /* disable interrupt */
    }

    inline async command bool Cntl.isPending(){
        return((irqn_t) (NVIC->ispr0 & (1 << ((uint32_t)(irqn) & 0x1F))));         /* Return Interrupt bit or 'zero' */
    }

    inline async command void Cntl.setPending(){
        NVIC->ispr0 = (1 << ((uint32_t)(irqn) & 0x1F));                             /* set interrupt pending */
    }

    inline async command void Cntl.clearPending(){
        NVIC->icpr0 = (1 << ((uint32_t)(irqn) & 0x1F));
    }

    inline async command uint32_t Cntl.getActive(){
        return((irqn_t)(NVIC->iabr0 & (1 << ((uint32_t)(irqn) & 0x1F))));                        /* Return Interruptnumber or 'zero' */
    }

    inline async command void Cntl.setPriority(uint32_t priority){
        NVIC->ip[(uint32_t)(irqn)] = (priority & 0xff);
    }

    inline async command uint32_t Cntl.getPriority(){
        return((uint32_t)(NVIC->ip[(uint32_t)(irqn)] >> (8 - __NVIC_PRIO_BITS)));
    }

}
