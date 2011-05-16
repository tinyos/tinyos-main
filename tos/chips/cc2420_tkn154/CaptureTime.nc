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
 * $Revision: 1.2 $
 * $Date: 2009-03-04 18:31:00 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

interface CaptureTime 
{

  /** 
   * Converts a platform-specific SFD capture time value (16-bit) into a IEEE
   * 802.15.4 timestamp. The timestamp is a 32-bit value that represents the
   * local time when the *first bit* (chip) of the corresponding frame was
   * transmitted / received (note that on the CC2420 the SFD capture happens 
   * 5 byte (=10 symbols) after the transmission/reception of the first bit).
   *
   * @param   time  capture time 
   * @return  timestamp local time when the frame was transmitted/received
   **/ 
  async command uint32_t getTimestamp(uint16_t SFDCaptureTime); 

  /** 
   * Returns the time interval that the SFD pin was high during a packet
   * transmission/reception. The time is expressed in 802.15.4 symbols.
   *
   * @param  SFDCaptureTime capture time of rising SFD
   * @param  EFDCaptureTime capture time of falling SFD
   */
  async command uint16_t getSFDUptime(uint16_t SFDCaptureTime, uint16_t EFDCaptureTime);
}
