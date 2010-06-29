/*
 * Copyright (c) 2000-2006 The Regents of the University  of California.  
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
