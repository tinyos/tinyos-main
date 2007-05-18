//$Id: SerialPort.java,v 1.5 2007-05-18 18:27:03 rincon Exp $

package net.tinyos.comm;

/* "Copyright (c) 2000-2003 The Regents of the University of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

//@author Cory Sharp <cssharp@eecs.berkeley.edu>


import java.io.*;

public interface SerialPort
{
  public static final int STOPBITS_1 = 1;
  public static final int STOPBITS_2 = 2;
  public static final int STOPBITS_1_5 = 3;

  /*
  public static final int FLOWCONTROL_NONE = 0;
  public static final int FLOWCONTROL_RTSCTS_IN = 1;
  public static final int FLOWCONTROL_RTSCTS_OUT = 2;
  public static final int FLOWCONTROL_XONXOFF_IN = 4;
  public static final int FLOWCONTROL_XONXOFF_OUT = 8;
  */

  public InputStream getInputStream() throws IOException;
  public OutputStream getOutputStream() throws IOException;

  public boolean open();
  public void close();
  public void finalize();
  
  public void setSerialPortParams( 
    int baudrate, int dataBits, int stopBits, boolean parity )
    throws UnsupportedCommOperationException;
  public int getBaudRate();
  public int getDataBits();
  public int getStopBits();
  public boolean getParity();

  public void sendBreak( int millis );

  /*
  public void setFlowControlMode( int flowcontrol )
    throws UnsupportedCommOperationException;
  public int getFlowControlMode();
  */

  public void setDTR( boolean dtr );
  public void setRTS( boolean rts );
  public boolean isDTR();
  public boolean isRTS();
  public boolean isCTS();
  public boolean isDSR();
  public boolean isRI();
  public boolean isCD();

  public void addListener( SerialPortListener l );
  public void removeListener( SerialPortListener l );
  public void notifyOn( int serialEvent, boolean enable );
}

