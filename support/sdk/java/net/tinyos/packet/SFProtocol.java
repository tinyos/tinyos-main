// $Id: SFProtocol.java,v 1.5 2010-06-29 22:07:41 scipio Exp $

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
