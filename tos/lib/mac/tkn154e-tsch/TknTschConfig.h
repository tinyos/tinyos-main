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
 * @author Jasper Buesch <buesch@tkn.tu-berlin.de>
 */

#ifndef _TKN_TKN_CONFIG_H_
#define _TKN_TKN_CONFIG_H_


#define TSCH_BEACON_INTERVAL 5

//#define TKN_TSCH_DISABLE_TIME_CORRECTION_BEACONS

//#define TKN_TSCH_DISABLE_TIME_CORRECTION_ACKS

#define TKN_TSCH_DISABLE_ACTIVE_FOR_ALL_SLOTS

#define TKN_TSCH_MAX_NUM_INACTIVE_SLOTS 110

//#define TKN_TSCH_DISABLE_ADDRESS_FILTERING

//#define TKN_TSCH_DISABLE_SLEEP

#define TKNTSCH_SF_POOL_SIZE 40
#define TKNTSCH_LINK_POOL_SIZE 40

#define TKN_TSCH_DISABLE_UNICASTS_IN_SHARED_SLOTS

#endif
