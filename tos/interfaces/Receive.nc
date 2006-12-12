// $Id: Receive.nc,v 1.4 2006-12-12 18:23:15 vlahan Exp $
/*									tab:4
 * "Copyright (c) 2004-2005 The Regents of the University  of California.  
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
 *
 * Copyright (c) 2004 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * The basic message reception interface. 
 *
 * @author Philip Levis
 * @date   November 16, 2004
 * @see    Packet
 * @see    Send
 * @see    TEP 116: Packet Protocols
 */ 


#include <TinyError.h>
#include <message.h>

interface Receive {

  /**
   * Receive a packet buffer, returning a buffer for the signaling
   * component to use for the next reception. The return value
   * can be the same as <tt>msg</tt>, as long as the handling
   * component copies out the data it needs.
   *
   * <b>Note</b> that misuse of this interface is one of the most
   * common bugs in TinyOS code. For example, if a component both calls a
   * send on the passed message and returns it, then it is possible
   * the buffer will be reused before the send occurs, overwriting
   * the component's data. This would cause the mote to possibly
   * instead send a packet it most recently received.
   *
   * @param  msg      the receied packet
   * @param  payload  a pointer to the packet's payload
   * @param  len      the length of the data region pointed to by payload
   * @return          a packet buffer for the stack to use for the next
   *                  received packet.
   */
  
  event message_t* receive(message_t* msg, void* payload, uint8_t len);

  /**
   * Return point to a protocol's payload region in a packet.  If len
   * is not NULL, getPayload will return the length of the payload in
   * it. This call is identical to <TT>Packet.getPayload</TT>, and is
   * included in Receive as a convenience.
   *
   * @param  msg      the packet
   * @param  len      a pointer to where to store the payload length
   * @return          a pointer to the payload of the packet
   */
  command void* getPayload(message_t* msg, uint8_t* len);

  /**
   * Return the length of the payload of msg. This call is identical
   * to <TT>Packet.payloadLength</TT>, and is included in Receive as a
   * convenience.
   *
   * @param  msg      the packet
   * @return          the length of the packet's payload
   */
  command uint8_t payloadLength(message_t* msg);
  
}
