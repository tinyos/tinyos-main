// $Id: SASA.h,v 1.4 2006-12-12 18:23:01 vlahan Exp $

/*
 * $Id: SASA.h,v 1.4 2006-12-12 18:23:01 vlahan Exp $
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
  SASA.h
  
  Stargate AVR SSP Access

*/

#ifndef __SASA
#define __SASA

#include <sys/types.h>
#include <time.h>
#include <unistd.h>
#include <string.h>
#include "Error.h"

class TSASA {

private:
  int dev_fd;
  static const char dev_name[];

private:
  unsigned char SendRecv(unsigned char);
  /* low level access to parallel port lines */
  void SckDelay();

public:
  void PulseSck();
  void PulseReset();
  void Init();
  int Send(unsigned char*, int, int rec_queueSize=-1);
  void Delay_usec(long);

  TSASA();
  ~TSASA();
};

#endif
