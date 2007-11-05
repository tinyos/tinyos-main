/*
 * Copyright (c) 2003-2007, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
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
