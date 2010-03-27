//$Id: SerialPacketInfo802_15_4P.nc,v 1.6 2010-03-27 21:52:41 mmaroti Exp $

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
 * Implementation of the metdata necessary for a dispatcher to
 * communicate 802.15.4 message_t packets over a serial port.
 *
 * @author Philip Levis
 * @author Ben Greenstein
 * @date August 7 2005
 *
 */

module SerialPacketInfo802_15_4P {
  provides interface SerialPacketInfo as Info;
}
implementation {
#ifdef PLATFORM_IRIS
  enum {
    HEADER_SIZE = sizeof(rf230packet_header_t),
    FOOTER_SIZE = sizeof(rf230packet_footer_t),
  };
#else
  enum {
    HEADER_SIZE = sizeof(cc2420_header_t),
    FOOTER_SIZE = sizeof(cc2420_footer_t),
  };
#endif

  async command uint8_t Info.offset() {
    return sizeof(message_header_t)-HEADER_SIZE;
  }
  async command uint8_t Info.dataLinkLength(message_t* msg, uint8_t upperLen) {
    return upperLen + HEADER_SIZE + FOOTER_SIZE;
  }
  async command uint8_t Info.upperLength(message_t* msg, uint8_t dataLinkLen) {
    return dataLinkLen - (HEADER_SIZE + FOOTER_SIZE);
  }
}
