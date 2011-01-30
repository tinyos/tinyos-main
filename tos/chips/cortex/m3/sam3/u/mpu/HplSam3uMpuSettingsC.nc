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

module HplSam3uMpuSettingsC
{
	provides interface HplSam3uMpuSettings;
}
implementation
{
	async command error_t HplSam3uMpuSettings.getMpuSettings(
		uint8_t regionNumber,
		bool enable,
		void *baseAddress,
		uint32_t size, // in bytes (bug: 4 GB not possible with this interface)
		bool enableInstructionFetch,
		bool enableReadPrivileged,
		bool enableWritePrivileged,
		bool enableReadUnprivileged,
		bool enableWriteUnprivileged,
		bool cacheable, // should be turned off for periphery and sys control (definitive guide, p. 213)
		bool bufferable, // should be turned off for sys control to be strongly ordered (definitive guide, p. 213)
		uint8_t disabledSubregions, // bit = 1: subregion disabled
		mpu_rbar_t *rbar_param, // RBAR register value output
		mpu_rasr_t *rasr_param
	)
	{
		uint8_t sizeField = 0; // size encoded in 5 bits (definitive guide, p. 209)
		uint32_t sizeIter = size;
		uint8_t i = 0;

		mpu_rbar_t rbar;
		mpu_rasr_t rasr;

		if (regionNumber > 7) return FAIL;

		// size has to be greater or equal to 32
		if (size < 32) return FAIL;

		// compute size encoding
		while (sizeIter != 0) {
			sizeIter = sizeIter >> 1;
			sizeField++;
		}
		sizeField -= 2; // 32 bytes has to equal b00100 (4)

		// size has to be power of 2
		// compute size from power
		sizeIter = 2; // = sizeField of 0
		for (i = 0; i < sizeField; i++) {
			sizeIter *= 2;
		}
		if (sizeIter != size) return FAIL;

		// check alignment of base address to size
		if ((((uint32_t) baseAddress) & (size - 1)) != 0) return FAIL;
		
		// program region
		rbar.flat = (uint32_t) baseAddress;
		rbar.bits.region = regionNumber;
		rbar.bits.valid = 1; // region field is valid

		rasr.flat = 0;

		rasr.bits.xn = (enableInstructionFetch == TRUE ? 0 : 1); // 1 = instruction fetch disabled
		rasr.bits.srd = disabledSubregions;
		rasr.bits.tex = 0;
		rasr.bits.s = 1; // shareable
		rasr.bits.c = (cacheable == TRUE ? 1 : 0); // 1 = cacheable
		rasr.bits.b = (bufferable == TRUE ? 1 : 0); // 1 = bufferable
		rasr.bits.size = sizeField;
		rasr.bits.enable = enable; // region enabled or disabled

		// access permissions (see definitive guide, p. 209)
		// impossible combinations return FAIL
		if (enableReadPrivileged == FALSE) {
			// SV no read -> SV no access, user no access
			rasr.bits.ap = 0x0;
			if (enableWritePrivileged == TRUE || enableReadUnprivileged == TRUE || enableWriteUnprivileged == TRUE) return FAIL;
		} else {
			// SV read
			if (enableWritePrivileged == FALSE) {
				// SV read-only
				if (enableWriteUnprivileged == TRUE) return FAIL;
				if (enableReadUnprivileged == FALSE) {
					// SV read-only, user no access
					rasr.bits.ap = 0x5;
				} else {
					// SV read-only, user read-only
					rasr.bits.ap = 0x6;
				}
			} else {
				// SV read/write
				if (enableReadUnprivileged == FALSE) {
					// SV read/write, user no read -> user no access
					if (enableWriteUnprivileged == TRUE) return FAIL;
					rasr.bits.ap = 0x1;
				} else {
					// SV read/write, user read
					if (enableWriteUnprivileged == FALSE) {
						// SV read/write, user read-only
						rasr.bits.ap = 0x2;
					} else {
						// SV read/write, user read/write
						rasr.bits.ap = 0x3;
					}
				}
			}
		}

		// output register values
		*rbar_param = rbar;
		*rasr_param = rasr;

		return SUCCESS;
	}
}
