//$Id: NativeSerialEnums.h,v 1.5 2010-06-29 22:07:42 scipio Exp $

/* Copyright (c) 2000-2003 The Regents of the University of California.  
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

