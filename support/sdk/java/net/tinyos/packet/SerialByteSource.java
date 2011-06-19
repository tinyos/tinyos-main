// $Id: SerialByteSource.java,v 1.7 2010-06-29 22:07:41 scipio Exp $

package net.tinyos.packet;

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

import java.io.*;
import net.tinyos.comm.*;

/**
 * A serial port byte source using net.tinyos.comm
 */
public class SerialByteSource extends StreamByteSource implements
    SerialPortListener {
  private SerialPort serialPort;

  private String portName;

  private int baudRate;

  public SerialByteSource(String portName, int baudRate) {
    this.portName = portName;
    this.baudRate = baudRate;
  }

  public void openStreams() throws IOException {
    // if (serialPort == null) {
    try {
      serialPort = new TOSSerial(portName);
    } catch (Exception e) {
      throw new IOException("Could not open " + portName + ": "
          + e.getMessage());
    }
    /*
     * } else { if (!serialPort.open()) { throw new IOException("Could not
     * re-open " + portName); } }
     */

    try {
      // serialPort.setFlowControlMode(SerialPort.FLOWCONTROL_NONE);
      serialPort.setSerialPortParams(baudRate, 8, SerialPort.STOPBITS_1, false);
      serialPort.addListener(this);
      
      serialPort.notifyOn(SerialPortEvent.DATA_AVAILABLE, true);
      serialPort.notifyOn(SerialPortEvent.OUTPUT_EMPTY, true);

      
    } catch (Exception e) {
      serialPort.close();
      throw new IOException("Could not configure " + portName + ": "
          + e.getMessage());
    }

    is = serialPort.getInputStream();
    os = serialPort.getOutputStream();
  }

  public void closeStreams() throws IOException {
    serialPort.close();
    synchronized (sync) {
      sync.notify();
    }
  }

  public String allPorts() {
    /*
     * Enumeration ports = CommPortIdentifier.getPortIdentifiers(); if (ports ==
     * null) return "No comm ports found!";
     * 
     * boolean noPorts = true; String portList = "Known serial ports:\n"; while
     * (ports.hasMoreElements()) { CommPortIdentifier port =
     * (CommPortIdentifier)ports.nextElement();
     * 
     * if (port.getPortType() == CommPortIdentifier.PORT_SERIAL) { portList += "- " +
     * port.getName() + "\n"; noPorts = false; } } if (noPorts) return "No comm
     * ports found!"; else return portList;
     */
    return "Listing available comm ports is no longer supported.";
  }

  Object sync = new Object();

  public byte readByte() throws IOException {
    // On Linux at least, javax.comm input streams are not interruptible.
    // Make them so, relying on the DATA_AVAILABLE serial event.
    synchronized (sync) {
      while (opened && is.available() == 0) {
        try {
          sync.wait();
        } catch (InterruptedException e) {
          close();
          throw new IOException("interrupted");
        }
      }
    }

    if( opened )
    	return super.readByte();
    else
    	throw new IOException("closed");
  }

  public void serialEvent(SerialPortEvent ev) {
    if (ev.getEventType() == SerialPortEvent.DATA_AVAILABLE) {
      synchronized (sync) {
        sync.notify();
      }
    }
  }

  protected void finalize() {
    serialPort.finalize();
  }

}
