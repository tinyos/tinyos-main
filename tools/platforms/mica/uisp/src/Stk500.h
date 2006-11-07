// $Id: Stk500.h,v 1.3 2006-11-07 19:30:42 scipio Exp $

/*
 * $Id: Stk500.h,v 1.3 2006-11-07 19:30:42 scipio Exp $
 *
 ****************************************************************************
 *
 * uisp - The Micro In-System Programmer for Atmel AVR microcontrollers.
 * Copyright (C) 2001, 2002, 2003  Daniel Berntsson
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

/* Stk500.h, Daniel Berntsson, 2001 */

#ifndef __STK500
#define __STK500

#include "Global.h"
#include "Serial.h"
#include "Avr.h"

#define STK500_PROG_SERIAL   0
#define STK500_PROG_PARALLEL 1

struct SPrgParams {
  const TByte cmd;              // Always 0x42 (Cmnd_STK_SET_DEVICE)
  const TByte devicecode;       // Device code (as defined above)
  const TByte revision;         // Device revision. Not used, set to 0.
  TByte progtype;               // Defines which Program modes are supported:
                                //   0 - Both parallel/Hi-V and serial mode
                                //   1 - Parallel/Hi-V only
  const TByte parmode;          // Defines if the device has a full parallel
                                // interface or a pseudo parallel programming
                                // interface: 0 - pseudo; 1 - full
  const TByte polling;          // Defines if polling may be used during SPI
                                // access: 0 - no; 1 - yes
  const TByte selftimed;        // Defines if prog insns are self timed: 
                                // 0 - no; 1 - yes
  const TByte lockbytes;        // Number of lock bytes. Currently not used
                                // but should be set for future compat.
  const TByte fusebytes;        // Number of fuse bytes. Currently not used
                                // but should be set for future compat.
  const TByte flashpollval1;    // FLASH polling value. See dev data sheet.
  const TByte flashpollval2;    // FLASH polling value. Same as val1.
  const TByte eeprompollval1;   // EEPROM polling value 1 (P1). See dev data
                                // sheet.
  const TByte eeprompollval2;   // EEPROM polling value 2 (P2). See dev data
                                // sheet.
  
  // The following multi-byte values are sent to the stk500 in big endian
  // order.
  const TByte pagesize[2];      // Page size in bytes for pagemode parts
  const TByte eepromsize[2];    // Size of eeprom in bytes.
  const TByte flashsize[4];     // Size of FLASH in bytes.
  const TByte sync;             // Always 0x20 (Sync_CRC_EOP)
};

/* Set the Extened Device Programming parameters. In the future, this may
   require more than 3 arguments. */

struct SPrgExtDevParams {
  const TByte eepgsz;           // EEPROM page size in bytes.
  const TByte sig_pagel;        // Defines which port pin the PAGEL signal
                                // should be mapped on to. e.g. 0xD7 maps to
                                // PORTD7.
  const TByte sig_bs2;          // Defines which port pin the BS2 signal
                                // should be mapped on to.
  const TByte reset_disable;    // Req'd by firmware version 1.14.  It's a
                                // flag which tells whether a device uses the
                                // reset pin as an IO pin. Where 0x00 =
                                // Dedicated RESET pin, 0x01 = Can't rely on
                                // RESET pin for going into programming
                                // mode. Not needed for SPI programming
                                // though.
};

class TStk500: public TAvr, TSerial {
private:
  struct SPrgPart{
    const char *name;
    struct SPrgExtDevParams ext_params;
    struct SPrgParams params;
  };

  int desired_part;
  int page;                     /* page address for reading memory, mib510 */
  const char *pNodename;
  TByte* write_buffer[2];       /* buffer for SEG_FLASH and SEG_EEPROM */
  TByte* read_buffer[2];        /* buffer for SEG_FLASH and SEG_EEPROM */
  TAddr maxaddr;
  TAddr minaddr;

  static const TByte IspMode[];             //XBOW MIB510
  static const TByte IspMode_Reply[];       //XBOW MIB510
  static const TByte pSTK500[];
  static const TByte pSTK500_Reply[];
  static const TByte SWminor[];
  static const TByte SWminor_Reply[];
  static const TByte SWmajor[];
  static const TByte SWmajor_Reply[];
  static const TByte EnterPgmMode[];
  static const TByte EnterPgmMode_Reply[];
  static const TByte LeavePgmMode[];
  static const TByte LeavePgmMode_Reply[];
  static const TByte SetAddress[];
  static const TByte SetAddress_Reply[];
  static const TByte EraseDevice[];
  static const TByte EraseDevice_Reply[];
  static const TByte WriteMemory[];
  static const TByte WriteMemory_Reply[];
  static const TByte ReadMemory[];
  static const TByte ReadMemory_Reply[];
  static const TByte GetSignature[];
  static const TByte GetSignature_Reply[];
  static const TByte CmdStopByte[];
  static const TByte ReplyStopByte[];
  static const TByte Flash;
  static const TByte EEPROM;
  static const TByte DeviceParam_Reply[];
  static const TByte ExtDevParams_Reply[];
  static SPrgPart prg_part[];

  void Initialize();
  void Cleanup();

  void EnterProgrammingMode();
  void LeaveProgrammingMode();
  void ReadSignature();
  void ReadMem();
  void ReadMemPage(TAddr addr);

  TByte ReadParam(TByte param);
  void  WriteParam(TByte param, TByte val);

  TByte UniversalCmd(TByte cmd[]);

  TByte ReadLockFuseBits();
  TByte ReadCalFuseBits(int addr);
  TByte ReadFuseLowBits();
  TByte ReadFuseHighBits();
  TByte ReadFuseExtBits();

  TByte ReadLockBits();

  void WriteLockFuseBits(TByte bits);
  void WriteFuseLowBits(TByte bits);
  void WriteFuseHighBits(TByte bits);
  void WriteFuseExtBits(TByte bits);

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

  TStk500();
  ~TStk500();
};

#endif
