/*
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
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
