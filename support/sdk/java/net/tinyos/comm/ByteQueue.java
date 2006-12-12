//$Id: ByteQueue.java,v 1.4 2006-12-12 18:22:59 vlahan Exp $

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

