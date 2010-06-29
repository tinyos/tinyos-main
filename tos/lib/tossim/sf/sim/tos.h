/*
 * Copyright (c) 2005 Stanford University. All rights reserved.
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
 */

/**
 * Implementation of all of the basic TOSSIM primitives and utility
 * functions.
 *
 * @author Philip Levis
 * @author Chad Metcalf
 * @date   July 15 2007
 */

// $Id: tos.h,v 1.3 2010-06-29 22:07:51 scipio Exp $

#ifndef TOS_H_INCLUDED
#define TOS_H_INCLUDED

#if !defined(__CYGWIN__)
#if defined(__MSP430__)
#include <sys/inttypes.h>
#else
#include <inttypes.h>
#endif
#else //cygwin
#include <unistd.h>
#include <stdio.h>
#include <sys/types.h>
#endif

#include <string.h>
#include <stdlib.h>
#include <math.h>
#include <stddef.h>
#include <ctype.h>
#include <stdio.h>

/* 
 * TEMPORARY: include the Safe TinyOS macros so that annotations get
 * defined away for non-safe users -- this will no longer be necessary
 * after we require users to use the ncc that has Safe TinyOS
 * support 
 */
#include "../../lib/safe/include/annots_stage1.h"

#ifndef __cplusplus
typedef uint8_t bool;
#endif

enum { FALSE = 0, TRUE = 1 };

extern uint16_t TOS_NODE_ID;

#define PROGMEM

#ifndef TOSSIM_MAX_NODES
#define TOSSIM_MAX_NODES 1000
#endif

#include <sim_event_queue.h>
#include <sim_tossim.h>
#include <sim_mote.h>
#include <sim_log.h>

// We only want to include these files if we are compiling TOSSIM proper,
// that is, the C file representing the TinyOS application. The TinyOS
// build process means that this is the only really good place to put
// them.
#ifdef TOSSIM

struct @atmostonce { };
struct @atleastonce { };
struct @exactlyonce { };

#include <sim_log.c>
#include <heap.c>
#include <sim_event_queue.c>
#include <sim_tossim.c>
#include <sim_mac.c>
#include <sim_packet.c>
#include <sim_serial_packet.c>
#endif

#endif
