// $Id: ListenRaw.java,v 1.7 2010-06-29 22:07:41 scipio Exp $

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
 * - Neither the name of the copyright holders nor the names of
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
/* Authors: Mike Chen, Philip Levis
 * Last Modified: 7/1/02 (transition to nesC)
 *
 */

/**
 * @author Mike Chen
 * @author Philip Levis
 */



package net.tinyos.tools;

import java.io.*;
import net.tinyos.comm.*;

import net.tinyos.util.*;

public class ListenRaw {
    private static final int PORT_SPEED_TELOS = 115200;
    private static final int PORT_SPEED_MICAZ = 57600;
    private static final int PORT_SPEED_MICA2 = 57600;
    private static final int PORT_SPEED_MICA2DOT = 19200;
    private static final int PORT_SPEED_MICA = 19200;
    private static final int PORT_SPEED_RENE = 19200;
    private static final int PORT_SPEED_IRIS = 57600;
    private static final int PORT_SPEED_SHIMMER = 115200;
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
