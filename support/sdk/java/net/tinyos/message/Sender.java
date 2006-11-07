// $Id: Sender.java,v 1.3 2006-11-07 19:30:41 scipio Exp $

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
 * Sender class (send tinyos messages).<p>
 *
 * A sender class provides a simple interface built on Message for
 * sending tinyos messages to a SerialForwarder
 *
 * @version	2, 24 Jul 2003
 * @author	David Gay
 */
public class Sender {
    // If true, dump packet contents that are sent
    private static final boolean VERBOSE = false;

    PhoenixSource sender;

    /**
     * Create a sender talking to PhoenixSource forwarder. The group id of
     * sent packets is not set.
     * @param forwarder PhoenixSource with which we wish to send packets
     */
    public Sender(PhoenixSource forwarder) {
	sender = forwarder;
    }

    /**
     * Send m to moteId via this Sender's SerialForwarder
     * @param moteId message destination
     * @param m message
     * @exception IOException thrown if message could not be sent
     */
    synchronized public void send(int moteId, Message m) throws IOException {
	int amType = m.amType();
	byte[] data = m.dataGet();

	if (amType < 0) {
	    throw new IOException("unknown AM type for message " +
				  m.getClass().getName());
	}

	SerialPacket packet =
	    new SerialPacket(SerialPacket.offset_data(0) + data.length);
	packet.set_header_dest(moteId);
	packet.set_header_type((short)amType);
	packet.set_header_length((short)data.length);
	packet.dataSet(data, 0, packet.offset_data(0), data.length);

	byte[] packetData = packet.dataGet();
	byte[] fullPacket = new byte[packetData.length + 1];
	fullPacket[0] = Serial.TOS_SERIAL_ACTIVE_MESSAGE_ID;
	System.arraycopy(packetData, 0, fullPacket, 1, packetData.length);
	sender.writePacket(fullPacket);
	if (VERBOSE) Dump.dump("sent", fullPacket);
    }
}
