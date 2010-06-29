// $Id: Packet.nc,v 1.9 2010-06-29 22:07:46 scipio Exp $
/*
 * Copyright (c) 2004-5 The Regents of the University  of California.  
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
 *
 * Copyright (c) 2004-5 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/** 
  * The basic message data type accessors. Protocols may use
  * additional packet interfaces for their protocol specific
  * data/metadata.
  *
  * @author Philip Levis
  * @date   January 5 2005
  * @see    TEP 116: Packet Protocols
  */ 


#include <message.h>

interface Packet {


  /**
    * Clear out this packet.  Note that this is a deep operation and
    * total operation: calling clear() on any layer will completely
    * clear the packet for reuse.
    * @param  'message_t* ONE msg'    the packet to clear
    */

  command void clear(message_t* msg);

  /**
    * Return the length of the payload of msg. This value may be less
    * than what maxPayloadLength() returns, if the packet is smaller than
    * the MTU. If a communication component does not support variably
    * sized data regions, then payloadLength() will always return
    * the same value as maxPayloadLength(). 
    *
    * @param  'message_t* ONE msg'    the packet to examine
    * @return        the length of its current payload
    */

  command uint8_t payloadLength(message_t* msg);

  /**
    * Set the length field of the packet. This value is not checked
    * for validity (e.g., if it is larger than the maximum payload
    * size). This command is not used when sending packets, as calls
    * to send include a length parameter. Rather, it is used by
    * components, such as queues, that need to buffer requests to
    * send.  This command allows the component to store the length
    * specified in the request and later recover it when actually
    * sending.
    *
    * @param 'message_t* ONE msg'   the packet
    * @param len   the value to set its length field to
    */

  command void setPayloadLength(message_t* msg, uint8_t len);

 /**
   * Return the maximum payload length that this communication layer
   * can provide. Note that, depending on protocol fields, a given
   * request to send a packet may not be able to send the maximum
   * payload length (e.g., if there are variable length
   * fields). Protocols may provide specialized interfaces for these
   * circumstances.
   *
   * @return   the maximum size payload allowed by this layer
   */
  command uint8_t maxPayloadLength();


 /**
   * Return a pointer to a protocol's payload region in a packet.
   * If the caller intends to write to the payload region then
   * the <tt>len</tt> parameter must reflect the maximum required
   * length. If the caller (only) wants to read from the payload
   * region, then <tt>len</tt> may be set to the value of
   * payloadLength(). If the payload region is smaller than 
   * <tt>len</tt> this command returns NULL. The offset where
   * the payload region starts within a packet is fixed, i.e. for
   * a given <tt>msg</tt> this command will always return the same
   * pointer or NULL.
   *
   * @param 'message_t* ONE msg'   the packet 
   * @param len   the length of payload required
   * @return 'void* COUNT_NOK(len)'     a pointer to the packet's data payload for this layer
   *              or NULL if <tt>len</tt> is too big
   */
  command void* getPayload(message_t* msg, uint8_t len);

}
