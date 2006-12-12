// $Id: SFProtocol.java,v 1.4 2006-12-12 18:23:00 vlahan Exp $

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


package net.tinyos.packet;

import java.io.*;

/**
 * This is the TinyOS 2.x serial forwarder protocol. It is incompatible
 * with the TinyOS 1.x serial forwarder protocol to avoid accidentally
 * mixing TinyOS 1.x and 2.x serial forwarders, applications, etc.
 */
abstract public class SFProtocol extends AbstractSource
{
    // Protocol version, written at connection-open time
    // 2 bytes: first byte is always 'U', second byte is
    // protocol version
    // The actual protocol used will be min(my-version, other-version)
    // current protocols:
    // ' ': initial protocol, no further connection data, packets are
    //      1-byte length followed by n-bytes data. Length must be at least 1.
    final static byte VERSION[] = {'U', ' '};
    int version; // The protocol version we're running (negotiated)

    protected InputStream is;
    protected OutputStream os;

    protected SFProtocol(String name) {
	super(name);
    }
    
    protected void openSource() throws IOException {
	// Assumes streams are open
	os.write(VERSION);
	byte[] partner = readN(2);
	
	// Check that it's a valid header (min version is ' ')
	if (partner[0] != VERSION[0])
	    throw new IOException("protocol error");
	// Actual version is min received vs our version
	version = partner[1] & 0xff;
	int ourversion = VERSION[1] & 0xff;
	if (ourversion < version)
	    version = ourversion;

	// Handle the different protocol versions (currently only one)
	// Any connection-time data-exchange goes here
	switch (version) {
	case ' ':
	    break;
	default:
	    throw new IOException("bad protocol version");
	}
    }
	
    protected byte[] readSourcePacket() throws IOException {
	// Protocol is straightforward: 1 size byte, <n> data bytes
	byte[] size = readN(1);

	if (size[0] == 0)
	    throw new IOException("0-byte packet");
	byte[] read = readN(size[0] & 0xff);
	//Dump.dump("reading", read);
	return read;
    }

    protected byte[] readN(int n) throws IOException {
	byte[] data = new byte[n];
	int offset = 0;

	// A timeout would be nice, but there's no obvious way to
	// write it before java 1.4 (probably some trickery with
	// a thread and closing the stream would do the trick, but...)
	while (offset < n) {
	  int count = is.read(data, offset, n - offset);

	  if (count == -1)
	    throw new IOException("end-of-stream");
	  offset += count;
	}
	return data;
    }

    protected boolean writeSourcePacket(byte[] packet) throws IOException {
	if (packet.length > 255)
	    throw new IOException("packet too long");
	if (packet.length == 0)
	    throw new IOException("packet too short");
	//Dump.dump("writing", packet);
	os.write((byte)packet.length);
	os.write(packet);
	os.flush();
	return true;
    }
}
