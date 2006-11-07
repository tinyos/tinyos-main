// $Id: SFListen.java,v 1.3 2006-11-07 19:30:41 scipio Exp $

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
 * File: ListenServer.java
 *
 * Description:
 * The Listen Server is the heart of the serial forwarder.  Upon
 * instantiation, this class spawns the SerialPortReader and the
 * Multicast threads.  As clients connect, this class spawns
 * ServerReceivingThreads as wells as registers the new connection
 * SerialPortReader.  This class also provides the central
 * point of contact for the GUI, allowing the server to easily
 * be shut down
 *
 * @author <a href="mailto:bwhull@sourceforge.net">Bret Hull</a>
 * @author <a href="mailto:dgay@intel-research.net">David Gay</a>
 */
package net.tinyos.sf;

import java.net.*;
import java.io.*;
import java.util.*;
import net.tinyos.packet.*;

public class SFListen extends Thread implements PacketListenerIF, PhoenixError {
    PhoenixSource source;
    private ServerSocket serverSocket;
    private Vector clients  = new Vector();
    private SerialForwarder sf;

    public SFListen(SerialForwarder sf) {
        this.sf = sf;
    }

    // IO error on packet source, restart it
    // This is essentially the same as the standard resurrection error
    // handler, but sends the error message to a different location
    // (sf.message vs sf.verbose.message)
    public void error(IOException e) {
	if (e.getMessage() != null) {
	    sf.message(e.getMessage());
	}
	sf.message(source.getPacketSource().getName() +
		   " died - restarting");
	try {
	    sleep(5000);
	}
	catch (InterruptedException ie) { }
	
    }

    public void run() {
	try {
	    sf.verbose.message("Listening to " + sf.motecom);

	    source = BuildSource.makePhoenix(sf.motecom, sf.verbose);
	    if (source == null) {
		sf.message("Invalid source " + sf.motecom + ", pick one of:");
		sf.message(BuildSource.sourceHelp());
		return;
	    }
	    source.setPacketErrorHandler(this);
	    source.registerPacketListener(this);
	    source.start();
	
	    // open up our server socket
	    try {
		serverSocket = new ServerSocket(sf.serverPort);
	    }
	    catch (Exception e) {
		sf.message("Could not listen on port: " + sf.serverPort);
		source.shutdown();
		return;
	    }

	    sf.verbose.message("Listening for client connections on port " + sf.serverPort);
	    try {
		for (;;) {
		    Socket currentSocket = serverSocket.accept();
		    SFClient newServicer = new SFClient(currentSocket, sf, this);
		    clients.add(newServicer);
		    newServicer.start();
		}
	    }
	    catch (IOException e) { }
	}
        finally {
	    cleanup();
            sf.verbose.message("--------------------------");
        }
    }

    private void cleanup() {
	shutdownAllSFClients();
	sf.verbose.message("Closing source");
	if (source != null) {
	    source.shutdown();
	}
	sf.verbose.message("Closing socket");
	if (serverSocket != null) {
	    try {
		serverSocket.close();
	    }
	    catch (IOException e) { }
	}
	sf.listenServerStopped();
    }

    private void shutdownAllSFClients() {
        sf.verbose.message("Shutting down all client connections");
        SFClient crrntServicer;
        while (clients.size() != 0) {
	    crrntServicer = (SFClient)clients.firstElement();
	    crrntServicer.shutdown();
	    try {
		crrntServicer.join(1000);
	    }
	    catch (InterruptedException e) {
		e.printStackTrace();
	    }
	}
    }

    public void removeSFClient(SFClient clientS) {
        clients.remove(clientS);
    }

    public void packetReceived(byte[] packet) {
	sf.incrementPacketsRead();
    }

    public void shutdown() {
	try {
	    if (serverSocket != null) {
		serverSocket.close();
	    }
	}
	catch (IOException e) {
	    sf.debug.message("shutdown error " + e);
	}
    }
}
