// $Id: Sender.java,v 1.5 2010-06-29 22:07:41 scipio Exp $

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
