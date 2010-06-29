// $Id: BuildSource.java,v 1.5 2010-06-29 22:07:41 scipio Exp $

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

import net.tinyos.util.*;

/**
 * This class is where packet-sources are created. It also provides 
 * convenient shortcuts for building PhoenixSources on packet-sources.
 *
 * See PacketSource and PhoenixSource for details on the source behaviours.
 *
 * Most applications will probably use net.tinyos.message.MoteIF with
 * the default source, but those that don't must use BuildSource to obtain
 * a PacketSource.
 *
 * The default source is specified by the MOTECOM environment variable
 * (note that the JNI code for net.tinyos.util.Env must be installed for
 * this to work - see net/tinyos/util/Env.INSTALL for details). When
 * MOTECOM is undefined (or the JNI code for Env.java cannot be found), the
 * packet source is "sf@localhost:9002" (new serial-forwarder, on localhost
 * port 9002).
 *
 * Packet sources can either be specified by strings (when calling
 * <code>makePacketSource</code>, or by calling a specific makeXXX method
 * (e.g., <code>makeSF</code>, <code>makeSerial</code>). There are also
 * makeArgsXXX methods which make a source from its source-args (see below).
 *
 * Packet source strings have the format: <source-name>[@<source-args>],
 * where source-args have reasonable defaults for most sources.
 * The <code>sourceHelp</code> method prints an up-to-date description
 * of known sources and their arguments.
 */
public class BuildSource {
    /**
     * Make a new PhoenixSource over a specified PacketSource
     * Note that a PhoenixSource must be started (<code>start</code> method)
     * before use, and that resurrection is off by default (the default error
     * calls System.exit).
     * @param source The packet-source to use (not null)
     * @param messages Where to send status messages (null for no messages)
     * @return The new PhoenixSource
     */
    public static PhoenixSource makePhoenix(PacketSource source, Messenger messages) {
	return new PhoenixSource(source, messages);
    }

    /**
     * Make a new PhoenixSource over a specified PacketSource
     * Note that a PhoenixSource must be started (<code>start</code> method)
     * before use, and that resurrection is off by default (the default error
     * calls System.exit).
     * @param name The packet-source to use, specified with a packet-source
     *   string
     * @param messages Where to send status messages (null for no messages)
     * @return The new PhoenixSource, or null if name is an invalid source
     */
    public static PhoenixSource makePhoenix(String name, Messenger messages) {
	PacketSource source = makePacketSource(name);
	if (source == null) {
	    return null;
	}
	return new PhoenixSource(source, messages);
    }

    /**
     * Make a new PhoenixSource over the default PacketSource
     * Note that a PhoenixSource must be started (<code>start</code> method)
     * before use, and that resurrection is off by default (the default error
     * calls System.exit).
     * @param messages Where to send status messages (null for no messages)
     * @return The new PhoenixSource
     * @return The new PhoenixSource, or null if the default packet source is
     *   invalid (ie, the MOTECOM environment variable specifies an invalid packet
     *   source)
     */
    public static PhoenixSource makePhoenix(Messenger messages) {
	PacketSource source = makePacketSource();
	if (source == null) {
	    return null;
	}
	return new PhoenixSource(source, messages);
    }

    /**
     * Make the default packet source
     * @return The packet source, or null if it could not be made
     */
    public static PacketSource makePacketSource() {
	return makePacketSource(Env.getenv("MOTECOM"));
    }

    /**
     * Make the specified packet source
     * @param name Name of the packet source, or null for "sf@localhost:9002"
     * @return The packet source, or null if it could not be made
     */
    public static PacketSource makePacketSource(String name) {
	if (name == null)
	    name = "sf@localhost:9002"; // default source

	ParseArgs parser = new ParseArgs(name, "@");
	String source = parser.next();
	String args = parser.next();
	PacketSource retVal = null;
	
	if (source.equals("sf"))
	    retVal =  makeArgsSF(args);
	if (source.equals("serial"))
	    retVal =  makeArgsSerial(args);
	if (source.equals("network"))
	    retVal =  makeArgsNetwork(args);
	if (source.equals("tossim-serial"))
	    retVal =  makeArgsTossimSerial(args);
	if (source.equals("tossim-radio"))
	    retVal =  makeArgsTossimRadio(args);

	return retVal;
    }

    /**
     * Return summary of source string specifications
     */
    public static String sourceHelp() {
	return
"  - sf@HOSTNAME:PORTNUMBER\n" +
"    A serial forwarder.\n" +
"  - serial@SERIALPORT:BAUDRATE\n" +
"    A mote connected to a serial port using the TinyOS 2.0 serial protocol.\n" +
"     BAUDRATE is either a number or a platform name (selects platform's\n" +
"     default baud rate).\n" +
"  - network@HOSTNAME:PORTNUMBER\n" +
"    A mote whose serial port is accessed over the network.\n" +
"  - tossim-serial[@HOSTNAME]\n" +
"    The serial port of tossim node 0.\n" +
"  - tossim-radio[@HOSTNAME]\n" +
"    The radios of tossim nodes.\n" +
"\n" +
"Examples: serial@COM1:mica2, serial@/dev/ttyUSB2:19200, sf@localhost:9000";
    }

    /**
     * Make a serial-forwarder source  (tcp/ip client) from an argument string
     * @param args "hostname:port-number", or null for "localhost:9002"
     * @return The new PacketSource or null for invalid arguments
     */
    public static PacketSource makeArgsSF(String args) {
	if (args == null)
	    args = "localhost:9002";

	ParseArgs parser = new ParseArgs(args, ":");
	String host = parser.next();
	String portS = parser.next();
	if (portS == null)
	    return null;
	int port = Integer.parseInt(portS);

	return makeSF(host, port);
    }

