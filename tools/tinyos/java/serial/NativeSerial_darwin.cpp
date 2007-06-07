//$Id: NativeSerial_darwin.cpp,v 1.1 2007-06-07 07:22:18 klueska Exp $

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
#include <sstream>
#include <iostream>
#include <fstream>

#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <termios.h>
#include <signal.h>
#include <errno.h>

#include "NativeSerialEnums.h"
using namespace NativeSerialEnums;


class comm_port_error : public std::runtime_error
{
  public:
    comm_port_error( const char* msg ): std::runtime_error(msg) { }
};


class NativeSerial
{
public:
  typedef std::string String;

private:

  std::string m_portname;
  int m_fd;
  int m_events_in;
  int m_events_out;
  bool m_wait_for_events;

protected:

  void note( std::string s )
  {
    //std::cout << "NativeSerial_linux " << m_portname << ": " << s << std::endl;
  }

  String cat( const char* prefix, const String& err )
  {
    return (prefix == NULL ? "" : String(prefix)+": ") + err;
  }

  void errno_wrap( bool error, const char* extra_err = NULL )
  {
    if( error && (errno != 0) )
      throw comm_port_error( cat(extra_err, strerror(errno)).c_str() );
  }

  void block_on_read( bool block )
  {
note( "block_on_read begin" );
    fcntl( m_fd, F_SETFL, (block ? 0 : FNDELAY) );
note( "block_on_read end" );
  }

  struct termios get_comm_state()
  {
note( "get_comm_state begin" );
    struct termios options;
    errno_wrap( tcgetattr( m_fd, &options ) == -1, "get_comm_state" );
note( "get_comm_state end" );
    return options;
  }


  int get_modem_status()
  {
note( "get_modem_status begin" );
    int status = 0;
    errno_wrap( ioctl( m_fd, TIOCMGET, &status ) == -1, "get_modem_status" );
note( "get_modem_status end" );
    return status;
  }

  void set_modem_status( int status )
  {
note( "set_modem_status begin" );
    errno_wrap( ioctl( m_fd, TIOCMSET, &status ) == -1, "set_modem_status" );
note( "set_modem_status end" );
  }

  int baud_to_enum( int baud )
  {
    switch( baud )
    {
      case 0: return B0;
      case 50: return B50;
      case 75: return B75;
      case 110: return B110;
      case 134: return B134;
      case 150: return B150;
      case 200: return B200;
      case 300: return B300;
      case 600: return B600;
      case 1200: return B1200;
      case 1800: return B1800;
      case 2400: return B2400;
      case 4800: return B4800;
      case 9600: return B9600;
      case 19200: return B19200;
      case 38400: return B38400;
      case 57600: return B57600;
      case 115200: return B115200;
      case 230400: return B230400;
    }
    throw comm_port_error("baud_to_enum, bad baud rate");
  }

  int enum_to_baud( int baudenum )
  {
    switch( baudenum )
    {
      case B0: return 0;
      case B50: return 50;
      case B75: return 75;
      case B110: return 110;
      case B134: return 134;
      case B150: return 150;
      case B200: return 200;
      case B300: return 300;
      case B600: return 600;
      case B1200: return 1200;
      case B1800: return 1800;
      case B2400: return 2400;
      case B4800: return 4800;
      case B9600: return 9600;
      case B19200: return 19200;
      case B38400: return 38400;
      case B57600: return 57600;
      case B115200: return 115200;
      case B230400: return 230400;
    }
    throw comm_port_error("enum_to_baud, bad baud rate");
  }

/*
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
*/

public:

  void setSerialPortParams( int baudrate, int databits, int stopbits, int parity )
  {
note( "setSerialPortParams begin" );
    struct termios state = get_comm_state();

    int baudenum = baud_to_enum(baudrate);
    errno_wrap( cfsetispeed( &state, baudenum ) == -1, "baudrate" );
    errno_wrap( cfsetospeed( &state, baudenum ) == -1, "baudrate" );

    //throw comm_port_error("nuthin");

    state.c_cflag &= ~CSIZE;
    switch( databits )
    {
      case 5: state.c_cflag |= CS5; break;
      case 6: state.c_cflag |= CS6; break;
      case 7: state.c_cflag |= CS7; break;
      case 8: default: state.c_cflag |= CS8;
    }

    if( stopbits == STOPBITS_2 )
      state.c_cflag |= CSTOPB;
    else
      state.c_cflag &= ~CSTOPB;

    state.c_cflag |= PARENB;
    switch( parity )
    {
      case NPARITY_EVEN: state.c_cflag &= ~PARODD; break;
      case NPARITY_ODD: state.c_cflag |= PARODD; break;
      case NPARITY_NONE: default: state.c_cflag &= ~PARENB;
    }

    errno_wrap( tcsetattr( m_fd, TCSANOW, &state ) == -1, "set_comm_state" );
note( "setSerialPortParams end" );
  }

  int getBaudRate()
  {
    struct termios state = get_comm_state();
    return enum_to_baud( cfgetospeed( &state ) );
  }

  int getDataBits()
  {
    switch( get_comm_state().c_cflag & CSIZE )
    {
      case CS5: return 5;
      case CS6: return 6;
      case CS7: return 7;
      case CS8: default: return 8;
    }
  }

  int getStopBits()
  {
    int stop = get_comm_state().c_cflag;
    return (stop & CSTOPB) ? STOPBITS_2 : STOPBITS_1;
  }

  int getParity()
  {
    int parity = get_comm_state().c_cflag;
    if( parity & PARENB )
      return (parity & PARODD) ? NPARITY_ODD : NPARITY_EVEN;
    return NPARITY_NONE;
  }

