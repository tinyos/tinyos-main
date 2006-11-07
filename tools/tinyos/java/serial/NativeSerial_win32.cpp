//$Id: NativeSerial_win32.cpp,v 1.3 2006-11-07 19:30:43 scipio Exp $

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

#include <windows.h>
#include <stdexcept>
#include <sstream>
#include <iostream>

#include "NativeSerialEnums.h"
using namespace NativeSerialEnums;


class comm_port_error : public std::runtime_error
{
  public:
    comm_port_error( const char* msg ): std::runtime_error(msg) { }
};


class W32Overlapped
{
public:
  OVERLAPPED o;

  W32Overlapped()
  {
    o.hEvent = CreateEvent( NULL, FALSE, FALSE, NULL );
    o.Internal = 0;
    o.InternalHigh = 0;
    o.Offset = 0;
    o.OffsetHigh = 0;
    if( o.hEvent == NULL )
      throw comm_port_error("could not create Overlapped event");
  }

  ~W32Overlapped()
  {
    if( o.hEvent != NULL )
      CloseHandle( o.hEvent );
  }
};


class NativeSerial
{
private:

  HANDLE hComm;
  W32Overlapped oread;
  W32Overlapped owrite;
  W32Overlapped owait;
  W32Overlapped oavail;

  std::string m_portname;
  int m_events_in;
  int m_events_out;
  bool m_dtr;
  bool m_rts;

protected:

  void test_comm_success( bool success, const char* extra_msg )
  {
    if( !success )
    {
      DWORD err = GetLastError();
      std::ostringstream os;
      char msg[1024];
      FormatMessage( FORMAT_MESSAGE_FROM_SYSTEM, NULL, err, 0, msg, sizeof(msg), NULL );
      os << "Error " << err << ".\n   " << msg;
      if( extra_msg != NULL ) { os << "   in " << extra_msg; }
      throw comm_port_error(os.str().c_str());
    }
  }

  DCB get_comm_state()
  {
    DCB dcb;
    test_comm_success( GetCommState( hComm, &dcb ), "get_comm_state.GetCommState" );
    return dcb;
  }

  DWORD get_modem_status()
  {
    DWORD status = 0;
    test_comm_success( GetCommModemStatus( hComm, &status ), "get_modem_stauts.GetCommModemStatus" );
    return status;
  }

  static DWORD map_events_to_win32( int event )
  {
    DWORD ev = 0;
    if( event & DATA_AVAILABLE ) ev |= EV_RXCHAR;
    if( event & OUTPUT_EMPTY ) ev |= EV_TXEMPTY;
    if( event & CTS ) ev |= EV_CTS;
    if( event & DSR ) ev |= EV_DSR;
    if( event & RING_INDICATOR ) ev |= EV_RING;
    if( event & CARRIER_DETECT ) ev |= EV_RLSD;
    if( event & OVERRUN_ERROR ) ev |= EV_ERR;
    if( event & PARITY_ERROR ) ev |= EV_ERR;
    if( event & FRAMING_ERROR ) ev |= EV_ERR;
    if( event & BREAK_INTERRUPT ) ev |= EV_BREAK;
    return ev;
  }

  static int map_events_from_win32( DWORD ev, DWORD errors )
  {
    int event = 0;
    if( ev & EV_RXCHAR ) event |= DATA_AVAILABLE;
    if( ev & EV_TXEMPTY ) event |= OUTPUT_EMPTY;
    if( ev & EV_CTS ) event |= CTS;
    if( ev & EV_DSR ) event |= DSR;
    if( ev & EV_RING ) event |= RING_INDICATOR;
    if( ev & EV_RLSD ) event |= CARRIER_DETECT;
    if( ev & EV_ERR )
    {
      if( errors & CE_BREAK ) event |= BREAK_INTERRUPT;
      if( errors & CE_FRAME ) event |= FRAMING_ERROR;
      if( errors & CE_IOE ) throw comm_port_error("Win32 Comm IO Error");
      if( errors & CE_MODE ) throw comm_port_error("Win32 Comm Invalid Mode");
      if( errors & CE_OVERRUN ) event |= OVERRUN_ERROR;
      if( errors & CE_RXOVER ) event |= OVERRUN_ERROR; //?? okay
      if( errors & CE_RXPARITY ) event |= PARITY_ERROR;
      if( errors & CE_TXFULL ) event |= OVERRUN_ERROR; //?? okay
    }
    if( ev & EV_BREAK ) event |= BREAK_INTERRUPT;
    return event;
  }

public:

