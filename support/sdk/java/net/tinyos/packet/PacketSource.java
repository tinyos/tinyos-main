// $Id: PacketSource.java,v 1.5 2010-06-29 22:07:41 scipio Exp $

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


/** This interface specifies the generic behaviour of a packet mediator.
    The read and write operations are blocking. 
    Reads and writes may fail (e.g., for communications failure), which
    implicitly closes the mediator. It is not possible to reopen a mediator
    after it is closed (instead, a new mediator should be created).

    The packet byte array must be at least 1 byte long - the first byte
    indicates the type of packet and is used to dispatch to upper layers.

    PacketSources are point-to-point and have "at most once" semantics.
    writePacket should return true only if the packet has been received
    Note that checking this is not possible with some of our broken,
    legacy protocols, and that we will optimistically assume that packets
    sent over reliable links (e.g., tcp/ip socket to a serial forwarder)
    will be reliably delivered by tcp/ip.
 */
package net.tinyos.packet;

import java.io.*;
import net.tinyos.util.*;

public interface PacketSource
{
    /**
     * Get PacketSource name
     * @return the name of this packet source, valid for use with
     * <code>BuildSource.makeSource</code>.
     */
    public String getName();

    /**
     * Open a packet source
     * @param messages A destination for informative messages from the
     *   packet source, or null to discard these.
     * @exception IOException If the source could not be opened
     */
    public void open(Messenger messages) throws IOException;

    /**
     * Close a packet source. Closing a source must force any 
     * running <code>readPacket</code> and <code>writePacket</code>
     * operations to terminate with an IOException
     * @exception IOException Thrown if a problem occured during closing.
     *   The source is considered closed even if thos occurs.
     *   Closing a closed source does not cause this exception
     */
    public void close() throws IOException;

    /**
     * Read a packet
     * @return The packet read (newly allocated). The format is described
     *   above
     * @exception IOException If the source detected a problem. The source
     *   is automatically closed.
     */
    public byte[] readPacket() throws IOException;

    /**
     * Write a packet
     * @param packet The packet to write. The format is decribed above.
     * @return Some packet sources will return false if the packet
     *   could not be written.
     */
    public boolean writePacket(byte[] packet) throws IOException;
}
