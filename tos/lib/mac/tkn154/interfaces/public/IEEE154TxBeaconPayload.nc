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
 * $Revision: 1.2 $
 * $Date: 2008-11-25 09:35:09 $
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
   * <tt>setBeaconPayloadDone()<\tt> event will be signalled when the 
   * beacon payload has been set -- until then <tt>beaconPayload<\tt> must 
   * not be modified.
   *
   * @param beaconPayload   the new beacon payload
   * @param length          the length of the new beacon payload (in byte)
   *
   * @return EBUSY if another transaction is pending, ESIZE if length is too big, 
   * SUCCESS otherwise (and only then the <tt>setBeaconPayloadDone<\tt> event 
   * will be signalled)
   */
 command error_t setBeaconPayload(void *beaconPayload, uint8_t length);

  /**
   * Signalled in response to a <tt>setBeaconPayload()<\tt> request.
   * Indicates that the beacon payload has been copied and returns the
   * ownership of the buffer to the next higher layer. 
   * 
   * @param beaconPayload   the <tt>beaconPayload<\tt> passed in the 
   *                        <tt>setBeaconPayload()<\tt> command
   * @param length          the <tt>length<\tt> passed in the 
   *                        <tt>setBeaconPayload()<\tt> command
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
   * command over the <tt>setBeaconPayload()<\tt> command.  The
   * <tt>modifyBeaconPayloadDone()<\tt> event will be signalled when the 
   * beacon payload has been updated -- until then <tt>buffer<\tt> must 
   * not be modified.
   *
   * @param offset      offset into the current beacon payload
   * @param buffer      the buffer to be written 
   * @param length      the length of the buffer
   *
   * @return EBUSY if another transaction is pending, ESIZE if offset+length is too big, 
   * SUCCESS otherwise (and only then the <tt>modifyBeaconPayloadDone<\tt> event 
   * will be signalled)
   */
 command error_t modifyBeaconPayload(uint8_t offset, void *buffer, uint8_t bufferLength);

  /**
   * Signalled in response to a <tt>modifyBeaconPayload()<\tt> request.
   * Indicates that the beacon payload has been updated. 
   * 
   * @param offset        the <tt>offset<\tt> passed in the 
   *                      <tt>modifyBeaconPayload()<\tt> command
   * @param buffer        the <tt>buffer<\tt> passed in the 
   *                      <tt>modifyBeaconPayload()<\tt> command
   * @param bufferLength  the <tt>bufferLength<\tt> passed in the 
   *                      <tt>modifyBeaconPayload()<\tt> command
   */
 event void modifyBeaconPayloadDone(uint8_t offset, void *buffer, uint8_t bufferLength);

  /** 
   * Indicates that a beacon frame will be transmitted "soon" and now is a good
   * time to update the beacon payload (if desired).
   *
   * The usual policy is that (1) this event is signalled before every beacon
   * transmission, and (2) that a subsequent call to <tt>setPayload<\tt>
   * will update the beacon payload portion of this beacon.  However, 
   * because of tight timing constraints in beacon-enabled mode neither can be
   * guaranteed!
   */
 event void aboutToTransmit();  

  /** 
   * Indicates that a beacon frame has been transmitted (the 
   * <tt>getBeaconPayload<\tt> command can be used to inspect the
   * beacon payload).
   */
 event void beaconTransmitted();  
}
