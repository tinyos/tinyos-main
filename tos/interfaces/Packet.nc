// $Id: Packet.nc,v 1.5 2007-09-13 23:10:17 scipio Exp $
/*									tab:4
 * "Copyright (c) 2004-5 The Regents of the University  of California.  
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
    * @param  msg    the packet to clear
    */

  command void clear(message_t* msg);

  /**
    * Return the length of the payload of msg. This value may be less
    * than what maxPayloadLength() returns, if the packet is smaller than
    * the MTU. If a communication component does not support variably
    * sized data regions, then payloadLength() will always return
    * the same value as maxPayloadLength(). 
    *
    * @param  msg    the packet to examine
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
    * @param msg   the packet
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
   * Return a pointer to a protocol's payload region in a packet which
   * at least a certain length.  If the payload region is smaller than
   * the len parameter, then getPayload returns NULL.
   *
   * @param msg   the packet
   * @param len   the length of payload required
   * @return      a pointer to the packet's data payload for this layer
   */
  command void* getPayload(message_t* msg, uint8_t len);

}
