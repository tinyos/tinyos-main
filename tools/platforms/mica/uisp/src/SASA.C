// $Id: SASA.C,v 1.3 2006-11-07 19:30:42 scipio Exp $

/*
 * $Id: SASA.C,v 1.3 2006-11-07 19:30:42 scipio Exp $
 *
 ****************************************************************************
 *
 * uisp - The Micro In-System Programmer for Atmel AVR microcontrollers.
 * Copyright (C) 1999, 2000, 2001, 2002, 2003  Sergey Larin
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
 * Portions Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.

 ****************************************************************************
 */

/*
	SASA.C

	Stargate AVR SSP Access (SASA)
	
	Phil Buonadonna (c) 2003
*/

//#define DEBUG
//#define DEBUG1

#include "config.h"

#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <ctype.h>


#include <unistd.h>
#include <signal.h>
#include <sys/ioctl.h>
#include <fcntl.h>

#include "timeradd.h"
#include "Global.h"
#include "Error.h"
#include "SASA.h"
#include "Avr.h"


/* Default value for minimum SCK high/low time in microseconds.  */
#ifndef SCK_DELAY
#define SCK_DELAY 5
#endif

/* Minimum RESET# high time in microseconds.
   Should be enough to charge a capacitor between RESET# and GND
   (it is recommended to use a voltage detector with open collector
   output, and only something like 100 nF for noise immunity).
   Default value may be changed with -dt_reset=N microseconds.  */
#ifndef RESET_HIGH_TIME
#define RESET_HIGH_TIME 1000
#endif

/* Delay from RESET# low to sending program enable command
   (the datasheet says it must be at least 20 ms).  Also wait time
   for crystal oscillator to start after possible power down mode.  */
#ifndef RESET_LOW_TIME
#define RESET_LOW_TIME 30000
#endif

const char TSASA::dev_name[] = "/dev/ssp";

void
TSASA::SckDelay()
{
  Delay_usec(5);
}

#ifndef MIN_SLEEP_USEC
#define MIN_SLEEP_USEC 20000
#endif

void
TSASA::Delay_usec(long t)
{
  struct timeval t1, t2;
  if (t <= 0)
    return;  /* very short delay for slow machines */
  gettimeofday(&t1, NULL);
  if (t > MIN_SLEEP_USEC)
    usleep(t - MIN_SLEEP_USEC);
  /* loop for the remaining time */
  t2.tv_sec = t / 1000000UL;
  t2.tv_usec = t % 1000000UL;
  timeradd(&t1, &t2, &t1);
  do {
    gettimeofday(&t2, NULL);
  } while (timercmp(&t2, &t1, <));
}

void 
TSASA::PulseSck()
{

  PulseReset();

}

void
TSASA::PulseReset()
{
  close(dev_fd);

  Delay_usec(1000);

  dev_fd = open(dev_name, O_RDWR, 0);
  if (dev_fd == -1) {
    perror(dev_name);
    throw Error_Device("Failed to reopen ppdev.");
  }

}

void
TSASA::Init()
{
  return;
}

unsigned char
TSASA::SendRecv(unsigned char b)
{
  unsigned char received;

  write(dev_fd,&b,1);
  read(dev_fd,&received,1);

  return received;
}

int
TSASA::Send (unsigned char* queue, int queueSize, int rec_queueSize)
{
  unsigned char *p = queue, ch;
  int i = queueSize;
  
  if (rec_queueSize==-1){rec_queueSize = queueSize;}
#ifdef DEBUG
  printf ("send(recv): ");
#endif
  while (i--){
#ifdef DEBUG
    printf ("%02X(", (unsigned int)*p);
#endif    
    ch = SendRecv(*p);
#ifdef DEBUG    
    printf ("%02X) ", (unsigned int)ch);
#endif    
    *p++ = ch;
  }
#ifdef DEBUG  
  printf ("\n");
#endif  
  return queueSize;
}


TSASA::TSASA(): 
  dev_fd(-1)
{

  /* Drop privileges (if installed setuid root - NOT RECOMMENDED).  */
  setgid(getgid());
  setuid(getuid());

  dev_fd = open(dev_name, O_RDWR, 0);
  if (dev_fd == -1) {
    perror(dev_name);
    throw Error_Device("Failed to open the SSP. Is the driver installed?");
  }

}

TSASA::~TSASA()
{

  if (dev_fd != -1) {
    close(dev_fd);
    dev_fd = -1;
  } 
}


/* eof */
