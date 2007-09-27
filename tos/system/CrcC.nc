/*                                                                      tab:2
 *
 * "Copyright (c) 2000-2007 The Regents of the University of
 * California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
 * DOCUMENTATION, EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF
 * CALIFORNIA HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT,
 * UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */

/**
 * Wrapper around the CRC-16 primitive to allow computing the CRC
 * value of a byte array.
 *
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 * @author David Moss
 */
 
#include <crc.h>

module CrcC {
  provides interface Crc;
}

implementation {

  /**
   * Compute the CRC-16 value of a byte array.
   *
   * @param   buf A pointer to the buffer over which to compute CRC.
   * @param   len The length of the buffer over which to compute CRC.
   * @return  The CRC-16 value.
   */
  async command uint16_t Crc.crc16(void *buf, uint8_t len) {
    return call Crc.seededCrc16(0, buf, len);
  }
  
  /**
   * Compute a generic CRC-16 using a given seed.  Used to compute CRC's
   * of discontinuous data.
   * 
   * @param startCrc An initial CRC value to begin with
   * @param buf A pointer to a buffer of data
   * @param len The length of the buffer
   * @return The CRC-16 value.
   */
  async command uint16_t Crc.seededCrc16(uint16_t startCrc, void *buf, uint8_t len) {
    uint8_t *tmp = (uint8_t *) buf;
    uint16_t crc;
    for (crc = startCrc; len > 0; len--) {
      crc = crcByte(crc, *tmp++);
    }
    return crc;
  }
}
