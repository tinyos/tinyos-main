/*
 * "Copyright (c) 2005 Stanford University. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 * 
 * IN NO EVENT SHALL STANFORD UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF STANFORD UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 * 
 * STANFORD UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND STANFORD UNIVERSITY
 * HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES,
 * ENHANCEMENTS, OR MODIFICATIONS."
 */

/**
 * Implementation of all of the basic TOSSIM primitives and utility
 * functions.
 *
 * @author Philip Levis
 * @date   Nov 22 2005
 */

// $Id: tos.h,v 1.3 2006-11-07 19:31:22 scipio Exp $

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
#endif

#endif
