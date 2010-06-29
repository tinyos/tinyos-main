//$Id: SerialPort.java,v 1.6 2010-06-29 22:07:41 scipio Exp $

package net.tinyos.comm;

/* Copyright (c) 2000-2003 The Regents of the University of California.  
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
 * - Neither the name of the copyright holder nor the names of
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

