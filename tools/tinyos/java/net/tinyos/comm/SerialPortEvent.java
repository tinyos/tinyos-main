//$Id: SerialPortEvent.java,v 1.5 2010-06-29 22:07:41 scipio Exp $

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

package net.tinyos.comm;

public class SerialPortEvent extends java.util.EventObject
{
  public final static int DATA_AVAILABLE = (1<<0);
  public final static int OUTPUT_EMPTY = (1<<1);
  public final static int CTS = (1<<2);
  public final static int DSR = (1<<3);
  public final static int RING_INDICATOR = (1<<4);
  public final static int CARRIER_DETECT = (1<<5);
  public final static int OVERRUN_ERROR = (1<<6);
  public final static int PARITY_ERROR = (1<<7);
  public final static int FRAMING_ERROR = (1<<8);
  public final static int BREAK_INTERRUPT = (1<<9);

  public SerialPort port;
  int eventType;

  public SerialPortEvent( SerialPort _port, int _eventType )
  {
    super(_port);
    port = _port;
    eventType = _eventType;
  }

  public int getEventType()
  {
    return eventType;
  }
}

