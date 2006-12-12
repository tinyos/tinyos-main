/* $Id: CtpRoutingPacket.nc,v 1.4 2006-12-12 18:23:29 vlahan Exp $ */
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
 *  ADT for CTP routing frames.
 *
 *  @author Philip Levis
 *  @author Kyle Jamieson
 *  @date   $Date: 2006-12-12 18:23:29 $
 */

#include <AM.h>
   
interface CtpRoutingPacket {

  /* Allow individual options to be read, set, and reset independently */
  command bool          getOption(message_t* msg, ctp_options_t opt);
  command void          setOption(message_t* msg, ctp_options_t opt);
  command void          clearOption(message_t* msg, ctp_options_t opt);
  
  /* Clear all options */
  command void          clearOptions(message_t* msg);

  command am_addr_t     getParent(message_t* msg);
  command void          setParent(message_t* msg, am_addr_t addr);

  command uint16_t      getEtx(message_t* msg);
  command void          setEtx(message_t* msg, uint8_t etx);
}
