/*
 * Copyright (c) 2000-2005 The Regents of the University  of California.  
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
 * - Neither the name of the University of California nor the names of
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
 *
 */
/**
 * Interface for receiving time stamp information from the radio.
 * This information is also embedded in packet metadata.
 *
 * @author Jonathan Hui
 * @author Philip Levis
 * @author Joe Polastre
 * @date   October 10 2005
 *
 */

interface RadioTimeStamping
{
  /** 
   * Provides the time at which start of frame delimiter has been
   * transmitted: units are in terms of a 32kHz clock.
   * @param 'message_t* ONE p_msg'
   */
  async event void transmittedSFD( uint16_t time, message_t* p_msg );
  
  /** 
   * Provides the time at which start of frame delimiter was received:
   * units are in terms of a 32kHz clock.  <b>NOTE</b> that receiving
   * a receivedSFD() event does NOT mean that a packet will be
   * received; the transmission may stop, become corrupted, or be
   * filtered by the physical or link layers.  The number of rxSFD
   * events will always be great than or equal to the number of
   * Receive message events.
   */
  async event void receivedSFD( uint16_t time );
}
