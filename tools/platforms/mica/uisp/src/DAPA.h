// $Id: DAPA.h,v 1.3 2006-11-07 19:30:42 scipio Exp $

/*
 * $Id: DAPA.h,v 1.3 2006-11-07 19:30:42 scipio Exp $
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
  DAPA.h
  
  Direct AVR Parallel Access
  
  (c) copyright 1997, Uros Platise  
*/

#ifndef __DAPA
#define __DAPA

#include <sys/types.h>
#include <termios.h>
#include <time.h>
#include <unistd.h>
#include <string.h>
#include "Error.h"

class TDAPA {
public:
  enum TPaType{	PAT_DAPA, PAT_STK200, PAT_ABB, PAT_AVRISP, PAT_BSD,
		PAT_FBPRG, PAT_DT006, PAT_ETT, PAT_MAXI, PAT_XIL,
		PAT_DASA, PAT_DASA2, PAT_DAPA_2 };

private:
  int mosi_invert;
  int miso_invert;
  int sck_invert;
  int reset_invert;
  int reset_high_time;
  int parport_base;
  int ppdev_fd;
  long t_sck;
  TPaType pa_type;
  bool pa_type_is_serial;  /* not ppdev/ppi */
  struct termios saved_modes;
  unsigned char par_data, par_ctrl;  /* write */
  unsigned char par_status;  /* read */
  unsigned int ser_ctrl;  /* TIOCMGET/TIOCMSET */

private:
  int SendRecv(int);
  /* low level access to parallel port lines */
  void OutReset(int);
  void OutSck(int);
  void OutData(int);
  void SckDelay();
  int InData();
  void OutEnaReset(int);
  void OutEnaSck(int);

  void ParportSetDir(int);
  void ParportWriteCtrl();
  void ParportWriteData();
  void ParportReadStatus();

  void SerialReadCtrl();
  void SerialWriteCtrl();

public:
  /* If enable command 0x53 did not echo back, give a positive SCK
     pulse and retry again.
  */
  void PulseSck();
  void PulseReset();
  void Init();
  int Send(unsigned char*, int, int rec_queueSize=-1);
  void Delay_usec(long);

  TDAPA();
  ~TDAPA();
};

#endif
