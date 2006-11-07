//$Id: SerialPortEvent.java,v 1.3 2006-11-07 19:30:40 scipio Exp $

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

