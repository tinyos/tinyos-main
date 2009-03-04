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
   * Convert a capture time (+ symbol offset) to local time.
   *
   * @param   time  capture time
   * @param   localTime capture time converted to local time + offset symbols
   * @param   offset time in symbols (16 us) to add to capture time
   * @return  SUCCESS if conversion was made successfully, FAIL otherwise
   */
  async command error_t convert(uint16_t time, ieee154_timestamp_t *localTime, int16_t offset);

  /**
   * Tells whether the timestamp is valid. On the CC2420 an SFD transition
   * does not necessarily mean that the packet is put in the RXFIFO.
   * This command should return FALSE iff the time between the rising SFD
   * and the falling SFD is too short for the smallest possible frame, i.e.
   * ACK frame (see CC2420 datasheet for details on SFD timing).
   *
   * @param  risingSFDTime capture time of rising SFD
   * @param  fallingSFDTime capture time of falling SFD
   * @return FALSE if time offset is too small for a valid packet
   */
  async command bool isValidTimestamp(uint16_t risingSFDTime, uint16_t fallingSFDTime);
}
