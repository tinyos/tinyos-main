// $Id: Serial.C,v 1.3 2006-11-07 19:30:42 scipio Exp $

/*
 * $Id: Serial.C,v 1.3 2006-11-07 19:30:42 scipio Exp $
 *
 ****************************************************************************
 *
 * uisp - The Micro In-System Programmer for Atmel AVR microcontrollers.
 * Copyright (C) 1997, 1998, 1999, 2000, 2001, 2002, 2003  Uros Platise
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 ****************************************************************************
 */

/*
	Serial.C
	
	Serial Interface
	Uros Platise, (c) 1997-1999
*/

#include "config.h"

#include <sys/time.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <netdb.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <ctype.h>
#include <errno.h>
#include "Global.h"
#include "Serial.h"

int TSerial::Tx(unsigned char* queue, int queue_size)
{
  Info(4, "Transmit: { ");
  for (int n=0; n<queue_size; n++) {
    Info(4, "%c [%02x] ", isprint(queue[n])?(char) queue[n]:'.', queue[n]);
  }
  Info(4, "}\n");
  int ok = write(serline, queue, queue_size);
  tcdrain(serline);
  return ok;
}

int TSerial::Rx(unsigned char* queue, int queue_size, timeval* timeout){
  int ret;
  fd_set rfds;
  FD_ZERO(&rfds); FD_SET(serline,&rfds);

  int tries = 5;
  while (1) {
    if ((ret=select(serline+1, &rfds, NULL, NULL, timeout))==-1) {
      Info(3, "Select on %d returned retval:%d errno:%d\n",
           serline, ret, errno);
      if ((errno == EINTR) && tries) {
        tries--;
        continue;
      }
      throw Error_C("Select failed");
    }

    // Success.
    break;
  }

  if (ret==0)
    throw Error_Device("Programmer is not responding.",GetCmdParam("-dhost"));
  int size = read(serline, queue, queue_size);  
  Info(4, "Receive: { ");
  for (int n=0; n<size; n++) {
    Info(4, "%c [%02x] ", isprint(queue[n])?(char)queue[n]:'.', queue[n]);
  }
  Info(4, "}\n");
  return size;
}

int TSerial::Send(unsigned char* queue, int queue_size, int rec_queue_size,
		  int timeout)
{
  Tx(queue, queue_size);
  struct timeval time_out;
  time_out.tv_sec = timeout;
  time_out.tv_usec = 0;
  if (rec_queue_size==-1){rec_queue_size = queue_size;}
  int total_len=0;  
  while(total_len<rec_queue_size){
    total_len += Rx(&queue[total_len], rec_queue_size - total_len, &time_out);
  }
  return total_len;
}

//xmit a buffer only, empty the rcv buffer
//for MIB510 only. May have bad chars in uart rcv bfr from mote.
//need to flush them.
void TSerial::SendOnly(unsigned char* queue, int queue_size)
{
  Tx(queue, queue_size);
  if (!remote) {
    // Make sure sequence goes out, then flush input
    tcdrain(serline);
    tcflush(serline, TCIFLUSH); // Not strictly necessary, but I
				// think it will make cygwin happier
    usleep(10000);		// Should be more than enough (response
				// is 2 bytes at 115200 baud)
    tcflush(serline, TCIFLUSH);
  }
}

/* Constructor/Destructor
*/

TSerial::TSerial(){
  /* Parse Command Line Parameters */
  if (GetCmdParam("-dhost")) {
    remote = true;
    OpenTcp();
  }
  else {
    remote = false;
    OpenPort();
  }
}

