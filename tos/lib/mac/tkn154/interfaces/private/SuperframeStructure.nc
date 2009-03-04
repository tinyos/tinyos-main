/* 
 * Copyright (c) 2008, Technische Universitaet Berlin 
 * All rights reserved.
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
 * $Revision: 1.1 $
 * $Date: 2009-03-04 18:31:45 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

 /* A superframe is bounded by beacons and divided into 16 equally-sized slots,
  * which are part of CAP, CFP (GTS) or the inactive period. This interface
  * can be used to determine the various parameters of a superframe,
  * for example the begin of an inactive period would be calculated as
  * "sfStartTime + (numCapSlot + numGtsSlots) * sfSlotDuration"
  **/

interface SuperframeStructure 
{
  /**
   * Returns the absolute time (in symbols) when the superframe started, 
   * i.e. the timestamp of the beacon marking the first slot.
   * 
   * @returns  superframe start time 
   **/
  async command uint32_t sfStartTime(); 

  /**
   * Duration (in symbols) of a single superframe slot.
   * Zero means, the CAP is not valid (no valid beacon was received).
   * 
   * @returns  superframe slot duration
   **/
  async command uint16_t sfSlotDuration();

  /**
   * Number of CAP slots.
   * 
   * @returns  number of CAP slots
   **/
  async command uint8_t numCapSlots();

  /**
   * Number of CAP slots (following the last CAP slot).
   * 
   * @returns  number of CAP slots
   **/
  async command uint8_t numGtsSlots();

  /**
   * Duration of the battery life extension period (in symbols), 
   * Zero means battery life extension is not used (disabled).
   * 
   * @returns  duration of the battery life extension period, 
   * zero means battery life extension is disabled
   **/
  async command uint16_t battLifeExtDuration();     

  /**
   * Returns a pointer to the content of the GTS fields of the 
   * last received/transmitted beacon. 
   * 
   * @returns GTS fields 
   **/
  async command const uint8_t* gtsFields();

  /**
   * The last "guardTime" symbols of CAP/CFP should not be used,
   * i.e. transmission/reception should stop "guardTime" symbols
   * before the actual end of the CAP/CFP.
   * 
   * @returns guard time
   **/
  async command uint16_t guardTime();

  /**
   * Platform-specific representation of "sfStartTime" marking
   * the reception/tranmission time of a beacon.
   * 
   * @returns reception/tranmission time of the beacon
   **/
  async command const ieee154_timestamp_t* sfStartTimeRef();

  /**
   * Tells whether the frame pending bit is set in the header
   * of the beacon frame.
   * 
   * @returns TRUE is frame pending bit in beacon header is set, FALSE otherwise
   **/
  async command bool isBroadcastPending();  
}
