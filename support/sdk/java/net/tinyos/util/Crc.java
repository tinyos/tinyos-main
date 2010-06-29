// $Id: Crc.java,v 1.5 2010-06-29 22:07:42 scipio Exp $

/*									tab:4
 * Copyright (c) 2000-2003 The Regents of the University  of California.  
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
