//$Id: SFConsoleRenderer.java,v 1.4 2006-12-12 18:23:00 vlahan Exp $

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

package net.tinyos.sf;

public class SFConsoleRenderer implements SFRenderer
{
  boolean statusLine = false;
  boolean listening = false;
  int nclients = 0;
  int nread = 0;
  int nwritten = 0;

  public void SFConsoleRenderer()
  {
  }

  void clearStatus()
  {
    if( statusLine )
    {
      System.out.print("\r                                                                              \r");
      statusLine = false;
    }
  }

  void updateStatus()
  {
    clearStatus();
    System.out.print( (listening?"SF enabled":"SF disabled") + ", "
      + nclients + " " + (nclients==1?"client":"clients") + ", "
      + nread + " " + (nread==1?"packet":"packets") + " read, "
      + nwritten + " " + (nwritten==1?"packet":"packets") + " written"
      + " "
    );
    statusLine = true;
  }

  public void message( String msg )
  {
    clearStatus();
    System.out.println(msg);
    updateStatus();
  }

  public void updatePacketsRead( int n )
  {
    nread = n;
    updateStatus();
  }

  public void updatePacketsWritten( int n )
  {
    nwritten = n;
    updateStatus();
  }

  public void updateNumClients( int n )
  {
    nclients = n;
    updateStatus();
  }

  public void updateListenServerStatus( boolean b )
  {
    listening = b;
    updateStatus();
  }
}