  int read( signed char* buffer, int off, int len )
  {
note( "read begin" );
    int nread = ::read( m_fd, buffer+off, len );
    errno_wrap( nread == -1, "read" );
#if 0
printf("   ...  read:");
for( int i=0; i<nread; i++ )
  printf(" %02x",buffer[off+i]&255);
printf("\n");
#endif
note( "read end" );
    return nread;
  }

  int write( const signed char* buffer, int off, int len )
  {
note( "write begin" );
    int nwritten = ::write( m_fd, buffer+off, len );
    errno_wrap( nwritten == -1, "write" );
#if 0
printf("   ... wrote:");
for( int i=0; i<nwritten; i++ )
  printf(" %02x",buffer[off+i]&255);
printf("\n");
#endif
note( "write end" );
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
note( "available begin" );
    int navail = 0;
    int rv = 0;
    errno_wrap( rv=ioctl( m_fd, FIONREAD, &navail ) == -1, "available" );
//printf("... fionread=%d, rv=%d\n",navail,rv);
note( "available end" );
    return navail;
  }

  void notifyOn( int event, bool enable )
  {
    if( enable )
      m_events_in |= event;
    else
      m_events_in &= ~event;
  }

  bool isNotifyOn( int event )
  {
    return (m_events_in & event) != 0;
  }

  bool waitForEvent()
  {
note( "waitForEvent begin" );
    fd_set input;
    struct timeval tv;
    m_events_out = 0;

    while( m_wait_for_events && (m_fd != -1) && (m_events_out == 0) )
    {
      FD_ZERO( &input );
      FD_SET( m_fd, &input );
      tv.tv_sec = 0;
      tv.tv_usec = 100*1000; // 1ms is the minimum resolution, at best

      if( select( m_fd+1, &input, NULL, NULL, &tv ) == -1 )
      {
	if( errno == EINTR )
	  break;
	errno_wrap( true, "waitForEvent.select" );
      }

      if( FD_ISSET( m_fd, &input ) )
	m_events_out |= DATA_AVAILABLE;
    }

    m_wait_for_events = true;
note( "waitForEvent end" );
    return (m_events_out != 0);
  }

  bool cancelWait()
  {
note( "cancelWait begin" );
    m_wait_for_events = false;
note( "cancelWait end" );
  }

  bool didEventOccur( int event )
  {
    return (m_events_out & event) != 0;
  }

  void setDTR( bool high )
  {
    if( high )
      set_modem_status( get_modem_status() | TIOCM_DTR );
    else
      set_modem_status( get_modem_status() & ~TIOCM_DTR );
  }

  void setRTS( bool high )
  {
    if( high )
      set_modem_status( get_modem_status() | TIOCM_RTS );
    else
      set_modem_status( get_modem_status() & ~TIOCM_RTS );
  }

  bool isDTR()
  {
    return (get_modem_status() & TIOCM_DTR) != 0;
  }

  bool isRTS()
  {
    return (get_modem_status() & TIOCM_RTS) != 0;
  }

  bool isCTS()
  {
    return (get_modem_status() & TIOCM_CTS) != 0;
  }

  bool isDSR()
  {
    return (get_modem_status() & TIOCM_DSR) != 0;
  }

  bool isRI()
  {
    return (get_modem_status() & TIOCM_RI) != 0;
  }

  bool isCD()
  {
    return (get_modem_status() & TIOCM_CD) != 0;
  }

  void sendBreak( int millis )
  {
  }

  NativeSerial( const char* portname ):
    m_fd(-1),
    m_events_in(0), 
    m_events_out(0),
    m_wait_for_events(true)
  {
    m_portname = portname;
note( "constructor begin" );
    m_fd = open( portname, O_RDWR | O_NOCTTY | O_NONBLOCK );
    errno_wrap( m_fd == -1, "open" );

//std::cout << "NativeSerial constructor [1] " << portname << std::endl;

    block_on_read(false);

    // set default port parmeters
    struct termios options = get_comm_state();

    // disable rts/cts, no parity bits, one stop bit, clear databits mask
    //local mode, enable receiver, 8 databits
    options.c_cflag = CLOCAL | CREAD | CS8;

    //raw mode
    options.c_lflag = 0;

    //disable software flow control, etc
    options.c_iflag = IGNPAR | IGNBRK;

    //raw output mode
    options.c_oflag = 0;

    //set thresholds
    options.c_cc[VMIN] = 0;
    options.c_cc[VTIME] = 0;

    errno_wrap( tcflush( m_fd, TCIOFLUSH ) == -1, "flush" );
    errno_wrap( tcsetattr( m_fd, TCSANOW, &options ) == -1, "setattr" );

    setDTR(false);
    setRTS(false);
note( "constructor end" );
  }

  ~NativeSerial()
  {
note( "destructor begin" );
    close();
note( "destructor end" );
  }

  void close()
  {
note( "close begin" );
//std::cout << "NativeSerial_linux close fd=" << m_fd << std::endl;
    if( m_fd != -1 )
    {
      cancelWait();
      struct timeval tv = { tv_sec:0, tv_usec:1100 };
      select( 0, NULL, NULL, NULL, &tv );
      ::close( m_fd );
      m_fd = -1;
    }
note( "close end" );
  }

  static std::string getTOSCommMap()
  {
    const char* env = getenv( "TOSCOMMMAP" );
    return (env == NULL) ? "com1=/dev/ttyS0:usb1=/dev/ttyUSB0" : env;
  }
};


#include "TOSComm_wrap.cxx"

