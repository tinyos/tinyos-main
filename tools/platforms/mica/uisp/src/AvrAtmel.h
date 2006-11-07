// $Id: AvrAtmel.h,v 1.3 2006-11-07 19:30:42 scipio Exp $

/*
 * $Id: AvrAtmel.h,v 1.3 2006-11-07 19:30:42 scipio Exp $
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

/* AvrAtmel.h, Uros Platise (c) 1999 */

#ifndef __AVR_ATMEL
#define __AVR_ATMEL

#include "Global.h"
#include "Serial.h"
#include "Avr.h"

class TAvrAtmel: public TAvr, TSerial {
private:
  /* Programmer AVR codes */
  struct SPrgPart{
    const char* name;
    TByte code;
    const char* description;
    bool supported;
  };
  static SPrgPart prg_part[];
  TByte desired_avrcode;

  /* Flash word's lower byte cache */
  bool cache_lowbyte;
  TByte buf_lowbyte;
  TAddr buf_addr;
  
  /* Speed-up Transfer by using the Auto-Increment Option */
  TAddr apc_address;	/* AVR Programmer's Current Address */
  bool apc_autoinc;	/* Auto Increment Supported by AVR ISP SoftVer 2 */

private:
  void EnterProgrammingMode();
  void LeaveProgrammingMode();
  void CheckResponse(TByte x);
  void EnableAvr();
  void SetAddress(TAddr addr);
  void WriteProgramMemoryPage();
  TByte ReadFuseLowBits ();
  TByte ReadFuseHighBits ();
  TByte ReadCalByte(TByte addr);
  TByte ReadFuseExtBits ();
  TByte ReadLockFuseBits ();
  TByte ReadLockBits ();
  void WriteOldFuseBits (TByte val);
  void WriteFuseLowBits (TByte val);
  void WriteFuseHighBits (TByte val);
  void WriteFuseExtBits (TByte val);

public:
  /* Read byte from active segment at address addr. */
  TByte ReadByte(TAddr addr);
  
  /* Write byte to active segment at address addr */
  void WriteByte(TAddr addr, TByte byte, bool flush_buffer=true);
  void FlushWriteBuffer();
  
  /* Chip Erase */
  void ChipErase();

  /* Write lock bits */
  void WriteLockBits(TByte bits);
  
  TAvrAtmel();
  ~TAvrAtmel();
};

#endif
