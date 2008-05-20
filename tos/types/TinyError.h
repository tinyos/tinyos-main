// $Id: TinyError.h,v 1.8 2008-05-20 21:46:21 scipio Exp $
/*									tab:4
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
 * All rights reserved.
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
 */

/**
 * @author Phil Levis
 * @author David Gay
 * Revision:  $Revision: 1.8 $
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
  ELAST          = 10            // Last enum value
};

typedef uint8_t error_t NESC_COMBINE("ecombine");

error_t ecombine(error_t r1, error_t r2)
/* Returns: r1 if r1 == r2, FAIL otherwise. This is the standard error
     combination function: two successes, or two identical errors are
     preserved, while conflicting errors are represented by FAIL.
*/
{
  return r1 == r2 ? r1 : FAIL;
}

#endif
