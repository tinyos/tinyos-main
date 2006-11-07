//$Id: NativeSerial.h,v 1.3 2006-11-07 19:30:43 scipio Exp $

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

#include <stdexcept>

class NativeSerial
{
public:
  void setSerialPortParams( int baudrate, int databits, int stopbits, bool parity );
  int getBaudRate();
  int getDataBits();
  int getStopBits();
  bool getParity();

  void notifyOn( int event, bool enable );
  bool isNotifyOn( int event );
  bool waitForEvent();
  bool cancelWait();
  bool didEventOccur( int event );

  void setDTR( bool high );
  void setRTS( bool high );
  bool isDTR();
  bool isRTS();
  bool isCTS();
  bool isDSR();
  bool isRI();
  bool isCD();

  void sendBreak( int millis );

  NativeSerial( const char* portname );
  ~NativeSerial();

  void close();

  int available();
  int read();
  int read( signed char buffer_out[], int off, int len );
  int write( int b );
  int write( const signed char buffer_in[], int off, int len );

  static std::string getTOSCommMap();
};

