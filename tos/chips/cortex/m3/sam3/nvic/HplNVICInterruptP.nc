/**
 * Copyright (c) 2009 The Regents of the University of California.
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
