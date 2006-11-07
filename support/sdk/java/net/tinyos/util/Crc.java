// $Id: Crc.java,v 1.3 2006-11-07 19:30:41 scipio Exp $

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
package net.tinyos.util;

public class Crc {
    public static int calcByte(int crc, int b) {
      crc = crc ^ (int)b << 8;

      for (int i = 0; i < 8; i++) {
	if ((crc & 0x8000) == 0x8000)
	  crc = crc << 1 ^ 0x1021;
	else
	  crc = crc << 1;
      }

      return crc & 0xffff;
    }

    public static int calc(byte[] packet, int index, int count) {
	int crc = 0;
	int i;

	while (count > 0) {
	    crc = calcByte(crc, packet[index++]);
	    count--;
	}
	return crc;
    }

    public static int calc(byte[] packet, int count) {
	return calc(packet, 0, count);
    }

    public static void set(byte[] packet) {
        int crc = Crc.calc(packet, packet.length - 2);

        packet[packet.length - 2] = (byte) (crc & 0xFF);
        packet[packet.length - 1] = (byte) ((crc >> 8) & 0xFF);
    }

    public static void main(String[] args) {
	byte[] ia = new byte[args.length];

	for (int i = 0; i < args.length; i++)
	    try {
		ia[i] = Integer.decode(args[i]).byteValue();
	    } catch (NumberFormatException e) { }
	System.out.println(Integer.toHexString(calc(ia, ia.length)));
    }
}
