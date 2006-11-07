// $Id: AbstractSource.java,v 1.3 2006-11-07 19:30:41 scipio Exp $

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
