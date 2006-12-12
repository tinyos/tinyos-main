// $Id: StreamByteSource.java,v 1.4 2006-12-12 18:23:00 vlahan Exp $

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

import java.util.*;
import java.io.*;

abstract public class StreamByteSource implements ByteSource
{
    protected InputStream is;
    protected OutputStream os;
    private boolean opened;

    protected StreamByteSource() {
    }

    abstract protected void openStreams() throws IOException;
    abstract protected void closeStreams() throws IOException;

    public void open() throws IOException {
	openStreams();
	opened = true;
    }

    public void close() {
	if (opened) {
	    opened = false;
	    try { 
		os.close(); 
		is.close();
		closeStreams();
	    }
	    catch (Exception e) { }
	}
    }

    public byte readByte() throws IOException {
	int serialByte;

	if (!opened)
	    throw new IOException("not open");

	try {
	    serialByte = is.read();
	}
	catch (IOException e) {
	    serialByte = -1;
	}

	if (serialByte == -1) {
	    close();
	    throw new IOException("read error");
	}

	return (byte)serialByte;
    }

    public void writeBytes(byte[] bytes) throws IOException {
	if (!opened)
	    throw new IOException("not open");

	try {
	    os.write(bytes);
	    os.flush();
	}
	catch (IOException e) {
	    close();
	    throw new IOException("write error");
	}
    }
}
