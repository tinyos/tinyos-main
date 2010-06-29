//$Id: SerialFrameComm.nc,v 1.5 2010-06-29 22:07:50 scipio Exp $

/* Copyright (c) 2005 The Regents of the University of California.  
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
 *
 * This interface sits between a serial byte encoding component and a
 * framing/packetizing component. It is to be used with framing protocols
 * that place delimiters between frames. This interface separates the tasks
 * of interpreting and coding delimiters and escape bytes from the rest of
 * the wire protocol.
 *
 * @author Philip Levis
 * @author Ben Greenstein
 * @date   August 7 2005
 */
   
interface SerialFrameComm {
  /**
   * Used by the upper layer to request that an interframe delimiter
   * be sent. The lower layer is responsible for the determining the
   * actual byte(s) that must be sent to delimit the frame.
   * @return Returns a error_t code that indicates if the lower layer
   * was able to put an interframe delimiter to serial (SUCCESS) or
   * not (FAIL).
   */
  async command error_t putDelimiter();

  /**
   *  Used by the upper layer to request that a byte of data be sent
   *  over serial.
   *  @param data The byte to be sent
   *  @return Returns an error_t code that indicates if the lower layer
   *  has accepted the byte for sending (SUCCESS) or not (FAIL).
   */
  async command error_t putData(uint8_t data);

  /**
   * Requests that any underlying state associated with send-side frame
   * delimiting or escaping be reset. Used to initialize the lower
   * layer's send path and/or cancel a frame mid-transmission.
   */
  async command void resetSend();

  /**
   * Requests that any underlying state associated with receive-side
   * frame or escaping be reset. Used to initialize the lower layer's
   * receive path and/or cancel a frame mid-reception when sync is lost.
   */
  async command void resetReceive();

  /**
   * Signals the upper layer that an inter-frame delimiter has been 
   * received from the serial connection.
   */
  async event void delimiterReceived();

  /**
   * Signals the upper layer that a byte of data has been received
   * from the serial connection. It passes this byte as a function
   * parameter.  
   * @param data The byte of data that has been received
   * from the serial connection
   */  
  async event void dataReceived(uint8_t data);

  /**
   * Split-phase event to signal when the lower layer has finished writing
   * the last request (either putDelimiter or putData) to serial.
   */
  async event void putDone(); 
}
