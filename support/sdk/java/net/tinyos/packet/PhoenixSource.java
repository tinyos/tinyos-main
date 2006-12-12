// $Id: PhoenixSource.java,v 1.4 2006-12-12 18:23:00 vlahan Exp $

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

import net.tinyos.util.*;
import java.io.*;
import java.util.*;

/**
 * A PhoenixSource builds upon a PacketSource to provide the following
 * features:
 * - automatic reading and dispatching of packets (registerPacketListener
 *   and deregisterPacketListener)
 * - automatic source restarting (via setResurrection), off by default
 *
 * PhoenixSources are threads and hence need to be started. PhoenixSources
 * are not PacketSources (direct reads are no longer allowed, open and
 * close is less meaningful with automatic restart). 
 *
 * net.tinyos.message.MoteIF builds upon a PhoenixSource, not a PacketSource.
 *
 * PhoenixSources are built using the makePhoenix methods in BuildSource
 */
public class PhoenixSource extends Thread implements PhoenixError {
    private PacketSource source;
    private Messenger messages;
    private Vector listeners;
    private boolean phoenixLike = true; // does it rise from the ashes?
    private boolean started;
    private PhoenixError errorHandler = this;

    protected void message(String s) {
	if (messages != null)
	    messages.message(s);
    }

    // Wait for thread to start
    public synchronized void awaitStartup() throws IOException {
	while (!started) {
	    try {
		wait();
	    }
	    catch (InterruptedException e) {
		throw new IOException("interrupted");
	    }
	}
    }

    private synchronized void started() {
	started = true;
	notify();
    }

    synchronized private void stopped() {
	started = false;
    }
 
    /**
     * Build PhoenixSources using makePhoenix in BuildSource
     */
    PhoenixSource(PacketSource source, Messenger messages) {
	this.source = source;
	this.messages = messages;
	listeners = new Vector();
    }

    /**
     * Shutdown a PhoenixSource (closes underlying packet source)
     * close errors are NOT reported to the error handler, instead 
     * a simple message is sent
     */
    synchronized public void shutdown() {
	phoenixLike = false;
	try {
	    source.close();
	    interrupt();
	}
	catch (IOException e) {
	    message("close error " + e);
	}
    }

    /**
     * @return This PhoenixSource's PacketSource
     */
    public PacketSource getPacketSource() {
	return source;
    }

    /**
     * Write a packet. Waits for PhoenixSource thread to start
     * @param packet Packet to write (same format as PacketSource)
     * @return false if packet wasn't received (only the serial 
     *   and network packet sources currently provide this indication)
     *   Note that a true result does not guarantee reception
     */
    public boolean writePacket(byte[] packet) throws IOException {
	awaitStartup();
	return source.writePacket(packet);
    }

    /**
     * Register a new packet listener
     * @param listener listener.packetReceived will be invoked for
     *   all packets received on this packet source (see PacketSource
     *   for a description of the packet format). The listener will
     *   be invoked in the context of the PhoenixSource thread.
     */
    public void registerPacketListener(PacketListenerIF listener) {
	listeners.addElement(listener);
    }

    /**
     * Remove a packet listener
     * @param listener Listener to remove (if it was registered twice,
     *   only one entry will be removed)
     */
    public void deregisterPacketListener(PacketListenerIF listener) {
	listeners.remove(listener);
    }

    private void packetDipatchLoop() throws IOException {
	for (;;) {
	    dispatch(source.readPacket());
	}
    }

    private void dispatch(byte[] packet) {
	Enumeration e = listeners.elements();
	while (e.hasMoreElements()) {
	    PacketListenerIF listener = (PacketListenerIF)e.nextElement();
	    listener.packetReceived(packet);
	}
    }

    public void run() {
	while (phoenixLike) {
	    try {
		source.open(messages);
		started();
		packetDipatchLoop();
	    }
	    catch (IOException e) {
		stopped();
		if (phoenixLike)
		    errorHandler.error(e);
	    }
	}
    }

    /** 
     * Set the error handler for this PhoenixSource. When an IOException e
     * is thrown by this PhoenixSource's PacketSource (note that this
     * implicitly closes the PacketSource), errorHandler.error is invoked
     * with e as an argument. When the error handler returns, the
     * PhoenixSource will restart (i.e., reopen the packet source and try
     * to read messages), except if the <code>shutdown</code> method has
     * been called.
     * @param errorHandler The packet source error handler for this
     *    PhoenixSource
     */
    synchronized public void setPacketErrorHandler(PhoenixError errorHandler) {
	this.errorHandler = errorHandler;
    }

    /**
     * Turn resurrection on. This changes the current packet error handler
     * (see <code>setPacketErrorHandler</code>) to one that automatically
     * restarts the packet source after a 2s delay
     */
    public void setResurrection() {
	setPacketErrorHandler(new PhoenixError() {
		public void error(IOException e) {
		    message(source.getName() + " died - restarting");
		    try {
			sleep(2000);
		    }
		    catch (InterruptedException ie) { }
		}
	    });
    }

    // Default error handler
    public void error(IOException e) {
	String msg = source.getName() + " died - exiting (" + e + ")";
	if (messages != null) {
	    message(msg);
	}
	else {
	    // We always try and print this message as we're about to exit.
	    System.err.println(msg);
	}
	System.exit(2);
    }
}
