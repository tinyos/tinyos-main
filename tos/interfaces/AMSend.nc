// $Id: AMSend.nc,v 1.8 2010-06-29 22:07:46 scipio Exp $
/*
 * Copyright (c) 2005 The Regents of the University  of California.  
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
 * Copyright (c) 2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/** The basic active message message sending interface. Also see
  * Packet, Receive, and Send.
  *
  * @author Philip Levis
  * @date   January 5 2005
  * @see   Packet
  * @see   AMPacket
  * @see   Receive
  * @see   TEP 116: Packet Protocols
  */ 


#include <TinyError.h>
#include <message.h>
#include <AM.h>

interface AMSend {

  /** 
    * Send a packet with a data payload of <tt>len</tt> to address
    * <tt>addr</tt>. To determine the maximum available size, use the
    * Packet interface of the component providing AMSend. If send
    * returns SUCCESS, then the component will signal the sendDone
    * event in the future; if send returns an error, it will not
    * signal the event.  Note that a component may accept a send
    * request which it later finds it cannot satisfy; in this case, it
    * will signal sendDone with error code.
    *
    * @param addr   address to which to send the packet
    * @param 'message_t* ONE msg'    the packet
    * @param len    the length of the data in the packet payload
    * @return       SUCCESS if the request to send succeeded and a
    *               sendDone will be signaled later, EBUSY if the
    *               abstraction cannot send now but will be able to
    *               later, or FAIL if the communication layer is not
    *               in a state that can send (e.g., off).
    * @see          sendDone
    */ 
  command error_t send(am_addr_t addr, message_t* msg, uint8_t len);

  /**
    * Cancel a requested transmission. Returns SUCCESS if the 
    * transmission was canceled properly (not sent in its
    * entirety). Note that the component may not know
    * if the send was successfully canceled, if the radio is
    * handling much of the logic; in this case, a component
    * should be conservative and return an appropriate error code.
    * A successful call to cancel must always result in a 
    * sendFailed event, and never a sendSucceeded event.
    * 
    * @param  'message_t* ONE msg'    the packet whose transmission should be cancelled.
    * @return SUCCESS if the transmission was cancelled, FAIL otherwise.
    * @see    sendDone
    */
  command error_t cancel(message_t* msg);

  /** 
    * Signaled in response to an accepted send request. <tt>msg</tt> is
    * the message buffer sent, and <tt>error</tt> indicates whether
    * the send was successful.
    *
    * @param  'message_t* ONE msg'   the packet which was submitted as a send request
    * @param  error SUCCESS if it was sent successfully, FAIL if it was not,
    *               ECANCEL if it was cancelled
    * @see send
    * @see cancel
    */ 

  event void sendDone(message_t* msg, error_t error);


   /**
   * Return the maximum payload length that this communication layer
   * can provide. This command behaves identically to
   * <tt>Packet.maxPayloadLength</tt> and is included in this
   * interface as a convenience.
   *
   * @return the maximum payload length
   */

  
  command uint8_t maxPayloadLength();


   /**
    * Return a pointer to a protocol's payload region in a packet.
    * This command behaves identically to <tt>Packet.getPayload</tt>
    * (minus the length parameter) and is included in this interface
    * as a convenience.
    *
    * @param  'message_t* ONE msg'    the packet
    * @return 'void* COUNT(len)'      the payload of the packet
    */
  command void* getPayload(message_t* msg, uint8_t len);

  
}
