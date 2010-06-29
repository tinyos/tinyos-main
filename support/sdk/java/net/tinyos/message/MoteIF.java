// $Id: MoteIF.java,v 1.5 2010-06-29 22:07:41 scipio Exp $

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
/* Authors:  David Gay  <dgay@intel-research.net>
 *           Intel Research Berkeley Lab
 *
 */

/**
 * @author David Gay <dgay@intel-research.net>
 * @author Intel Research Berkeley Lab
 */

package net.tinyos.message;

import net.tinyos.util.*;
import net.tinyos.packet.*;
import java.io.*;

/**
 * MoteIF provides an application-level Java interface for receiving 
 * messages from, and sending messages to, a mote through a serial port, 
 * TCP connection, or some other means of connectivity. Generally this
 * is used to write Java programs that connect over a TCP or serial port
 * to communicate with a TOSBase or GenericBase mote.
 *
 * The default way to use MoteIF is to create an instance of this class
 * and then register one or more MessageListener objects that will 
 * be invoked when messages arrive. For example:
 * <pre>
 *   MoteIF mif = new MoteIF();
 *   mif.registerListener(new FooMsg(), this);
 *   
 *   // Invoked when a message arrives
 *   public void messageReceived(int toaddr, Message msg) { ... }
 * </pre>
 * The default MoteIF constructor uses the MOTECOM environment
 * variable to determine how the Java application connects to the mote.
 * For example, a MOTECOM setting of "serial@COM1" connects to a base
 * station using the serial port on COM1.
 *
 * You can also send messages through the base station mote using
 * <tt>MoteIF.send()</tt>.
 * 
 * @see net.tinyos.packet.BuildSource
 * @author	David Gay
 */
public class MoteIF {
    /** The destination address for a broadcast. */
    public static final int TOS_BCAST_ADDR = 0xffff;

    protected PhoenixSource source;
    protected Sender sender;
    protected Receiver receiver;

    /**
     * Create a new mote interface to packet source specified using the 
     * MOTECOM environment variable. Status and error messages will
     * be printed to System.err.
     */
    public MoteIF() {
	init(BuildSource.makePhoenix(net.tinyos.util.PrintStreamMessenger.err));
    }

    /**
     * Create a new mote interface to packet source specified using the 
     * MOTECOM environment variable. Status and error messages will
     * be printed to 'messages'.
     *
     * @param messages where to send status messages (null means no messages)
     */
    public MoteIF(Messenger messages) {
	init(BuildSource.makePhoenix(messages));
    }

    /**
     * Create a new mote interface to an arbitrary packet source. The
     * packet source is started if necessary. 
     *
     * @param source packet source to use
     */
    public MoteIF(PhoenixSource source) {
	init(source);
    }

    /**********************************************************************/

    private void init(PhoenixSource source) {
	this.source = source;
	// Start source if it isn't started yet
	try {
	    source.start();
	}
	catch (IllegalThreadStateException e) { }
	try {
	    source.awaitStartup();
	}
	catch (IOException e) { 
	    e.printStackTrace();
	}
	receiver = new Receiver(source);
	sender = new Sender(source);
    }

    /**
     * @return this MoteIF's source 
     */
    public PhoenixSource getSource() {
	return source;
    }

    /**
     * Send m to moteId via this mote interface
     * @param moteId message destination
     * @param m message
     * @exception IOException thrown if message could not be sent
     */
    synchronized public void send(int moteId, Message m) throws IOException {
	sender.send(moteId, m);
    }

    /**
     * Register a listener for given messages type. The message m should be
     * an instance of a subclass of Message (generated by mig). When a
     * message of the corresponding type is received, a new instance of m's
     * class is created with the received message as data. This message is
     * then passed to the given MessageListener.
     * 
     * Note that multiple MessageListeners can be registered for the same
     * message type, and in fact each listener can use a different template
     * type if it wishes (the only requirement is that m.getType() matches
     * the received message). 
     *
     * @param m message template specifying which message to receive
     * @param l listener to which received messages are dispatched
     */
    synchronized public void registerListener(Message m, MessageListener l) {
	receiver.registerListener(m, l);
    }

    /**
     * Deregister a listener for a given message type.
     * @param m message template specifying which message to receive
     * @param l listener to which received messages are dispatched
     */
    synchronized public void deregisterListener(Message m, MessageListener l) {
      receiver.deregisterListener(m, l);
    }
}
