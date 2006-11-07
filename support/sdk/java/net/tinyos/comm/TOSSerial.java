//$Id: TOSSerial.java,v 1.3 2006-11-07 19:30:40 scipio Exp $

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

import java.io.*;
import java.util.*;
import java.util.regex.*;

public class TOSSerial extends NativeSerial implements SerialPort
{
  class EventDispatcher extends Thread
  {
    boolean m_run;

    public EventDispatcher()
    {
      m_run = true;
    }

    void dispatch_event( int event )
    {
      if( didEventOccur(event) )
      {
	SerialPortEvent ev = new SerialPortEvent( TOSSerial.this, event );
        synchronized(m_listeners) {
          Iterator i = m_listeners.iterator();
          while( i.hasNext() )
            ((SerialPortListener)i.next()).serialEvent( ev );
        }
      }
    }

    public void run()
    {
      while( m_run )
      {
	if( waitForEvent() )
	{
	  if( m_run )
	  {
	    dispatch_event( SerialPortEvent.BREAK_INTERRUPT );
	    dispatch_event( SerialPortEvent.CARRIER_DETECT );
	    dispatch_event( SerialPortEvent.CTS );
	    dispatch_event( SerialPortEvent.DATA_AVAILABLE );
	    dispatch_event( SerialPortEvent.DSR );
	    dispatch_event( SerialPortEvent.FRAMING_ERROR );
	    dispatch_event( SerialPortEvent.OVERRUN_ERROR );
	    dispatch_event( SerialPortEvent.OUTPUT_EMPTY );
	    dispatch_event( SerialPortEvent.PARITY_ERROR );
	    dispatch_event( SerialPortEvent.RING_INDICATOR );
	  }
	}
      }
    }

    public void close()
    {
      m_run = false;
      cancelWait();
    }
  }


  class SerialInputStream extends InputStream
  {
    ByteQueue bq = new ByteQueue(128);

    protected void gather()
    {
      int navail = TOSSerial.this.available();
      if( navail > 0 )
      {
        byte buffer[] = new byte[navail];
        bq.push_back( buffer, 0, TOSSerial.this.read( buffer, 0, navail ) );
      }
    }

    public int read()
    {
      gather();
      return bq.pop_front();
    }

    public int read( byte[] b )
    {
      gather();
      return bq.pop_front(b);
    }

    public int read( byte[] b, int off, int len )
    {
      gather();
      return bq.pop_front(b,off,len);
    }

    public int available()
    {
      gather();
      return bq.available();
    }
  }


  class SerialOutputStream extends OutputStream
  {
    public void write( int b )
    {
      TOSSerial.this.write(b);
    }

    public void write( byte[] b )
    {
      TOSSerial.this.write(b,0,b.length);
    }

    public void write( byte[] b, int off, int len )
    {
      int nwritten = 0;
      while( nwritten < len )
	nwritten += TOSSerial.this.write( b, nwritten, len-nwritten );
    }
  }


  SerialInputStream m_in;
  SerialOutputStream m_out;
  Vector m_listeners = new Vector();
  EventDispatcher m_dispatch;

  static String map_portname( String mapstr, String portname )
  {
    // mapstr is of the form "from1=to1:from2=to2"

    // If "from", "to", and "portname" all end port numbers, then the ports in
    // "from" and "to" are used as a bias for the port in "portname", appended
    // to the "to" string (without its original terminating digits).  If more
    // than one port mapping matches, the one with the smallest non-negative
    // port number wins.

    // For instance, if
    //   mapstr="com1=COM1:com10=\\.\COM10"
    // then
    //   com1 => COM1
    //   com3 => COM3
    //   com10 => \\.\COM10
    //   com12 => \\.\COM12
    // or if
    //   mapstr="com1=/dev/ttyS0:usb1=/dev/ttyS100"
    // then
    //   com1 => /dev/ttyS0
    //   com3 => /dev/ttyS2
    //   usb1 => /dev/ttyS100
    //   usb3 => /dev/ttyS102

    String maps[] = mapstr.split(":");
    Pattern pkv = Pattern.compile("(.*?)=(.*?)");
    Pattern pnum = Pattern.compile("(.*\\D)(\\d+)");

    Matcher mport = pnum.matcher(portname);
    int match_distance = -1;
    String str_port_to = null;

    for( int i=0; i<maps.length; i++ )
    {
      Matcher mkv = pkv.matcher( maps[i] );
      if( mkv.matches() )
      {
	Matcher mfrom = pnum.matcher( mkv.group(1) );
	Matcher mto = pnum.matcher( mkv.group(2) );
	if( mfrom.matches() && mto.matches() && mport.matches()
	    && mfrom.group(1).equalsIgnoreCase( mport.group(1) )
	  )
	{
	  int nfrom = Integer.parseInt( mfrom.group(2) );
	  int nto = Integer.parseInt( mto.group(2) );
	  int nport_from = Integer.parseInt( mport.group(2) );
	  int nport_to = nport_from - nfrom + nto;
	  int ndist = nport_from - nfrom;

	  if( (ndist >= 0) && ((ndist < match_distance) || (match_distance == -1)) )
	  {
	    match_distance = ndist;
	    str_port_to = mto.group(1) + nport_to;
	  }
	}
	else if( mkv.group(1).equalsIgnoreCase( portname ) )
	{
	  match_distance = 0;
	  str_port_to = mkv.group(2);
	}
      }
    }

    return (str_port_to == null) ? portname : str_port_to;
  }

  public TOSSerial( String portname )
  {
    super( map_portname( NativeSerial.getTOSCommMap(), portname ) );
    m_in = new SerialInputStream();
    m_out = new SerialOutputStream();
    m_dispatch = new EventDispatcher();
    m_dispatch.start();
  }

  public void addListener( SerialPortListener l )
  {
    synchronized(m_listeners) {
      if( !m_listeners.contains(l) )
        m_listeners.add(l);
    }
  }

  public void removeListener( SerialPortListener l )
  {
    synchronized(m_listeners) {
      m_listeners.remove(l);
    }
  }

  public InputStream getInputStream()
  {
    return m_in;
  }

  public OutputStream getOutputStream()
  {
    return m_out;
  }

  public void close()
  {
    if( m_dispatch != null )
      m_dispatch.close();

    try { if( m_dispatch != null ) m_dispatch.join(); }
    catch( InterruptedException e ) { }

    super.close();

    try
    {
      if( m_in != null )
	m_in.close();

      if( m_out != null )
	m_out.close();
    }
    catch( IOException e )
    {
    }

    m_dispatch = null;
    m_in = null;
    m_out = null;
  }

  protected void finalize()
  {
    // Be careful what you call here. The object may never have been
    // created, so the underlying C++ object may not exist, and there's
    // insufficient guarding to avoid a core dump. If you call other
    // methods than super.close() or super.finalize(), be sure to
    // add an if (swigCptr != 0) guard in NativeSerial.java.
    System.out.println("Java TOSSerial finalize");
    close();
    super.finalize();
  }
}

