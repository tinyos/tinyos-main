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
 * Interface representing one of the CC2420 command strobe registers.
 * Writing to one of these registers enacts a command on the CC2420,
 * such as power-up, transmission, or clear a FIFO.
 *
 * @author Philip Levis
 * @version $Revision: 1.4 $ $Date: 2006-12-12 18:23:06 $
 */

#include "CC2420.h"

interface CC2420Strobe {

  /**
   * Send a command strobe to the register. The return value is the
   * CC2420 status register. Table 5 on page 27 of the CC2420
   * datasheet (v1.2) describes the contents of this register.
   * 
   * @return Status byte from the CC2420.
   */
  async command cc2420_status_t strobe();

}
