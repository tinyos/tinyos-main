/*
 * Copyright (c) 2007, Vanderbilt University
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

#include "Tasklet.h"
#include "RadioAssert.h"
#include "message.h"
#include "RadioConfig.h"

module RadioDriverConfigP
{
	provides
	{
#if defined(PLATFORM_IRIS) || defined(PLATFORM_MULLE) || defined(PLATFORM_MESHBEAN)
		interface RF230DriverConfig as RadioDriverConfig;
#elif defined(PLATFORM_MESHBEAN900)
		interface RF212DriverConfig as RadioDriverConfig;
#elif defined(PLATFORM_MICAZ) || defined(PLATFORM_TELOSA) || defined(PLATFORM_TELOSB)
		interface CC2420XDriverConfig as RadioDriverConfig;
#elif defined(PLATFORM_UCMINI)
		interface RFA1DriverConfig as RadioDriverConfig;
#elif defined(PLATFORM_UCDUAL)
		interface Si443xDriverConfig as RadioDriverConfig;
#endif
	}
}

implementation
{
	async command uint8_t RadioDriverConfig.headerLength(message_t* msg)
	{
		return 0;
	}

	async command uint8_t RadioDriverConfig.maxPayloadLength()
	{
		return sizeof(message_header_t) + TOSH_DATA_LENGTH;
	}

	async command uint8_t RadioDriverConfig.metadataLength(message_t* msg)
	{
		return 0;
	}

#if ! defined(PLATFORM_UCMINI)
	async command uint8_t RadioDriverConfig.headerPreloadLength()
	{
		return 7;
	}
#endif

	async command bool RadioDriverConfig.requiresRssiCca(message_t* msg)
	{
		return FALSE;
	}
}
