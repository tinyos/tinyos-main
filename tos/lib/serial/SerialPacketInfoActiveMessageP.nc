//$Id: SerialPacketInfoActiveMessageP.nc,v 1.4 2006-12-12 18:23:32 vlahan Exp $

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
 * Implementation of the metadata neccessary for a dispatcher to
 * communicate with basic active messages packets over a serial port.
 *
 * @author Philip Levis
 * @author Ben Greenstein
 * @date August 7 2005
 *
 */

#include "Serial.h"

module SerialPacketInfoActiveMessageP {
  provides interface SerialPacketInfo as Info;
}
implementation {

  async command uint8_t Info.offset() {
    return (uint8_t)(sizeof(message_header_t) - sizeof(serial_header_t));
  }
  async command uint8_t Info.dataLinkLength(message_t* msg, uint8_t upperLen) {
    return upperLen + sizeof(serial_header_t);
  }
  async command uint8_t Info.upperLength(message_t* msg, uint8_t dataLinkLen) {
    return dataLinkLen - sizeof(serial_header_t);
  }
}

