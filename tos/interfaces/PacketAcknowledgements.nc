/*
 * "Copyright (c) 2000-2006 The Regents of the University  of California.  
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
 */

/**
 * This interface allows a component to enable or disable acknowledgments
 * on a per-packet basis.
 *
 * @author Jonathan Hui
 * @author Philip Levis
 * @author Joe Polastre
 * @date   June 21 2006
 */

interface PacketAcknowledgements {

  /**
   * Tell a protocol that when it sends this packet, it should use synchronous
   * acknowledgments.
   * The acknowledgment is synchronous as the caller can check whether the
   * ack was received through the wasAcked() command as soon as a send operation
   * completes.
   *
   * @param 'message_t* ONE msg' - A message which should be acknowledged when transmitted.
   * @return SUCCESS if acknowledgements are enabled, EBUSY
   * if the communication layer cannot enable them at this time, FAIL
   * if it does not support them.
   */
  
  async command error_t requestAck( message_t* msg );

  /**
   * Tell a protocol that when it sends this packet, it should not use
   * synchronous acknowledgments.
   *
   * @param 'message_t* ONE msg' - A message which should not be acknowledged when transmitted.
   * @return SUCCESS if acknowledgements are disabled, EBUSY
   * if the communication layer cannot disable them at this time, FAIL
   * if it cannot support unacknowledged communication.
   */

  async command error_t noAck( message_t* msg );

  /**
   * Tell a caller whether or not a transmitted packet was acknowledged.
   * If acknowledgments on the packet had been disabled through noAck(),
   * then the return value is undefined. If a packet
   * layer does not support acknowledgements, this command must return always
   * return FALSE.
   *
   * @param 'message_t* ONE msg' - A transmitted message.
   * @return Whether the packet was acknowledged.
   *
   */
  
  async command bool wasAcked(message_t* msg);
  
}
