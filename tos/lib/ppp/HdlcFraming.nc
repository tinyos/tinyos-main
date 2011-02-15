/* Copyright (c) 2010 People Power Co.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the People Power Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * PEOPLE POWER CO. OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 *
 */

#include "HdlcFraming.h"

/** Interface to support RFC1662-conformant HDLC-like framing of
 * packets for the Point-to-Point Protocol.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */
interface HdlcFraming {
  /** Initiate transmission of a frame of data.
   *
   * This command starts the state machine and begins to transmit the
   * provided data.  RFC1662-required delimeters, HDLC address and
   * control fields, the payload with transparency conversions, and
   * the 16-bit CRC are all added as the frame is transmitted.
   *
   * If this command returns SUCCESS, the sendDone event will be
   * signaled to indicate the ultimate success/failure of the
   * transmission.  The pointer passed to this command will be
   * provided in the event, so components may more easily detect
   * completion of transmissions they initiated.
   *
   * @param data Pointer to a block of data that is to be transmitted.
   *
   * @param len Number of octets in the data block.
   *
   * @param inhibit_accomp If TRUE, send the address and control
   * fields even if the implementing component is configured to
   * suppress them.
   *
   * @return SUCCESS if the frame transmission has begun.  EBUSY if
   * the system is already transmitting a frame.  Other errors if the
   * underlying UART is unable to transmit data.
   */
  command error_t sendFrame (const uint8_t* data,
                             unsigned int len,
                             bool inhibit_accomp);

  /** Notification that the attempt to transmit a frame of data has
   * completed.
   *
   * @note This event is raised by the HdlcFramingC task.
   *
   * @param data The original data pointer provided to sendFrame.
   *
   * @param len The original frame length provided to sendFrame.
   *
   * @param err The disposition of the transmission: SUCCESS if
   * succeeded, other values indicating failure in the state machine
   * or underlying serial transport. */
  event void sendDone (const uint8_t* data,
                       unsigned int len,
                       error_t err);
  
  /** Indicate that a frame has been successfully received.
   *
   * This event is signalled by a task, not within the UART interrupt
   * handler.  The signal is asynchronous to any receivedDelimiter()
   * and receptionError() events.  Regardless of the number of frames
   * received, a subsequent receivedFrame() event shall not occur
   * until after the releaseReceivedFrame() command releases the
   * buffer.
   */
  event void receivedFrame (const uint8_t* data,
                            unsigned int len);

  /** Inform the framer that it can reclaim space used by the given
   * frame.
   *
   * Each received frame must be released before the next frame will
   * be signalled.
   *
   * It is guaranteed that the next receivedFrame() signal will not
   * occur during this call.  This allows the caller to release state
   * after this command without having to worry that the state was
   * overwritten by the next frame.
   *
   * @param data Pointer to the start of a received frame, as provided
   * through the most recent receiveFrame() event.
   */
  command error_t releaseReceivedFrame (const uint8_t* buffer);

  /** Notification that a flag sequence byte has been received.
   *
   * @warning This event is signalled while processing the UART
   * interrupt.  Act quickly and return.
   *
   * It is guaranteed that this event will be signaled prior to the
   * receivedFrame event. */
  async event void receivedDelimiter ();

  /** Notification that an error occurred during frame reception.
   *
   * Note that a reception error does not release the received buffer.
   * The system will resynchronize on the next frame delimiter.
   *
   * @warning This event is signalled while processing the UART
   * interrupt.  Act quickly and return.
   *
   * It is guaranteed that this event will signaled prior to the
   * receivedDelimiter event if an unexpected delimiter is the cause
   * of the error. */
  async event void receptionError (HdlcError_e code);
}