  void setSerialPortParams( int baudrate, int databits, int stopbits, bool parity )
  {
    DCB dcb = get_comm_state();
    dcb.BaudRate = baudrate;
    dcb.ByteSize = databits;
    switch( stopbits )
    {
      case 0: dcb.StopBits = ONE5STOPBITS; break;
      case 2: dcb.StopBits = TWOSTOPBITS; break;
      default: dcb.StopBits = ONESTOPBIT;
    }
    dcb.Parity = (parity ? 1 : 0);
    test_comm_success( SetCommState( hComm, &dcb ), "set_params.SetCommState" );
  }

  int getBaudRate()
  {
    int baud_rate = get_comm_state().BaudRate;
    switch( baud_rate )
    {
      case CBR_110:    return 110;
      case CBR_300:    return 300;
      case CBR_600:    return 600;
      case CBR_1200:   return 1200;
      case CBR_2400:   return 2400;
      case CBR_4800:   return 4800;
      case CBR_9600:   return 9600;
      case CBR_14400:  return 14400;
      case CBR_19200:  return 19200;
      case CBR_38400:  return 38400;
      case CBR_56000:  return 56000;
      case CBR_57600:  return 57600;
      case CBR_115200: return 115200;
      case CBR_128000: return 128000;
      case CBR_256000: return 256000;
    }
    return baud_rate;
  }

  int getDataBits()
  {
    return get_comm_state().ByteSize;
  }

  int getStopBits()
  {
    switch( get_comm_state().StopBits )
    {
      case ONESTOPBIT: return 0;
      case ONE5STOPBITS: return 1;
      case TWOSTOPBITS: return 2;
    }
    return 0;
  }

  bool getParity()
  {
    return (get_comm_state().fParity != 0);
  }

  int read( signed char* buffer, int off, int len )
  {
    DWORD nread = 0;
    if( !ReadFile( hComm, buffer+off, len, &nread, &oread.o ) )
    {
      test_comm_success( GetLastError() == ERROR_IO_PENDING, "read.WriteFile" );
      DWORD rvwait = WaitForSingleObject(oread.o.hEvent,INFINITE);
      test_comm_success( rvwait != WAIT_FAILED, "read.WaitForSingleObject" );
      if( rvwait != WAIT_OBJECT_0 )
	return 0;
      test_comm_success( GetOverlappedResult(hComm,&oread.o,&nread,TRUE), "read.GetOverlappedresult" );
    }
    return nread;
  }

  int write( const signed char* buffer, int off, int len )
  {
    DWORD nread = 0;
    DWORD nwritten = 0;
    if( !WriteFile( hComm, buffer+off, len, &nwritten, &owrite.o ) )
    {
      test_comm_success( GetLastError() == ERROR_IO_PENDING, "write.WriteFile" );
      DWORD rvwait = WaitForSingleObject(owrite.o.hEvent,INFINITE);
      test_comm_success( rvwait != WAIT_FAILED, "write.WaitForSingleObject" );
      if( rvwait != WAIT_OBJECT_0 )
	return 0;
      test_comm_success( GetOverlappedResult(hComm,&owrite.o,&nwritten,TRUE), "write.GetOverlappedresult" );
    }
    return nwritten;
  }

  int read()
  {
    signed char byte;
    return (read(&byte,0,1) > 0) ? ((unsigned char)byte) : -1;
  }

  int write( int b )
  {
    signed char byte = b;
    return write( &byte, 0, 1 );
  }

  int available()
  {
    COMSTAT cs;
    DWORD errors = 0;
    test_comm_success( ClearCommError( hComm, &errors, &cs ), "available.ClearCommError" );
    return cs.cbInQue;
  }

  void notifyOn( int event, bool enable )
  {
    if( enable )
      m_events_in |= event;
    else
      m_events_in &= ~event;
    test_comm_success( SetEvent( owait.o.hEvent ), "enable_event.SetEvent" );
  }

  bool isNotifyOn( int event )
  {
    return (m_events_in & event) != 0;
  }

