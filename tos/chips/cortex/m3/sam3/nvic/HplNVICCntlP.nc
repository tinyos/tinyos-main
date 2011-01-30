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
