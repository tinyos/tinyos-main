/* $Id: Ctp.h,v 1.6 2008-07-10 18:59:47 idgay Exp $ */

/*
 * Copyright (c) 2006 Stanford University.
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

/*
 *  Header file that declares the AM types, message formats, and
 *  constants for the TinyOS reference implementation of the
 *  Collection Tree Protocol (CTP), as documented in TEP 123.
 *
 *  @author Philip Levis
 *  @date   $Date: 2008-07-10 18:59:47 $
 */

#ifndef CTP_H
#define CTP_H

#include <Collection.h>
#include <AM.h>

#define UQ_CTP_CLIENT "CtpSenderC.CollectId"

enum {
    // AM types:
    AM_CTP_ROUTING = 0x70,
    AM_CTP_DATA    = 0x71,
    AM_CTP_DEBUG   = 0x72,

    // CTP Options:
    CTP_OPT_PULL      = 0x80, // TEP 123: P field
    CTP_OPT_ECN       = 0x40, // TEP 123: C field
};

typedef nx_uint8_t nx_ctp_options_t;
typedef uint8_t ctp_options_t;

typedef nx_struct {
  nx_ctp_options_t    options;
  nx_uint8_t          thl;
  nx_uint16_t         etx;
  nx_am_addr_t        origin;
  nx_uint8_t          originSeqNo;
  nx_collection_id_t  type;
  nx_uint8_t (COUNT(0) data)[0]; // Deputy place-holder, field will probably be removed when we Deputize Ctp
} ctp_data_header_t;

typedef nx_struct {
  nx_ctp_options_t    options;
  nx_am_addr_t        parent;
  nx_uint16_t         etx;
  nx_uint8_t (COUNT(0) data)[0]; // Deputy place-holder, field will probably be removed when we Deputize Ctp
} ctp_routing_header_t;

#endif
