//$Id: ByteQueue.java,v 1.5 2010-06-29 22:07:41 scipio Exp $

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

public class ByteQueue
{
  byte buffer[];
  int nbegin;
  int nend;

  int num_free_back()
  {
    return buffer.length - nend;
  }

  void left_justify_into( byte dest[] )
  {
    for( int i=nbegin,j=0; i<nend; i++,j++ )
      dest[j] = buffer[i];
    nend -= nbegin;
    nbegin = 0;
    buffer = dest;
  }

  synchronized void ensure_free( int len )
  {
    if( (nbegin + num_free_back()) < len )
    {
      int newlen = buffer.length * 2;
      int total = available() + len;
      while( newlen < total )
        newlen *= 2;
      left_justify_into( new byte[newlen] );
    }
    else if( num_free_back() < len )
    {
      left_justify_into( buffer );
    }
  }

  public int available()
  {
    return nend - nbegin;
  }

  public void push_back( byte b )
  {
    ensure_free(1);
    buffer[nend++] = b;
  }

  public void push_back( byte b[] )
  {
    push_back( b, 0, b.length );
  }

  public void push_back( byte b[], int off, int len )
  {
    ensure_free( len );
    int bend = off + len;
    while( off < bend )
      buffer[nend++] = b[off++];
  }

  public int pop_front()
  {
    if( available() > 0 )
      return ((int)buffer[nbegin++]) & 255;
    return -1;
  }

  public int pop_front( byte b[] )
  {
    return pop_front( b, 0, b.length );
  }

  public int pop_front( byte b[], int off, int len )
  {
    int n = available();
    if( n > len )
      n = len;
    int bend = off + len;
    while( off < bend )
      b[off++] = buffer[nbegin++];
    return n;
  }

  public ByteQueue()
  {
    this(64);
  }

  public ByteQueue( int initial_buffer_length )
  {
    buffer = new byte[ initial_buffer_length ];
    nbegin = 0;
    nend = 0;
  }
}

