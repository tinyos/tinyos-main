//$Id: SFConsoleRenderer.java,v 1.5 2010-06-29 22:07:41 scipio Exp $

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

