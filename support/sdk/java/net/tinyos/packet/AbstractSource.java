// $Id: AbstractSource.java,v 1.5 2010-06-29 22:07:41 scipio Exp $

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
import java.util.*;
import net.tinyos.util.*;
//import net.tinyos.message.*;

/**
 * Provide a standard, generic implementation of PacketSource. Subclasses
 * need only implement low-level open and close operations, and packet
 * reading and writing. This class provides the automatic close-on-error
 * functionality, general error checking, and standard messages.
 */
abstract public class AbstractSource implements PacketSource
{
    protected String name;
    protected boolean opened = false;
    protected Messenger messages;

    protected void message(String s) {
	if (messages != null)
	    messages.message(s);
    }

    protected AbstractSource(String name) {
	this.name = name;
    }

    public String getName() {
	return name;
    }

    synchronized public void open(Messenger messages) throws IOException {
	if (opened)
	    throw new IOException("already open");
	this.messages = messages;
	openSource();
	opened = true;
    }

    synchronized public void close() throws IOException {
	if (opened) {
	    opened = false;
	    closeSource();
	}
    }

    protected void failIfClosed() throws IOException {
	if (!opened)
	    throw new IOException("closed");
    }

    public byte[] readPacket() throws IOException {
	failIfClosed();

	try {
	    return check(readSourcePacket());
	}
	catch (IOException e) {
	    close();
	    throw e;
	}
    }

    synchronized public boolean writePacket(byte[] packet) throws IOException {
	failIfClosed();

	try {
	    return writeSourcePacket(check(packet));
	}
	catch (IOException e) {
	    close();
	    throw e;
	}
    }

    protected byte[] check(byte[] packet) throws IOException {
	return packet;
    }

    // Implementation interfaces
    abstract protected void openSource() throws IOException;
    abstract protected void closeSource() throws IOException;
    abstract protected byte[] readSourcePacket() throws IOException;
    protected boolean writeSourcePacket(byte[] packet) throws IOException {
	// Default writer swallows packets
	return true;
    }
}
