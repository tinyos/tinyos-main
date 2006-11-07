// $Id: AvrStargate.h,v 1.3 2006-11-07 19:30:42 scipio Exp $

/*
 * $Id: AvrStargate.h,v 1.3 2006-11-07 19:30:42 scipio Exp $
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
 * Portions Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 *
 ****************************************************************************
 */


#ifndef __AVR_STARGATE
#define __AVR_STARGATE

#include "Global.h"
#include "Avr.h"
#include "SASA.h"

class TAvrStargate: public TAvr, TSASA {
private:
  bool use_data_polling;
  float min_poll_time, max_poll_time, total_poll_time;
  unsigned long total_poll_cnt;  /* bytes or pages */

  void EnableAvr();
  TByte GetPartInfo(TAddr addr);
  void WriteProgramMemoryPage();
  TByte ReadLockFuseBits();
  TByte ReadFuseLowBits();
  TByte ReadFuseHighBits();
  TByte ReadFuseExtBits();
  TByte ReadCalByte(TByte addr);
  void WriteOldFuseBits(TByte val);  /* 5 bits */
  void WriteFuseLowBits(TByte val);
  void WriteFuseHighBits(TByte val);
  void WriteFuseExtBits(TByte val);

  /* lock bits */
  void WriteLockBits(TByte bits);
  TByte ReadLockBits();

public:
  /* Read byte from active segment at address addr. */
  TByte ReadByte(TAddr addr);

  /* Write byte to active segment at address addr */
  void WriteByte(TAddr addr, TByte byte, bool flush_buffer=true);
  void FlushWriteBuffer();
  
  /* Chip Erase */
  void ChipErase();

  /* Transfer Statistics */
  unsigned int GetPollCount();
  float GetMinPollTime();
  float GetTotPollTime();
  float GetMaxPollTime();
  void ResetMinMax();
  
  TAvrStargate();
  ~TAvrStargate(){}
};

#endif