    /**
     * Make a serial-forwarder source (tcp/ip client)
     * @param host hostname
     * @param port port number
     * @return The new PacketSource
     */
    public static PacketSource makeSF(String host, int port) {
	return new SFSource(host, port);
    }

    private static int decodeBaudrate(String rateS) {
	try {
	    int rate = Platform.get(rateS);
	    if (rate == -1)
		rate = Integer.parseInt(rateS);
	    if (rate > 0)
		return rate;
	}
	catch (NumberFormatException e) { }
	return -1;
    }
 

    /**
     * Make a serial-port packet source. Serial packet sources report
     * missing acknowledgements via a false result to writePacket.
     * @param args "COMn[:baudrate]" ("COM1" if args is null)
     *   baudrate is an integer or mote name
     *   The default baudrate is 19200.
     * @return The new packet source, or null if the arguments are invalid
     */
    public static PacketSource makeArgsSerial(String args) {
	if (args == null)
	    args = "COM1";

	ParseArgs parser = new ParseArgs(args, ":");
	String port = parser.next();
	String platformOrBaud = parser.next();
	int baudrate = decodeBaudrate(platformOrBaud);
	if (baudrate < 0)
	    return null;
	return makeSerial(port, baudrate);
    }

    /**
     * Make a serial-port packet source. Serial packet sources report
     * missing acknowledgements via a false result to writePacket.
     * @param port javax.comm serial port name ("COMn:")
     * @param baudrate requested baudrate
     * @return The new packet source
     */ 
    public static PacketSource makeSerial(String port, int baudrate) {
	return new Packetizer("serial@" + port + ":" + baudrate,
			      new SerialByteSource(port, baudrate));
    }

    /**
     * Make a serial-port packet source for a network-accessible serial
     * port. Serial packet sources report missing acknowledgements via a
     * false result to writePacket.
     * @param args "hostname:portnumber" (no default)
     * @return The new packet source, or null if the arguments are invalid
     */
    public static PacketSource makeArgsNetwork(String args) {
	if (args == null)
	    return null;

	ParseArgs parser = new ParseArgs(args, ":,");
	String host = parser.next();
	String portS = parser.next();
	if (portS == null)
	    return null;
	int port = Integer.parseInt(portS);

	return makeNetwork(host, port);
    }

    /**
     * Make a serial-port packet source for a network-accessible serial
     * port. Serial packet sources report missing acknowledgements via a
     * false result to writePacket.
     * @param host hostname of network-accessible serial port
     * @param port tcp/ip port number
     * @return The new packet source
     */
    public static PacketSource makeNetwork(String host, int port) {
	return new Packetizer("network@" + host + ":" + port,
			      new NetworkByteSource(host, port));
    }

    // We create tossim sources using reflection to avoid depending on
    // tossim at compile-time

    /**
     * Make a tossim serial port (node 0) packet source
     * @param args "hostname" ("localhost" for null) (on which tossim runs)
     * @return The new packet source
     */
    public static PacketSource makeArgsTossimSerial(String args) {
	if (args == null)
	    args = "localhost";
	return makeTossimSerial(args);
    }

    /**
     * Make a tossim serial port (node 0) packet source
     * @param host hostname on which tossim runs
     * @return The new packet source
     */
    public static PacketSource makeTossimSerial(String host) {
	return makeTossimSource("TossimSerialSource", host);
    }

    /**
     * Make a tossim radio packet source
     * @param args "hostname" ("localhost" for null) (on which tossim runs)
     * @return The new packet source
     */
    public static PacketSource makeArgsTossimRadio(String args) {
	if (args == null)
	    args = "localhost";
	return makeTossimRadio(args);
    }

    /**
     * Make a tossim radio packet source
     * @param host hostname on which tossim runs
     * @return The new packet source
     */
    public static PacketSource makeTossimRadio(String host) {
	return makeTossimSource("TossimRadioSource", host);
    }

    private static PacketSource makeTossimSource(String name, String host) {
	try {
	    Class[] oneStringArg = new Class[1];
	    oneStringArg[0] = Class.forName("java.lang.String");
	    Object[] args = new Object[1];
	    args[0] = host;

	    Class tossimSource = Class.forName("net.tinyos.sim.packet." + name);
	    return (PacketSource)tossimSource.getConstructor(oneStringArg).newInstance(args);
	}
	catch (Exception e) {
	    System.err.println("Couldn't instantiate tossim packet source");
	    System.err.println("Did you compile tossim?");
	    return null;
	}
    }

//     static class ParseArgs {
// 	String tokens[];
// 	int tokenIndex;

// 	ParseArgs(String s, String delimiterSequence) {
// 	    int count = delimiterSequence.length();
// 	    tokens = new String[count + 1];
// 	    tokenIndex = 0;

// 	    // Fill in the tokens
// 	    int i = 0, lastMatch = 0;
// 	    while (i < count) {
// 		int pos = s.indexOf(delimiterSequence.charAt(i++));

// 		if (pos >= 0) {
// 		    // When we finally find a delimiter, we know where
// 		    // the last token ended
// 		    tokens[lastMatch] = s.substring(0, pos);
// 		    lastMatch = i;
// 		    s = s.substring(pos + 1);
// 		}
// 	    }
// 	    tokens[lastMatch] = s;
// 	}

// 	String next() {
// 	    return tokens[tokenIndex++];
// 	}
//     }

    public static void main(String[] args) {
	System.err.println(sourceHelp());
    }
}
