/*
 * Copyright (c) 2003-2007, Vanderbilt University
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

module NoDiagMsgC
{
	provides interface DiagMsg;
}

implementation
{
	async command bool DiagMsg.record()
	{
		return FALSE;
	}

#define IMPLEMENT(NAME, TYPE, TYPE2) \
	async command void DiagMsg.NAME(TYPE value) { } \
	async command void DiagMsg.NAME##s(const TYPE *value, uint8_t len) { }

	IMPLEMENT(int8, int8_t, TYPE_INT8)
	IMPLEMENT(uint8, uint8_t, TYPE_UINT8)
	IMPLEMENT(hex8, uint8_t, TYPE_HEX8)
	IMPLEMENT(int16, int16_t, TYPE_INT16)
	IMPLEMENT(uint16, uint16_t, TYPE_UINT16)
	IMPLEMENT(hex16, uint16_t, TYPE_HEX16)
	IMPLEMENT(int32, int32_t, TYPE_INT32)
	IMPLEMENT(uint32, uint32_t, TYPE_UINT32)
	IMPLEMENT(hex32, uint32_t, TYPE_HEX32)
	IMPLEMENT(int64, int64_t, TYPE_INT64)
	IMPLEMENT(uint64, uint64_t, TYPE_UINT64)
	IMPLEMENT(real, float, TYPE_FLOAT)
	IMPLEMENT(chr, char, TYPE_CHAR)

	async command void DiagMsg.str(const char* str) { }
	async command void DiagMsg.send() { }
}
