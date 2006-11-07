/* $Id: CtpPacket.nc,v 1.3 2006-11-07 19:31:19 scipio Exp $ */
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

/**
 *  ADT for CTP data frames.
 *
 *  @author Philip Levis
 *  @author Kyle Jamieson
 *  @date   $Date: 2006-11-07 19:31:19 $
 */

#include <AM.h>
   
interface CtpPacket {
  // Sets the given options bit.
  command void          setOption(message_t* msg, ctp_options_t option);

  // Clears the given options bit.
  command void          clearOption(message_t* msg, ctp_options_t option);

  // Returns TRUE iff all of the given options bits are set.
  command bool          option(message_t* msg, ctp_options_t opt);

  command uint8_t       getThl(message_t* msg);
  command void          setThl(message_t* msg, uint8_t thl);

  command uint16_t      getEtx(message_t* msg);
  command void          setEtx(message_t* msg, uint16_t etx);

  command am_addr_t     getOrigin(message_t* msg);
  command void          setOrigin(message_t* msg, am_addr_t addr);

  command uint8_t       getSequenceNumber(message_t* msg);
  command void          setSequenceNumber(message_t* msg, uint8_t seqno);

  command uint8_t       getType(message_t* msg);
  command void          setType(message_t* msg, uint8_t id);

  command bool          matchInstance(message_t* m1, message_t* m2);
  command bool          matchPacket(message_t* m1, message_t* m2);
}
