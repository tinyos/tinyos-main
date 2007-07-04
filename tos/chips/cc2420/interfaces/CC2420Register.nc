/*									tab:4
 * "Copyright (c) 2005 Stanford University. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 * 
 * IN NO EVENT SHALL STANFORD UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF STANFORD UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 * 
 * STANFORD UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND STANFORD UNIVERSITY
 * HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES,
 * ENHANCEMENTS, OR MODIFICATIONS."
 *
 */

/**
 * Interface representing one of the Read/Write registers on the
 * CC2420 radio. The return values (when appropriate) refer to the
 * status byte returned on the CC2420 SO pin. A full list of RW
 * registers can be found on page 61 of the CC2420 datasheet (rev
 * 1.2). Page 25 of the same document describes the protocol for
 * interacting with these registers over the CC2420 SPI bus.
 *
 * @author Philip Levis
 * @version $Revision: 1.1 $ $Date: 2007-07-04 00:37:14 $
 */

#include "CC2420.h"

interface CC2420Register {

  /**
   * Read a 16-bit data word from the register.
   *
   * @param data pointer to place the register value.
   * @return status byte from the read.
   */
  async command cc2420_status_t read(uint16_t* data);

  /**
   * Write a 16-bit data word to the register.
   * 
   * @param data value to write to register.
   * @return status byte from the write.
   */
  async command cc2420_status_t write(uint16_t data);

}
