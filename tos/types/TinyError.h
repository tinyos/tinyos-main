// $Id: TinyError.h,v 1.12 2010-06-29 22:07:56 scipio Exp $
/*
 * Copyright (c) 2000-2005 The Regents of the University  of California.  
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
 * - Neither the name of the University of California nor the names of
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
 * @author Phil Levis
 * @author David Gay
 * Revision:  $Revision: 1.12 $
 *
 * Defines global error codes for error_t in TinyOS.
 */

#ifndef TINY_ERROR_H_INCLUDED
#define TINY_ERROR_H_INCLUDED

#ifdef NESC
#define NESC_COMBINE(x) @combine(x)
#else
#define NESC_COMBINE(x)
#endif

enum {
  SUCCESS        =  0,          
  FAIL           =  1,           // Generic condition: backwards compatible
  ESIZE          =  2,           // Parameter passed in was too big.
  ECANCEL        =  3,           // Operation cancelled by a call.
  EOFF           =  4,           // Subsystem is not active
  EBUSY          =  5,           // The underlying system is busy; retry later
  EINVAL         =  6,           // An invalid parameter was passed
  ERETRY         =  7,           // A rare and transient failure: can retry
  ERESERVE       =  8,           // Reservation required before usage
  EALREADY       =  9,           // The device state you are requesting is already set
  ENOMEM         = 10,           // Memory required not available
  ENOACK         = 11,           // A packet was not acknowledged
  ELAST          = 11            // Last enum value
};

typedef uint8_t error_t NESC_COMBINE("ecombine");

error_t ecombine(error_t r1, error_t r2) @safe()
/* Returns: r1 if r1 == r2, FAIL otherwise. This is the standard error
     combination function: two successes, or two identical errors are
     preserved, while conflicting errors are represented by FAIL.
*/
{
  return r1 == r2 ? r1 : FAIL;
}

#endif
