/*
 * "Copyright (c) 2008, 2009 The Regents of the University  of California.
 * All rights reserved."
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */
#ifndef _BLIP_PLATFORM_H
#define _BLIP_PLATFORM_H

/* this file has platform-specific configuration settings that don't
   belong anywhere else */

/* bring in  */
#if defined(PC)
// use library versions if on linux
#include <netinet/in.h>
#include <endian.h>
#else
// if we're not on a pc, assume little endian for now
#define __LITTLE_ENDIAN 1234
#define __BYTE_ORDER __LITTLE_ENDIAN
#endif

/* buffer sizes are defined here. */
#if !defined(PLATFORM_MICAZ)
#define IP_MALLOC_HEAP_SIZE 1500
enum {
  IP_NUMBER_FRAGMENTS = 14,
};
#else
#define IP_MALLOC_HEAP_SIZE 500
enum {
  IP_NUMBER_FRAGMENTS = 4,
};
#endif


#ifndef BLIP_L2_RETRIES
#define BLIP_L2_RETRIES 5
#endif

#ifndef BLIP_L2_DELAY
#define BLIP_L2_DELAY 15
#endif


#endif
