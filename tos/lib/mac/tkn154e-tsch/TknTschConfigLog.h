/**
 * Copyright (c) 2015, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:T
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
 *
 * @author Moksha Birk <birk@tkn.tu-berlin.de>
 */

#ifndef _TKN_TSCH_CONFIG_LOG_H_
#define _TKN_TSCH_CONFIG_LOG_H_

// global logging switch
#define TKN_TSCH_LOG_ENABLED


// enable logging for specific topics

#define TKN_TSCH_LOG_INFO
#define TKN_TSCH_LOG_ERROR
#define TKN_TSCH_LOG_INIT
//#define TKN_TSCH_LOG_TIME_CORRECTION
//#define TKN_TSCH_LOG_ACTIVE_SLOT_INFO
#define TKN_TSCH_LOG_COLLISION_AVOIDANCE
#define TKN_TSCH_LOG_WARN
//#define TKN_TSCH_LOG_SLOT_STATE
//#define TKN_TSCH_LOG_DEBUG
#define TKN_TSCH_LOG_BUFFERING
#define TKN_TSCH_LOG_ADDRESS_FILTERING
//#define TKN_TSCH_LOG_RXTX_STATE
//#define TKN_TSCH_LOG_BLIP_RXTX_STATE
//#define


// logging switches for individual files

//#define TKN_TSCH_LOG_ENABLED_TSSMP
//#define TKN_TSCH_LOG_ENABLED_TSSM_RX
//#define TKN_TSCH_LOG_ENABLED_TSSM_TX
//#define TKN_TSCH_LOG_ENABLED_SCAN
//#define TKN_TSCH_LOG_ENABLED_TEMPLATE_MIN
//#define TKN_TSCH_LOG_ENABLED_SCHEDULE_MIN
//#define TKN_TSCH_LOG_ENABLED_PIB
//#define TKN_TSCH_LOG_ENABLED_FSM
//#define TKN_TSCH_LOG_ENABLED_FRAMES
//#define TKN_TSCH_LOG_ENABLED_PLAIN154_SWDEBUG
//#define TKN_TSCH_LOG_ENABLED_BLIP_BARE
//#define TKN_TSCH_LOG_ENABLED_

#endif
