// $Id: AMPacket.nc,v 1.8 2010-06-29 22:07:46 scipio Exp $
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
  * The Active Message accessors, which provide the AM local address and
  * functionality for querying packets. Active Messages are a single-hop
  * communication protocol. Therefore, fields such as source and destination
  * represent the single-hop source and destination. Multihop sources and
  * destinations are defined by the corresponding multihop protocol (if any).
  * Also see the Packet interface.
  *
  * @author Philip Levis 
  * @date   January 18 2005
  * @see    Packet
  * @see    AMSend
  * @see    TEP 116: Packet Protocols
  */ 


#include <message.h>
#include <AM.h>

interface AMPacket {

  /**
   * Return the node's active message address associated with this AM stack.
   * @return The address
   */

  command am_addr_t address();

  /**
   * Return the AM address of the destination of the AM packet.
   * If <tt>amsg</tt> is not an AM packet, the results of this command
   * are undefined.
   * @param 'message_t* ONE amsg'    the packet
   * @return        the destination address of the packet.
   */
  
  command am_addr_t destination(message_t* amsg);

  /**
   * Return the AM address of the source of the AM packet.
   * If <tt>amsg</tt> is not an AM packet, the results of this command
   * are undefined.
   * @param 'message_t* ONE amsg'  the packet
   * @return      the source address of the packet.
   */
   
  command am_addr_t source(message_t* amsg);
  
  /**
   * Set the AM address of the destination field of the AM packet.  As
   * the AM address is set as part of sending with the AMSend
   * interface, this command is not used for sending packets.  Rather,
   * it is used when a component, such as a queue, needs to buffer a
   * request to send. The component can save the destination address
   * and then recover it when actually sending. If <tt>amsg</tt> is
   * not an AM packet, the results of this command are undefined.
   *
   * @param  'message_t* ONE amsg'   the packet
   * @param  addr   the address
   */

  command void setDestination(message_t* amsg, am_addr_t addr);

  /**
   * Set the AM address of the source field of the AM packet.  As
   * the AM address is set as part of sending with the AMSend
   * interface, this command is not used for sending packets.  Rather,
   * it is used when a component, such as a queue, needs to buffer a
   * request to send. The component can save the source address
   * and then recover it when actually sending. As an AM layer generally
   * sets the source address to be the local address, this interface
   * is not commonly used except when a system is bypassing the AM
   * layer (e.g., a protocol bridge). If <tt>amsg</tt> is
   * not an AM packet, the results of this command are undefined.
   *
   * @param  'message_t* ONE amsg'   the packet
   * @param  addr   the address
   */

  command void setSource(message_t* amsg, am_addr_t addr);

  /**
   * Return whether <tt>amsg</tt> is destined for this mote. This is
   * partially a shortcut for testing whether the return value of
   * <tt>destination</tt> and <tt>address</tt> are the same. It
   * may, however, include additional logic. For example, there
   * may be an AM broadcast address: <tt>destination</tt> will return
   * the broadcast address, but <tt>address</tt> will still be
   * the mote's local address. If <tt>amsg</tt> is not an AM packet,
   * the results of this command are undefined.
   *
   * @param  'message_t* ONE amsg'   the packet
   * @return        whether the packet is addressed to this AM stack
   */
  command bool isForMe(message_t* amsg);
  
  /**
   * Return the AM type of the AM packet.
   * If <tt>amsg</tt> is not an AM packet, the results of this command
   * are undefined.
   *
   * @param  'message_t* ONE amsg'   the packet
   * @return        the AM type
   */
  
  command am_id_t type(message_t* amsg);

  /**
   * Set the AM type of the AM packet.  As the AM type is set as part
   * of sending with the AMSend interface, this command is not used
   * for sending packets. Instead, it is used when a component, such
   * as a queue, needs to buffer a request to send. The component can
   * save the AM type in the packet then recover it when actually
   * sending. If <tt>amsg</tt> is not an AM packet, the results of
   * this command are undefined.
   * 
   * @param  'message_t* ONE amsg'    the packet
   * @param  t       the AM type
   */
  
  command void setType(message_t* amsg, am_id_t t);

  /**
   * Get the AM group of the AM packet. The AM group is a logical
   * identifier that distinguishes sets of nodes which may share
   * a physical communication medium but wish to not communicate.
   * The AM group logically separates the sets of nodes. When
   * a node sends a packet, it fills in its AM group, and typically
   * nodes only receive packets whose AM group field matches their
   * own.
   *
   * @param 'message_t* ONE amsg' the packet
   * @return the AM group of this packet
   */
  
  command am_group_t group(message_t* amsg);

  /**
   * Set the AM group field of a packet. Note that most data link
   * stacks will set this field automatically on a send request, which
   * may overwrite changes made with this command.
   *
   * @param 'message_t* ONE amsg' the packet
   * @param group the packet's new AM group value
   */
  command void setGroup(message_t* amsg, am_group_t grp);

  /**
   * Provides the current AM group of this communication interface.
   *
   * @return The AM group.
   */
  
  command am_group_t localGroup();
}
