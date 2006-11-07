//$Id: NativeSerialEnums.h,v 1.3 2006-11-07 19:30:43 scipio Exp $

/* "Copyright (c) 2000-2003 The Regents of the University of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

//@author Cory Sharp <cssharp@eecs.berkeley.edu>

namespace NativeSerialEnums
{
  enum event_type
  {
    DATA_AVAILABLE = (1<<0),
    OUTPUT_EMPTY = (1<<1),
    CTS = (1<<2),
    DSR = (1<<3),
    RING_INDICATOR = (1<<4),
    CARRIER_DETECT = (1<<5),
    OVERRUN_ERROR = (1<<6),
    PARITY_ERROR = (1<<7),
    FRAMING_ERROR = (1<<8),
    BREAK_INTERRUPT = (1<<9),
  };

  enum parity_type
  {
    NPARITY_NONE = 0,
    NPARITY_EVEN = 1,
    NPARITY_ODD = 2,
  };

  enum stop_type
  {
    STOPBITS_1 = 1,
    STOPBITS_2 = 2,
    STOPBITS_1_5 = 3,
  };
};

