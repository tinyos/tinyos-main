// $Id: MotIntl.h,v 1.3 2006-11-07 19:30:42 scipio Exp $

/*
 * $Id: MotIntl.h,v 1.3 2006-11-07 19:30:42 scipio Exp $
 *
 ****************************************************************************
 *
 * uisp - The Micro In-System Programmer for Atmel AVR microcontrollers.
 * Copyright (C) 1999, 2000, 2001, 2002  Uros Platise
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
	MotIntl.h
	
	Motorola and Intel Uploading/Downloading Routines
	Uros Platise (c) 1999
*/

#ifndef __MOTINTL
#define __MOTINTL

#include <stdio.h>
#include "Global.h"

#define MI_LINEBUF_SIZE	128

class TMotIntl{
public:
  enum TFormatType{TF_MOTOROLA, TF_INTEL};

private:
  char line_buf [MI_LINEBUF_SIZE];
  unsigned char cc_sum;
  unsigned int hash_marker;
  FILE* fd;
  bool upload, verify;

  TByte Htoi(const char* p);
  void InfoOperation(const char* prefix, const char* seg_name);
  void ReportStats(float, TAddr);
  void UploadMotorola();
  void UploadIntel();
  void SrecWrite(unsigned int, const unsigned char *, unsigned int);
  void DownloadMotorola();

public:
  void Read(const char* filename, bool _upload, bool _verify);
  void Write(const char *filename);

  TMotIntl();
  ~TMotIntl(){}
};

extern TMotIntl motintl;

#endif
