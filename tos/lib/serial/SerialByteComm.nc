//$Id: SerialByteComm.nc,v 1.3 2006-11-07 19:31:20 scipio Exp $

/* "Copyright (c) 2000-2005 The Regents of the University of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

/**
 * A basic byte-level interface to a serial port.
 *
 * @author David Gay
 * @author Philip Levis
 * @author Ben Greenstein
 * @date August 7 2005
 *
 */

interface SerialByteComm {

  /** 
   * Put a single byte to the serial port.
   * @param data The byte to send to the serial port.
   * @return Returns an error_t code indicating whether this byte was
   * successfully put (SUCCESS) or not (FAIL).
   */
  async command error_t put(uint8_t data);

  /** 
   * Receive a single byte from the serial port.
   * @param data The byte that has been received from the serial port.
   */
  async event void get(uint8_t data);

  /** 
   * Split phase event to indicate that the last put request
   * has completed.
   */
  async event void putDone();
}
