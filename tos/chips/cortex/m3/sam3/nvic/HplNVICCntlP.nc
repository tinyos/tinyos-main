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
 * NVIC Controller
 *
 * @author Thomas Schmid
 * @author Wanja Hofer <wanja@cs.fau.de>
 */

#include "nvichardware.h"

module HplNVICCntlP
{
    provides interface HplNVICCntl;
    provides interface Init;
}

implementation{
    command void HplNVICCntl.setPriorityGrouping(uint32_t priority_grouping)
    {
        uint32_t reg_value=0;

        reg_value  = SCB->AIRCR;                                                                            /* read old register configuration    */
        reg_value &= ~((0xFFFFU << 16) | (0x0F << 8));                                                      /* clear bits to change               */
        reg_value  = ((reg_value | NVIC_AIRCR_VECTKEY | (priority_grouping << 8)));                         /* Insert write key and priorty group */
        SCB->AIRCR = reg_value;
    }

	async command void HplNVICCntl.enableUsageFault()
	{
		SCB->SHCSR.bits.usgfaultena = 1;
	}

	async command void HplNVICCntl.disableUsageFault()
	{
		SCB->SHCSR.bits.usgfaultena = 0;
	}

	async command void HplNVICCntl.enableBusFault()
	{
		SCB->SHCSR.bits.busfaultena = 1;
	}

	async command void HplNVICCntl.disableBusFault()
	{
		SCB->SHCSR.bits.busfaultena = 0;
	}

	async command void HplNVICCntl.enableMemoryProtectionFault()
	{
		SCB->SHCSR.bits.memfaultena = 1;
	}

	async command void HplNVICCntl.disableMemoryProtectionFault()
	{
		SCB->SHCSR.bits.memfaultena = 0;
	}


	async command bool HplNVICCntl.isSVCallPended()
	{
		return (SCB->SHCSR.bits.svcallpended == 0x1);
	}

	async command bool HplNVICCntl.isUsageFaultPended()
	{
		return (SCB->SHCSR.bits.usgfaultpended == 0x1);
	}

	async command bool HplNVICCntl.isBusFaultPended()
	{
		return (SCB->SHCSR.bits.busfaultpended == 0x1);
	}

	async command bool HplNVICCntl.isMemoryProtectionFaultPended()
	{
		return (SCB->SHCSR.bits.memfaultpended == 0x1);
	}


	async command bool HplNVICCntl.isSysTickActive()
	{
		return (SCB->SHCSR.bits.systickact == 0x1);
	}

	async command bool HplNVICCntl.isPendSVActive()
	{
		return (SCB->SHCSR.bits.pendsvact == 0x1);
	}

	async command bool HplNVICCntl.isMonitorActive()
	{
		return (SCB->SHCSR.bits.monitoract == 0x1);
	}

	async command bool HplNVICCntl.isSVCallActive()
	{
		return (SCB->SHCSR.bits.svcallact == 0x1);
	}

	async command bool HplNVICCntl.isUsageFaultActive()
	{
		return (SCB->SHCSR.bits.usgfaultact == 0x1);
	}

	async command bool HplNVICCntl.isBusFaultActive()
	{
		return (SCB->SHCSR.bits.busfaultact == 0x1);
	}

	async command bool HplNVICCntl.isMemoryProtectionFaultActive()
	{
		return (SCB->SHCSR.bits.memfaultact == 0x1);
	}

	command void HplNVICCntl.setSVCallPrio(uint8_t prio)
	{
		(SCB->SHP)[7] = prio;
	}

	command void HplNVICCntl.setPendSVPrio(uint8_t prio)
	{
		(SCB->SHP)[10] = prio;
	}

	command error_t Init.init()
	{
		// both SVCall and PendSV have the same, lowest prio in the system
		call HplNVICCntl.setSVCallPrio(0xff);
		call HplNVICCntl.setPendSVPrio(0xff);

		return SUCCESS;
	}
}
