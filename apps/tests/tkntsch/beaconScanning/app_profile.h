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
 * Code fragements have been taken from tkn154/ScanP components of Jan Hauer.
 *
 * @author Jasper Buesch <buesch@tkn.tu-berlin.de>
 */

#ifndef __APP_PROFILE_H
#define __APP_PROFILE_H

#ifndef APP_RADIO_CHANNEL
#define APP_RADIO_CHANNEL RADIO_CHANNEL
#endif

#define T32_FROM_US(dt) ((uint32_t) ((((uint64_t) dt) * 32768UL) / (1000000UL)))
#define T32_TO_US(dt) ((uint32_t) ((((uint64_t) dt) * 1000000UL) / (32768UL)))

enum {
  COORDINATOR_ADDRESS = 0x4331,
  PAN_ID = 0x8172,
  BEACON_ORDER = 6,
  PAN_DESCRIPTOR_LIST_ENTRIES = 10,
  SEARCH_CHANNELS = 1<<11 | 1<<12 | 1<<17 | 1<<26,
};

#endif
