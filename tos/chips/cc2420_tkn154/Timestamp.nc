/* 
 * Copyright (c) 2008, Technische Universitaet Berlin All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * - Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.  - Redistributions in
 * binary form must reproduce the above copyright notice, this list of
 * conditions and the following disclaimer in the documentation and/or other
 * materials provided with the distribution.  - Neither the name of the
 * Technische Universitaet Berlin nor the names of its contributors may be used
 * to endorse or promote products derived from this software without specific
 * prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *
 * - Revision -------------------------------------------------------------
 * $Revision: 1.1 $ $Date: 2008-06-16 18:02:40 $ 
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */
#include "IEEE802154.h"
interface Timestamp
{
  /**
   * The transmission of a packet has started (the PHY preamble is being 
   * transmitted).
   * Within the event handler the <code>modifyPayload()<\code> command can 
   * be called to modify the contents of the frame's payload.
   *
   * @param frameType     the type of frame (BEACON=0, DATA=1, ACK=2, COMMAND=3)
   * @param msduHandle    for DATA frames the handle associated with the MSDU,
   *                      otherwise undefined
   * @param payload       the MAC payload (e.g. in a DATA frame this is the msdu,
   *                      in a BEACON frame this is the first byte of the SFSpec)
   * @param token         a token to be used as parameter for the
   *                      <code>modifyPayload()<\code> command
   */
  async event void transmissionStarted(uint8_t frameType, uint8_t msduHandle, uint8_t *payload, uint8_t token);

  /**
   * The Start-of-Frame Delimiter of an outgoing frame has been transmitted.
   * Within the event handler the <code>modifyPayload()<\code> command may
   * be called to modify the contents of the frame's payload.
   *
   * @param time          the time when the SFD was transmitted, expressed
   *                      in 15.4 symbols as determined by a call to a T62500hz
   *                      Alarm/Timer.getNow()
   * @param frameType     the type of frame (BEACON=0, DATA=1, ACK=2, COMMAND=3)
   * @param msduHandle    for DATA frames the handle associated with the MSDU,
   *                      otherwise undefined
   * @param payload       the MAC payload (e.g. in a DATA frame this is the msdu,
   *                      in a BEACON frame this is the first byte of the SFSpec)
   * @param token         a token to be used as parameter for the
   *                      <code>modifyPayload()<\code> command
   */
  async event void transmittedSFD(uint32_t time, uint8_t frameType, uint8_t msduHandle, uint8_t *payload, uint8_t token);

  /**
   * Modify (overwrite) the contents of the MAC payload. This command must 
   * only be called in the context of a <code>transmittedSFD()<\code> event and it
   * should return fast. Note: the smaller offset is the faster 
   * <code>transmittedSFD()<\code> must be finished (offset of zero might not work).
   *
   * @param token   the token signalled by <code>transmittedSFD()<\code>
   * @param offset  the offset in the frame's payload to start modifying; 
   *                an offset of zero means the first byte of the MAC payload field
   * @param buf     data to write
   * @param len     number of bytes to write
   */
  async command void modifyMACPayload(uint8_t token, uint8_t offset, uint8_t* buf, uint8_t len);
}
