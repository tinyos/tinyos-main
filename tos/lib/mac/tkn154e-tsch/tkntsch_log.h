/*
 * Copyright (c) 2015, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * @author Moksha Birk <birk@tkn.tu-berlin.de>
 *
 */

#ifndef TKNTSCH_LOG_H_
#define TKNTSCH_LOG_H_

#include "tkntsch_types.h"

typedef struct {
  tkntsch_asn_t asn;
} tkntsch_log_tssm_t;


// define logging macros (depending on the settings in TknTschConfigLog.h)
#ifdef TKN_TSCH_LOG_ENABLED

#ifndef NEW_PRINTF_SEMANTICS
#define NEW_PRINTF_SEMANTICS
#endif
#include "printf.h"
#define T_LOG_FLUSH printfflush()

#else /* ! TKN_TSCH_LOG_ENABLED */

// logging is not enabled undefine alle options
#define T_LOG_FLUSH
#undef TKN_TSCH_LOG_INFO
#undef TKN_TSCH_LOG_ERROR
#undef TKN_TSCH_LOG_INIT
#undef TKN_TSCH_LOG_TIME_CORRECTION
#undef TKN_TSCH_LOG_ACTIVE_SLOT_INFO
#undef TKN_TSCH_LOG_COLLISION_AVOIDANCE
#undef TKN_TSCH_LOG_WARN
#undef TKN_TSCH_LOG_SLOT_STATE
#undef TKN_TSCH_LOG_DEBUG
#undef TKN_TSCH_LOG_BUFFERING
#undef TKN_TSCH_LOG_ADDRESS_FILTERING
#undef TKN_TSCH_LOG_RXTX_STATE
#undef TKN_TSCH_LOG_BLIP_RXTX_STATE

#endif /* TKN_TSCH_LOG_ENABLED */


#ifdef TKN_TSCH_LOG_INFO
#define T_LOG_INFO printf
#else
#define T_LOG_INFO(...)
#endif

#ifdef TKN_TSCH_LOG_ERROR
#define T_LOG_ERROR printf
#else
#define T_LOG_ERROR(...)
#endif

#ifdef TKN_TSCH_LOG_INIT
#define T_LOG_INIT printf
#else
#define T_LOG_INIT(...)
#endif

#ifdef TKN_TSCH_LOG_TIME_CORRECTION
#define T_LOG_TIME_CORRECTION printf
#else
#define T_LOG_TIME_CORRECTION(...)
#endif

#ifdef TKN_TSCH_LOG_ACTIVE_SLOT_INFO
#define T_LOG_ACTIVE_SLOT_INFO printf
#else
#define T_LOG_ACTIVE_SLOT_INFO(...)
#endif

#ifdef TKN_TSCH_LOG_COLLISION_AVOIDANCE
#define T_LOG_COLLISION_AVOIDANCE printf
#else
#define T_LOG_COLLISION_AVOIDANCE(...)
#endif

#ifdef TKN_TSCH_LOG_WARN
#define T_LOG_WARN printf
#else
#define T_LOG_WARN(...)
#endif

#ifdef TKN_TSCH_LOG_SLOT_STATE
#define T_LOG_SLOT_STATE printf
#else
#define T_LOG_SLOT_STATE(...)
#endif

#ifdef TKN_TSCH_LOG_DEBUG
#define T_LOG_DEBUG printf
#else
#define T_LOG_DEBUG(...)
#endif

#ifdef TKN_TSCH_LOG_BUFFERING
#define T_LOG_BUFFERING printf
#else
#define T_LOG_BUFFERING(...)
#endif

#ifdef TKN_TSCH_LOG_ADDRESS_FILTERING
#define T_LOG_ADDRESS_FILTERING printf
#else
#define T_LOG_ADDRESS_FILTERING(...)
#endif

#ifdef TKN_TSCH_LOG_RXTX_STATE
#define T_LOG_RXTX_STATE printf
#else
#define T_LOG_RXTX_STATE(...)
#endif

#ifdef TKN_TSCH_LOG_BLIP_RXTX_STATE
#define T_LOG_BLIP_RXTX_STATE printf
#else
#define T_LOG_BLIP_RXTX_STATE(...)
#endif

#ifdef TKN_TSCH_LOG_
#define T_LOG_ printf
#else
#define T_LOG_(...)
#endif

#endif /* TKNTSCH_LOG_H_ */
