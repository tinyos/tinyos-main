// $Id: crc.h,v 1.5 2007-05-07 15:43:59 andreaskoepke Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

#ifndef CRC_H
#define CRC_H

/* We don't want to duplicate this function inside binary components. */
#ifdef NESC_BUILD_BINARY
uint16_t crcByte(uint16_t oldCrc, uint8_t byte);
#else
/*
 * Default CRC function. Some microcontrollers may provide more efficient
 * implementations.
 *
 * This CRC-16 function produces a 16-bit running CRC that adheres to the
 * ITU-T CRC standard.
 *
 * The ITU-T polynomial is: G_16(x) = x^16 + x^12 + x^5 + 1
 * @param crc Running CRC value
 * @param b Byte to "add" to the CRC
 * @return New CRC value
 *
 * To understand how the CRC works and how it relates to the polynomial, read through this
 * loop based implementation.
 */
/*
uint16_t crcByte(uint16_t crc, uint8_t b)
{
  uint8_t i;
  
  crc = crc ^ b << 8;
  i = 8;
  do
    if (crc & 0x8000)
      crc = crc << 1 ^ 0x1021;
    else
      crc = crc << 1;
  while (--i);

  return crc;
}
*/
/**
 * The following implementation computes the same polynomial.  It should be
 * (much) faster on any processor architecture, as it does not involve
 * loops. Unfortunately, I can not yet give a reference to a derivation.
 * 
 * @author Andreas Koepke <koepke@tkn.tu-berlin.de> (porting to tinyos)
 * @author Paul Curtis (pointed out this implementation on the MSP430 yahoo mailing list)
 */

uint16_t crcByte(uint16_t crc, uint8_t b) {
  crc = (uint8_t)(crc >> 8) | (crc << 8);
  crc ^= b;
  crc ^= (uint8_t)(crc & 0xff) >> 4;
  crc ^= crc << 12;
  crc ^= (crc & 0xff) << 5;
  return crc;
}
#endif

#endif