  bool waitForEvent()
  {
    DWORD evMaskIn = map_events_to_win32( m_events_in );
    DWORD evMaskOut = 0;
    m_events_out = 0;
    if( evMaskIn != 0 )
    {
      test_comm_success( SetCommMask( hComm, evMaskIn ), "wait_for_event.SetCommMask" );
      if( !WaitCommEvent(hComm,&evMaskOut,&owait.o) )
      {
	DWORD nbytes = 0;
	test_comm_success( GetLastError() == ERROR_IO_PENDING, "wait_for_event.WaitCommEvent" );
	DWORD rvwait = WaitForSingleObject(owait.o.hEvent,INFINITE);
	test_comm_success( rvwait != WAIT_FAILED, "wait_for_event.WaitForSingleObject" );
	if( rvwait != WAIT_OBJECT_0 )
	  return 0;
	test_comm_success( GetOverlappedResult(hComm,&owait.o,&nbytes,TRUE), "write.GetOverlappedresult" );
      }
      //evMaskOut &= evMaskIn;
      DWORD errors = 0;
      test_comm_success( ClearCommError( hComm, &errors, NULL ), "wait_for_event.ClearCommError" );
      m_events_out = map_events_from_win32( evMaskOut, errors );
    }
    else
    {
      test_comm_success( ResetEvent( owait.o.hEvent ), "wait_for_event.ResetEvent" );
      DWORD rvwait = WaitForSingleObject( owait.o.hEvent, INFINITE );
      test_comm_success( rvwait != WAIT_FAILED, "wait_for_event.WaitForSingleObject" );
    }
    return (m_events_out != 0);
  }

  bool cancelWait()
  {
    test_comm_success( SetEvent( owait.o.hEvent ), "cancel_wait.SetEvent" );
    return true;
  }

  bool didEventOccur( int event )
  {
    return (m_events_out & event) != 0;
  }

  void setDTR( bool high )
  {
    test_comm_success( EscapeCommFunction( hComm, (high ? SETDTR : CLRDTR) ), "setDTR.EscapeCommFunction" );
    m_dtr = high;
  }

  void setRTS( bool high )
  {
    test_comm_success( EscapeCommFunction( hComm, (high ? SETRTS : CLRRTS) ), "setRTS.EscapeCommFunction" );
    m_rts = high;
  }

  bool isDTR()
  {
    return m_dtr;
  }

  bool isRTS()
  {
    return m_rts;
  }

  bool isCTS()
  {
    return (get_modem_status() & MS_CTS_ON) != 0;
  }

  bool isDSR()
  {
    return (get_modem_status() & MS_DSR_ON) != 0;
  }

  bool isRI()
  {
    return (get_modem_status() & MS_RING_ON) != 0;
  }

  bool isCD()
  {
    return (get_modem_status() & MS_RLSD_ON) != 0;
  }

  void sendBreak( int millis )
  {
  }

  NativeSerial( const char* portname ):
    m_events_in(0), 
    m_events_out(0),
    m_dtr(false),
    m_rts(false)
  {
    hComm = CreateFile( portname,
      GENERIC_READ | GENERIC_WRITE,
      0,  // exclusive access
      NULL,  // default security attributes
      OPEN_EXISTING,
      FILE_FLAG_OVERLAPPED,
      NULL
    );

    test_comm_success( hComm != INVALID_HANDLE_VALUE, "NativeSerialPort.CreateFile" );

    setDTR(false);
    setRTS(false);

    DWORD errors;
    test_comm_success( PurgeComm( hComm, PURGE_TXABORT | PURGE_RXABORT | PURGE_TXCLEAR | PURGE_RXCLEAR ), "NativeSerialPort.PurgeComm" );
    test_comm_success( ClearCommError( hComm, &errors, NULL ), "NativeSerialPort.ClearCommErrors" );
  }

  ~NativeSerial()
  {
    close();
  }

  void close()
  {
    CloseHandle( hComm );
    SetEvent( oread.o.hEvent );
    SetEvent( owrite.o.hEvent );
    SetEvent( owait.o.hEvent );
    SetEvent( oavail.o.hEvent );
  }

  static std::string getTOSCommMap()
  {
    const char* env = getenv( "TOSCOMMMAP" );
    return (env == NULL) ? "com1=COM1:com10=\\\\.\\COM10" : env;
  }
};


#include "TOSComm_wrap.cxx"

