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
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * @author Moksha Birk <birk@tkn.tu-berlin.de>
 *
 * ========================================================================
 */

#ifndef PLAIN_IEEE154_MESSAGE_STRUCTS_H
#define PLAIN_IEEE154_MESSAGE_STRUCTS_H

//#include <Ieee154.h>
//#include <jendefs.h>

/* TOSH_DATA_LENGTH should be the maximum length of the MAC payload */
// add case if using security header
#ifndef TOSH_DATA_LENGTH
  // using the worst case maximum:
  //   127 - 2 FCF - 1 DSN - 10 src - 10 dest - 2 FCS
  #define TOSH_DATA_LENGTH 102
#elif TOSH_DATA_LENGTH < 102
  #warning "MAC payload region is smaller than aMaxMACPayloadSize!"
#endif

/**
 * IEEE 802.15.4 sends the least significant bits and bytes first
 *  -> little endian
 */

typedef nx_union {
  nxle_uint16_t short_addr;
//  nxle_uint8_t long_addr[8];
  nxle_uint64_t long_addr;
} plain154_header_mixed_addr_field_t;

typedef nx_struct {
  nxle_uint8_t fcf1;
  nxle_uint8_t fcf2;
  nxle_uint8_t dsn;
  nxle_uint16_t srcpan;
  plain154_header_mixed_addr_field_t src;
  nxle_uint16_t destpan;
  plain154_header_mixed_addr_field_t dest;
  nxle_uint8_t hie[6];
  nxle_uint8_t payloadlen;

  // insert security header here, if needed

  // active message stuff (not important yet)
/*
#ifndef PLAIN154_ACTIVE_MESSAGE_SUPPORT_DISABLED
// This is a workaround: both, network and AM ID, are actually part of the
// MAC payload, but in the TinyOS world they are part of the header. To
// support bridging between radio and serial stack above AM layer
// we will let it look like TinyOS expects it to look like, which involves
// some extra overhead in our AM layer (a memmove) as well as adding the
// one (or two) struct members below.

  #ifndef TFRAMES_ENABLED
  // I-Frame 6LowPAN interoperability byte
  nxle_uint8_t network;
  #endif

  // Active Message identifier
  nxle_uint8_t type;
#endif
*/

} plain154_header_t;

typedef nx_struct {
} plain154_footer_t;

typedef nx_struct {
  nx_uint32_t timestamp;
  nx_bool valid_timestamp;
  nx_uint8_t lqi;
  nx_uint8_t transmissions;
  nx_uint32_t tracker;
  nx_uint8_t handle;
} plain154_metadata_t;

typedef struct
{
  plain154_header_t *header;
  uint8_t *payload;
  plain154_metadata_t *metadata;
  uint8_t headerLen;
  uint8_t payloadLen;
  uint8_t client;
  uint8_t handle;
} plain154_txframe_t;

#endif