void TSerial::OpenTcp() {
  /* Parse Command Line Parameters */
  struct sockaddr_in serv_addr;
  struct hostent *server;
  short  sPort = 10001;

  if ((server = gethostbyname(GetCmdParam("-dhost"))) == NULL) {
    throw Error_Device("Error resolving server name.");
  }

  if ((serline = socket(AF_INET,SOCK_STREAM,0)) < 0) {
    throw Error_C("Could not create socket.");
  }
    
  int flag = 1;
  if ((setsockopt(serline,IPPROTO_TCP,TCP_NODELAY,(char *)&flag,sizeof(int))) < 0 ){
    throw Error_Device("Error setting TCP_NODELAY.");
  }

  memset ((void *)&serv_addr,0,sizeof(serv_addr));
  serv_addr.sin_family = AF_INET;
    
  memcpy((void *)&serv_addr.sin_addr.s_addr,(void *)server->h_addr,server->h_length);

  const char* val;
  if ((val = GetCmdParam("-dport"))) {
    sPort = (short) atoi(val);
  }
  serv_addr.sin_port = htons(sPort);

  if (connect(serline,(sockaddr *)&serv_addr,sizeof(serv_addr)) < 0) {
    throw Error_Device("Error connecting to server.",GetCmdParam("-dhost"));
  }

  remote = true;
}

void TSerial::OpenPort() { 
  struct termios pmode;
  const char* dev_name = "/dev/avr";
  const char* val;
  speed_t speed = B19200;	/* default speed */
  
  struct TSpeed{
    const char* arg;
    speed_t speed;
  };
  const TSpeed speed_array[] = {
    {"1200", B1200},
    {"2400", B2400},
    {"4800", B4800},
    {"9600", B9600},
    {"19200", B19200},
    {"38400", B38400},
    {"57600", B57600},
    {"115200", B115200},
    {"", 0}
  };
  
 /* Open port and set serial attributes */
  if (strcmp(GetCmdParam("-dprog"), "stk500") == 0 ||
      strcmp(GetCmdParam("-dprog"), "mib510") == 0) {
    speed = B115200;        /* default STK500 speed */
  }

  if ((val=GetCmdParam("-dserial"))){dev_name = val;}
  if ((val=GetCmdParam("-dspeed"))){
    const TSpeed* speed_item = speed_array;
    for (;speed_item->arg[0] != 0; speed_item++){
      if (strcmp(speed_item->arg, val) == 0) {
	speed = speed_item->speed;
	break;
      }
    } 
    if (speed_item->arg[0]==0){throw Error_Device("-dspeed: Invalid speed.");}
  }

  // COMn and cygwin don't interact well. Use /dev/ttyS<n-1> instead
  if (strlen(dev_name) == 4 && strncasecmp(dev_name, "com", 3) == 0 &&
      isdigit(dev_name[3]))
    {
      char *new_name = new char[11];
      sprintf(new_name, "/dev/ttyS%c", dev_name[3] - 1);

      Info(0, "Please use %s rather than %s (the latter often doesn't work)\n",
	   new_name, dev_name);
      dev_name = new_name;
    }
  
  if ((serline = open(dev_name, O_RDWR | O_NOCTTY | O_NONBLOCK)) < 0) {
    throw Error_C(dev_name);
  }  
  tcgetattr(serline, &pmode);
  saved_modes = pmode;

  memset(&pmode, 0, sizeof(pmode));
  /* VMIN, VTIME=0 is fine as we use select in Rx anyway */
  pmode.c_cflag = CS8 | CLOCAL | CREAD;
  pmode.c_iflag = IGNPAR | IGNBRK;
  cfsetispeed(&pmode, speed);
  cfsetospeed(&pmode, speed);
  tcsetattr(serline, TCSANOW, &pmode);

#if 0
  /* Reopen port */
  int fd = serline;
  if ((serline = open(dev_name, O_RDWR | O_NOCTTY)) < 0){throw Error_C();}
  close(fd);
#else
  /* Clear O_NONBLOCK flag.  */
  int flags = fcntl(serline, F_GETFL, 0);
  if (flags == -1) { throw Error_C("Can not get flags"); }
  flags &= ~O_NONBLOCK;
  if (fcntl(serline, F_SETFL, flags) == -1) {
    throw Error_C("Can not clear nonblock flag");
  }
#endif
}

TSerial::~TSerial(){
  if (!remote)
    tcsetattr(serline, TCSADRAIN, &saved_modes);
  close(serline);
}
