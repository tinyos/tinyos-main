/* 
 * Copyright (c) 2008, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Revision -------------------------------------------------------------
 * $Revision: 1.1 $
 * $Date: 2008-06-16 18:00:34 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */


#include <TKN154.h>

interface IEEE154TxBeaconPayload 
{
  /** 
   * Sets the beacon payload portion for all subsequently transmitted beacons.
   * This command replaces the MLME-SET command for the PIB attribute values
   * 0x45 (macBeaconPayload) and 0x46 (macBeaconPayloadLength). The
   * <code>setBeaconPayloadDone()<\code> event will be signalled when the 
   * beacon payload has been set -- until then <code>beaconPayload<\code> must 
   * not be modified.
   *
   * @param beaconPayload   the new beacon payload
   * @param length          the length of the new beacon payload (in byte)
   *
   * @return EBUSY if another transaction is pending, ESIZE if length is too big, 
   * SUCCESS otherwise (and only then the <code>setBeaconPayloadDone<\code> event 
   * will be signalled)
   */
 command error_t setBeaconPayload(void *beaconPayload, uint8_t length);

  /**
   * Signalled in response to a <code>setBeaconPayload()<\code> request.
   * Indicates that the beacon payload has been copied and returns the
   * ownership of the buffer to the next higher layer. 
   * 
   * @param beaconPayload   the <code>beaconPayload<\code> passed in the 
   *                        <code>setBeaconPayload()<\code> command
   * @param length          the <code>length<\code> passed in the 
   *                        <code>setBeaconPayload()<\code> command
   */
 event void setBeaconPayloadDone(void *beaconPayload, uint8_t length);

  /**
   * Returns a pointer to the current beacon payload. 
   * 
   * @return the current beacon payload
   */
 command const void* getBeaconPayload();

  /**
   * Returns the length of the current beacon payload (in byte). 
   * 
   * @return length of the current beacon payload
   */
 command uint8_t getBeaconPayloadLength();

  /**
   * Replaces (overwrites) a portion of the current beacon payload. Whenever
   * possible, to minimize overhead, the next higher layer should prefer this
   * command over the <code>setBeaconPayload()<\code> command.  The
   * <code>modifyBeaconPayloadDone()<\code> event will be signalled when the 
   * beacon payload has been updated -- until then <code>buffer<\code> must 
   * not be modified.
   *
   * @param offset      offset into the current beacon payload
   * @param buffer      the buffer to be written 
   * @param length      the length of the buffer
   *
   * @return EBUSY if another transaction is pending, ESIZE if offset+length is too big, 
   * SUCCESS otherwise (and only then the <code>modifyBeaconPayloadDone<\code> event 
   * will be signalled)
   */
 command error_t modifyBeaconPayload(uint8_t offset, void *buffer, uint8_t bufferLength);

  /**
   * Signalled in response to a <code>modifyBeaconPayload()<\code> request.
   * Indicates that the beacon payload has been updated. 
   * 
   * @param offset        the <code>offset<\code> passed in the 
   *                      <code>modifyBeaconPayload()<\code> command
   * @param buffer        the <code>buffer<\code> passed in the 
   *                      <code>modifyBeaconPayload()<\code> command
   * @param bufferLength  the <code>bufferLength<\code> passed in the 
   *                      <code>modifyBeaconPayload()<\code> command
   */
 event void modifyBeaconPayloadDone(uint8_t offset, void *buffer, uint8_t bufferLength);

  /** 
   * Indicates that a beacon frame will be transmitted "soon" and now is a good
   * time to update the beacon payload (if desired).
   *
   * The usual policy is that (1) this event is signalled before every beacon
   * transmission, and (2) that a subsequent call to <code>setPayload<\code>
   * will update the beacon payload portion of this beacon.  However, 
   * because of tight timing constraints in beacon-enabled mode neither can be
   * guaranteed!
   */
 event void aboutToTransmit();  

  /** 
   * Indicates that a beacon frame has been transmitted (the 
   * <code>getBeaconPayload<\code> command can be used to inspect the
   * beacon payload).
   */
 event void beaconTransmitted();  
}
