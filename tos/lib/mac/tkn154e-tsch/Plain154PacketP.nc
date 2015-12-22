/*
 * Copyright (c) 2014, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without 
 * modification, are permitted provided that the following conditions 
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright 
 *   notice, this list of conditions and the following disclaimer in the 
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names 
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT 
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED 
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, 
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY 
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE 
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Based on lib/mac/tkn154/PibP.nc by Jan Hauer.
 * 
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * @author Moksha Birk <birk@tkn.tu-berlin.de>
 * ========================================================================
 */

/*
  TODO THIS IS UNCHECKED AND NEEDS WORK !
*/

/** 
 * This component maintains access to basic parts of IEEE 15.4 frames.
 */

#include "plain154_message_structs.h"
#include "plain154_types.h"
#include "message.h"
#include "plain154_values.h"

#define GET_HEADER_FROM_MSG(x) ((plain154_header_t*) ((void*) ((x)->header)))

// TODO The whole TOSH_DATA_LENGTH and maximum payload length topic is still unsolved for plain154/tkntsch !
#define _MAX_PAYLOAD_ TOSH_DATA_LENGTH

module Plain154PacketP {
  provides 
  {
    interface Init as LocalInit;
    interface Packet;
  }
}
implementation
{
  command error_t LocalInit.init()
  {
    return SUCCESS;
  }

  /* ----------------------- Frame Access ----------------------- */

  command void Packet.clear(message_t* msg)
  {
    plain154_header_t* header = GET_HEADER_FROM_MSG(msg);
    message_metadata_t* metadata = (message_metadata_t*) ((void*) msg->metadata);
    header->payloadlen = 0;
    header->fcf1 = 0;
    header->fcf2 = 0;
    memset(metadata, 0x0, sizeof(message_metadata_t));
  }

  command uint8_t Packet.payloadLength(message_t* msg)
  {
    return GET_HEADER_FROM_MSG(msg)->payloadlen;
  }

  command void Packet.setPayloadLength(message_t* msg, uint8_t len)
  {
    // TODO check length
    GET_HEADER_FROM_MSG(msg)->payloadlen = len;
  }

  command uint8_t Packet.maxPayloadLength()
  {
    return _MAX_PAYLOAD_;
  }

  command void* Packet.getPayload(message_t* msg, uint8_t len)
  {
    // TODO length check should be improved 
    if (len > _MAX_PAYLOAD_)
      return NULL;

    return msg->data;
  }
}
