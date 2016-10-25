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
 * @author wanja@cs.fau.de
 */

#include "sam3umpuhardware.h"

module HplSam3uMpuP
{
	provides interface HplSam3uMpu;
	provides interface HplSam3uMpuStatus;
	provides interface Init;
	uses interface HplNVICCntl;
        uses interface McuSleep;
}
implementation
{
	command error_t Init.init()
	{
		call HplNVICCntl.enableMemoryProtectionFault();
		return SUCCESS;
	}

	async command void HplSam3uMpu.enableMpu()
	{
		MPU_CTRL->bits.enable = 1;
	}

	async command void HplSam3uMpu.disableMpu()
	{
		MPU_CTRL->bits.enable = 0;
	}

	async command void HplSam3uMpu.enableMpuDuringHardFaults()
	{
		MPU_CTRL->bits.hfnmiena = 1;
	}

	async command void HplSam3uMpu.disableMpuDuringHardFaults()
	{
		MPU_CTRL->bits.hfnmiena = 0;
	}

	async command void HplSam3uMpu.enableDefaultBackgroundRegion()
	{
		MPU_CTRL->bits.privdefena = 1;
	}

	async command void HplSam3uMpu.disableDefaultBackgroundRegion()
	{
		MPU_CTRL->bits.privdefena = 0;
	}

	async command void HplSam3uMpu.deployRegion(mpu_rbar_t rbar, mpu_rasr_t rasr)
	{
		// write registers
		*MPU_RBAR = rbar;
		*MPU_RASR = rasr;
	}

	__attribute__((interrupt)) void MpuFaultHandler() @C() @spontaneous()
	{
		call McuSleep.irq_preamble();
		signal HplSam3uMpu.mpuFault();
		call McuSleep.irq_postamble();
	}

	async command bool HplSam3uMpuStatus.isStackingFault()
	{
		return (MPU_MMFSR->bits.mstkerr == 0x1);
	}

	async command bool HplSam3uMpuStatus.isUnstackingFault()
	{
		return (MPU_MMFSR->bits.munstkerr == 0x1);
	}

	async command bool HplSam3uMpuStatus.isDataAccessFault()
	{
		return (MPU_MMFSR->bits.daccviol == 0x1);
	}

	async command bool HplSam3uMpuStatus.isInstructionAccessFault()
	{
		return (MPU_MMFSR->bits.iaccviol == 0x1);
	}

	async command bool HplSam3uMpuStatus.isValidFaultAddress()
	{
		return (MPU_MMFSR->bits.mmarvalid == 0x1);
	}

	async command void *HplSam3uMpuStatus.getFaultAddress()
	{
		return (void *) MPU_MMFAR->bits.address;
	}
}
