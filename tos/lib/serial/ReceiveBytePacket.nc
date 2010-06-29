//$Id: ReceiveBytePacket.nc,v 1.5 2010-06-29 22:07:50 scipio Exp $

/* Copyright (c) 2000-2005 The Regents of the University of California.  
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
 * - Neither the name of the copyright holder nor the names of
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
 */

/**
 * This is the data interface that a serial protocol provides and
 * a serial dispatcher uses. The dispatcher expects the following pattern
 * of calls: ((startPacket)+ (byteReceived)* (endPacket)+)*
 * It should ignore any signals that do not follow this pattern.
 * The interface is used to separate the state machine of the wire protocol
 * from the complexities of dispatch.
 *
 * @author Philip Levis
 * @author Ben Greenstein
 * @date August 7 2005
 *
 */

interface ReceiveBytePacket {

  
  /**
   * Signals the upper layer to indicate that reception of a frame has begun.
   * Used by the upper layer to prepare for packet reception. If the upper
   * layer does not want to receive a packet (or isn't ready) it may
   * return a non-SUCCESS code  such as EBUSY to the lower layer to discard
   * the frame. The underlying layer may signal endPacket in response to
   * such a discard request.
   * @return Returns an error_t code indicating whether the
   * dispatcher would like to receive a packet (SUCCESS), or not
   * perhaps because it isn't ready (EBUSY).
   */
  async event error_t startPacket();

  /**
   * Signals the upper layer that a byte of the encapsulated packet has been
   * received. Passes this byte as a parameter to the function.
   * @param data A byte of the encapsulated packet that has been received.
   */
  async event void byteReceived(uint8_t data);
  /**
   * Signalled to indicate that a packet encapsulated withing a serial
   * frame has been received. SUCCESS should be passed by the lower layer
   * following verification that the packet has been received correctly.
   * A value of error_t indicating an error should be passed when the lower
   * layer's verification test fails or when the lower layer loses sync.
   * @param result An error_t code indicating whether the framer has
   * passed all bytes of an encapsulated packet it receives from
   * serial to the dispatcher (SUCCESS) or not (FAIL).
   */
  async event void endPacket(error_t result);
}

