// $Id: ListenRaw.java,v 1.6 2008-06-18 19:04:45 sallai Exp $

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
/* Authors: Mike Chen, Philip Levis
 * Last Modified: 7/1/02 (transition to nesC)
 *
 */

/**
 * @author Mike Chen
 * @author Philip Levis
 */



package net.tinyos.tools;

import java.util.*;
import java.io.*;
import net.tinyos.comm.*;

import net.tinyos.util.*;

public class ListenRaw {
    private static String CLASS_NAME = "net.tinyos.tools.ListenRaw";
    private static final int MAX_MSG_SIZE = 40;
    private static final int PORT_SPEED_TELOS = 115200;
    private static final int PORT_SPEED_MICAZ = 57600;
    private static final int PORT_SPEED_MICA2 = 57600;
    private static final int PORT_SPEED_MICA2DOT = 19200;
    private static final int PORT_SPEED_MICA = 19200;
    private static final int PORT_SPEED_RENE = 19200;
    private static final int PORT_SPEED_IRIS = 57600;
    private static final int PORT_SPEED_SHIMMER = 115200;
    private static final int LENGTH_OFFSET = 4;
    private int packetLength;
    private int portSpeed;

    private SerialPort port;
    private String portName;
    private InputStream in;
    private OutputStream out;

    public ListenRaw(String portName, int portSpeed) {
	this.portName = portName;
	this.portSpeed = portSpeed;
    }


    public void open() throws IOException, UnsupportedCommOperationException {
	System.out.println("Opening port " + portName);
	port = new TOSSerial(portName);
	in = port.getInputStream();
	out = port.getOutputStream();

	//port.setFlowControlMode(SerialPort.FLOWCONTROL_NONE);
	// These are the mote UART parameters
	port.setSerialPortParams(portSpeed, 8, SerialPort.STOPBITS_1, false);
	printPortStatus();
	System.out.println();
    }

    private void printPortStatus() {
	System.out.println(" baud rate: " + port.getBaudRate());
	System.out.println(" data bits: " + port.getDataBits());
	System.out.println(" stop bits: " + port.getStopBits());
	System.out.println(" parity:    " + port.getParity());
    }

    public void read() throws IOException {
	int i;
	int count = 0;
	byte[] packet = new byte[MAX_MSG_SIZE];

	while ((i = in.read()) != -1) {
	    if (i == 0x7e) {
		System.out.println();
	    }
	    Dump.printByte(System.out, i);
	}
    }

    private static void printUsage() {
	System.err.println("usage: java net.tinyos.tools.ListenRaw [options] <port>");
	System.err.println("options are:");
	System.err.println("  -h, --help:    usage help");
	System.err.println("  -p:            print available ports");
	System.err.println("  -telos:        Telos ("+PORT_SPEED_TELOS+" bps)");
	System.err.println("  -micaz:        Mica2 ("+PORT_SPEED_MICAZ+" bps) [default]");
	System.err.println("  -mica2:        Mica2 ("+PORT_SPEED_MICA2+" bps) [default]");
	System.err.println("  -mica2dot:     Mica2Dot ("+PORT_SPEED_MICA2DOT+" bps)");
	System.err.println("  -mica:         Mica ("+PORT_SPEED_MICA+" bps)");
	System.err.println("  -rene:         Rene ("+PORT_SPEED_RENE+" bps)");
	System.err.println("  -iris:         Iris ("+PORT_SPEED_IRIS+" bps) [default]");
	System.err.println("  -shimmer:      Shimmer ("+PORT_SPEED_SHIMMER+" bps)");
	System.exit(-1);
    }


    public static void main(String args[]) {
	int speed = PORT_SPEED_MICA2;

	if ((args.length < 1) || (args.length > 3)) {
	    printUsage();
	}

	for (int i = 0; i < args.length; i++) {
	    if (args[i].equals("-h") || args[i].equals("--help")) {
		printUsage();
	    }
	    if (args[i].equals("-telos")) {
	        speed = PORT_SPEED_TELOS;
	    }
	    if (args[i].equals("-micaz")) {
	        speed = PORT_SPEED_MICAZ;
	    }
	    if (args[i].equals("-mica2")) {
	        speed = PORT_SPEED_MICA2;
	    }
	    if (args[i].equals("-mica2dot")) {
	        speed = PORT_SPEED_MICA2DOT;
	    }
	    if (args[i].equals("-mica")) {
	        speed = PORT_SPEED_MICA;
	    }
	    if (args[i].equals("-rene")) {
	        speed = PORT_SPEED_RENE;
	    }
	    if (args[i].equals("-iris")) {
	        speed = PORT_SPEED_IRIS;
	    }
	    if (args[i].equals("-shimmer")) {
	        speed = PORT_SPEED_SHIMMER;
	    }
	}

	if (args[args.length - 1].charAt(0) == '-') {
	    return; // No port specified
	}

	ListenRaw reader = new ListenRaw(args[args.length - 1], speed);
	try {
	    reader.open();
	}
	catch (Exception e) {
	    e.printStackTrace();
	}

	try {
	    reader.read();
	}
	catch (Exception e) {
	    e.printStackTrace();
	}
    }
}
