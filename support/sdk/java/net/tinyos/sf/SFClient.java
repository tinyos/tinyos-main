// $Id: SFClient.java,v 1.4 2006-12-12 18:23:00 vlahan Exp $

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


/**
 * File: ServerReceivingThread.java
 *
 * Description:
 * The ServerReceivingThread listens for requests
 * from a connected Aggregator Server.  If a data
 * packet is received, it is sent on to the serial
 * port.
 *
 * @author <a href="mailto:bwhull@sourceforge.net">Bret Hull</a>
 * @author <a href="mailto:dgay@intel-research.net">David Gay</a>
 *
 */

package net.tinyos.sf;

import java.net.*;
import java.io.*;
import java.util.*;
import net.tinyos.packet.*;

public class SFClient extends SFProtocol implements Runnable, PacketListenerIF {
    private Thread thread;
    private Socket socket = null;
    private SerialForwarder sf;
    private SFListen listenServer;

    public SFClient(Socket socket, SerialForwarder serialForward,
		    SFListen listenSvr) {
	super("");
	thread = new Thread(this);
        sf = serialForward;
        listenServer = listenSvr;
        this.socket = socket;
        InetAddress addr = socket.getInetAddress();
	name = "client at " + addr.getHostName() +
	    " (" + addr.getHostAddress() + ")";
        sf.debug.message("new " + name);
    }

    protected void openSource() throws IOException {
        is = socket.getInputStream();
        os = socket.getOutputStream();
	super.openSource();
    }
 
    protected void closeSource() throws IOException {
        socket.close();
    }

    private void init() throws IOException {
	sf.incrementClients();
	open(sf);
	listenServer.source.registerPacketListener(this);
    }

    public void shutdown() {
	try {
	    close();
	}
	catch (IOException e) { }
    }

    public void start() {
	thread.start();
    }

    public final void join(long millis) throws InterruptedException {
	thread.join(millis);
    }

    public void run() {
	try {
	    init();
	    readPackets();
	}
	catch (IOException e) { }
	finally {
	    listenServer.source.deregisterPacketListener(this);
	    listenServer.removeSFClient(this);
	    sf.decrementClients();
	    shutdown();
	}
    }

    private void readPackets() throws IOException {
	for (;;) {
	    byte[] packet = readPacket();

	    sf.incrementPacketsWritten();
	    if (!listenServer.source.writePacket(packet))
		sf.verbose.message("write failed");
        }
    }

    public void packetReceived(byte[] packet) {
	try {
	    writePacket(packet);
	}
	catch (IOException e) {
	    shutdown();
	}
    }
}
