//$Id: ReceiveBytePacket.nc,v 1.3 2006-11-07 19:31:20 scipio Exp $

/* "Copyright (c) 2000-2005 The Regents of the University of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
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

