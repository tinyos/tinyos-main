// $Id: Stk500.C,v 1.3 2006-11-07 19:30:42 scipio Exp $

/*
 * $Id: Stk500.C,v 1.3 2006-11-07 19:30:42 scipio Exp $
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

/* Stk500.C, Daniel Berntsson, 2001 */

#include <stdlib.h>

#include "config.h"

#include "Stk500.h"
#include "Serial.h"

const TByte TStk500::pSTK500[] = { 0x30, 0x20 };
const TByte TStk500::pSTK500_Reply[] = { 0x14, 0x10 };

const TByte TStk500::SWminor[] = { 0x41, 0x82, 0x20 };
const TByte TStk500::SWminor_Reply[] = { 0x14, 0x07, 0x10 };

const TByte TStk500::SWmajor[] = { 0x41, 0x81, 0x20 };
const TByte TStk500::SWmajor_Reply[] = {0x14, 0x01, 0x10 };

//XBOW MIC510 cmd to enter cmd MIB510 to take control of RS232 lines
const TByte TStk500::IspMode[] = {0xaa, 0x55, 0x55, 0xaa, 0x17, 0x51, 0x31, 0x13,  '?' };
const TByte TStk500::IspMode_Reply[] = { 0x14, 0x10 };

const TByte TStk500::EnterPgmMode[] = { 0x50, 0x20 };
const TByte TStk500::EnterPgmMode_Reply[] = { 0x14, 0x10 };

const TByte TStk500::LeavePgmMode[] = { 0x51, 0x20 };
const TByte TStk500::LeavePgmMode_Reply[] = { 0x14, 0x10 };

const TByte TStk500::SetAddress[] = { 0x55, '?', '?', 0x20 };
const TByte TStk500::SetAddress_Reply[] = { 0x14, 0x10 };

const TByte TStk500::EraseDevice[] = { 0x52, 0x20 };
const TByte TStk500::EraseDevice_Reply[] = { 0x14, 0x10 };

const TByte TStk500::WriteMemory[] = { 0x64, '?', '?', '?' };
const TByte TStk500::WriteMemory_Reply[] = { 0x14, 0x10 };

const TByte TStk500::ReadMemory[] = { 0x74, 0x01, 0x00, '?', 0x20 };
const TByte TStk500::ReadMemory_Reply[] = { 0x14 };

const TByte TStk500::GetSignature[] = {0x75, 0x20};
const TByte TStk500::GetSignature_Reply[] = {0x75, '?', '?', '?', 0x20};

const TByte TStk500::CmdStopByte[] = { 0x20 };

const TByte TStk500::ReplyStopByte[] = { 0x10 };

const TByte TStk500::Flash = 'F';

const TByte TStk500::EEPROM = 'E';

const TByte TStk500::DeviceParam_Reply[] = { 0x14, 0x10 };
const TByte TStk500::ExtDevParams_Reply[] = { 0x14, 0x10 };

/* FIXME: troth/2002-10-02: Get rid of all these magic numbers now that we
   know what they mean. (See REAME.stk500) */

TStk500::SPrgPart TStk500::prg_part[] = {
  {"AT90S4414",
   {0x00, 0xD7, 0xA0, 0x00},
   {0x42, 0x50, 0x00, 0x00, 0x01, 0x01, 0x00, 0x01, 0x01, 0x7f, 0x7f, 0x80,
    0x7f, {0x00, 0x00}, {0x01, 0x00}, {0x00, 0x00, 0x10, 0x00}, 0x20}
  },
  {"AT90S2313",
   {0x00, 0xD7, 0xA0, 0x00},
   {0x42, 0x40, 0x00, 0x00, 0x01, 0x01, 0x00, 0x01, 0x01, 0x7f, 0x7f, 0x80,
    0x7f, {0x00, 0x00}, {0x00, 0x80}, {0x00, 0x00, 0x08, 0x00}, 0x20}
  },
  {"AT90S1200",
   {0x00, 0xD7, 0xA0, 0x00},
   {0x42, 0x33, 0x00, 0x00, 0x01, 0x01, 0x00, 0x01, 0x01, 0xff, 0xff, 0x00,
    0xff, {0x00, 0x00}, {0x00, 0x40}, {0x00, 0x00, 0x04, 0x00}, 0x20}
  },
  {"AT90S2323",
   {0x00, 0xD7, 0xA0, 0x00},
   {0x42, 0x41, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x01, 0xff, 0xff, 0x00,
    0xff, {0x00, 0x00}, {0x00, 0x80}, {0x00, 0x00, 0x08, 0x00}, 0x20}
  },
  {"AT90S2343",
   {0x00, 0xD7, 0xA0, 0x00},
   {0x42, 0x43, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x01, 0xff, 0xff, 0x00,
    0xff, {0x00, 0x00}, {0x00, 0x80}, {0x00, 0x00, 0x08, 0x00}, 0x20}
  },
  {"AT90S2333",
   {0x00, 0xD7, 0xA0, 0x00},
   {0x42, 0x42, 0x00, 0x00, 0x01, 0x01, 0x00, 0x01, 0x01, 0xff, 0xff, 0x00,
    0xff, {0x00, 0x00}, {0x00, 0x80}, {0x00, 0x00, 0x08, 0x00}, 0x20}
  },
  {"AT90S4433",
   {0x00, 0xD7, 0xA0, 0x00},
   {0x42, 0x51, 0x00, 0x00, 0x01, 0x01, 0x00, 0x01, 0x01, 0xff, 0xff, 0x00,
    0xff, {0x00, 0x00}, {0x01, 0x00}, {0x00, 0x00, 0x10, 0x00}, 0x20}
  },
  {"AT90S4434",
   {0x00, 0xD7, 0xA0, 0x00},
   {0x42, 0x52, 0x00, 0x00, 0x01, 0x01, 0x00, 0x01, 0x01, 0xff, 0xff, 0x00,
    0xff, {0x00, 0x00}, {0x01, 0x00}, {0x00, 0x00, 0x10, 0x00}, 0x20}
  },
  {"AT90S8515",
   {0x00, 0xD7, 0xA0, 0x00},
   {0x42, 0x60, 0x00, 0x00, 0x01, 0x01, 0x00, 0x01, 0x01, 0x7f, 0x7f, 0x80,
    0x7f, {0x00, 0x00}, {0x02, 0x00}, {0x00, 0x00, 0x20, 0x00}, 0x20}
  },
  {"AT90S8535",
   {0x00, 0xD7, 0xA0, 0x00},
   {0x42, 0x61, 0x00, 0x00, 0x01, 0x01, 0x00, 0x01, 0x01, 0xff, 0xff, 0x00,
    0xff, {0x00, 0x00}, {0x02, 0x00}, {0x00, 0x00, 0x20, 0x00}, 0x20}
  },
  {"AT90S8534", /* NOTE (20030216): experimental and untested */
   {0x00, 0xD7, 0xA0, 0x00},
   {0x42, 0x62, 0x00, 0x01, 0x01, 0x00, 0x00, 0x01, 0x01, 0xff, 0xff, 0x00,
    0xff, {0x00, 0x00}, {0x02, 0x00}, {0x00, 0x00, 0x20, 0x00}, 0x20}
  },
  {"ATmega8515",
   {0x00, 0xD7, 0xA0, 0x00},
   {0x42, 0x63, 0x00, 0x00, 0x01, 0x01, 0x01, 0x01, 0x02, 0xff, 0xff, 0xff,
    0xff, {0x00, 0x40}, {0x02, 0x00}, {0x00, 0x00, 0x20, 0x00}, 0x20}
  },
  {"ATmega8535",
   {0x00, 0xD7, 0xA0, 0x00},
   {0x42, 0x64, 0x00, 0x00, 0x01, 0x01, 0x01, 0x01, 0x02, 0xff, 0xff, 0xff,
    0xff, {0x00, 0x40}, {0x02, 0x00}, {0x00, 0x00, 0x20, 0x00}, 0x20}
  },
  {"ATtiny11",
   {0x00, 0xD7, 0xA0, 0x00},
   {0x42, 0x11, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x01, 0x00, 0x00, 0x00,
    0x00, {0x00, 0x00}, {0x00, 0x00}, {0x00, 0x00, 0x04, 0x00}, 0x20}
  },
  {"ATtiny12",
   {0x00, 0xD7, 0xA0, 0x01},
   {0x42, 0x12, 0x00, 0x00, 0x00, 0x01, 0x01, 0x01, 0x01, 0xff, 0xff, 0xff,
    0xff, {0x00, 0x00}, {0x00, 0x40}, {0x00, 0x00, 0x04, 0x00}, 0x20}
  },
  {"ATtiny15",
   {0x00, 0xD7, 0xA0, 0x01},
   {0x42, 0x13, 0x00, 0x00, 0x00, 0x01, 0x01, 0x01, 0x01, 0xff, 0xff, 0xff,
    0xff, {0x00, 0x00}, {0x00, 0x40}, {0x00, 0x00, 0x04, 0x00}, 0x20}
  },
  {"ATtiny22",
   {0x00, 0xD7, 0xA0, 0x00},
   {0x42, 0x20, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x01, 0xff, 0xff, 0x00,
    0xff, {0x00, 0x00}, {0x00, 0x80}, {0x00, 0x00, 0x08, 0x00}, 0x20}
  },
  {"ATtiny26",
   {0x04, 0xD7, 0xA0, 0x01},
   {0x42, 0x21, 0x01, 0x00, 0x01, 0x01, 0x01, 0x01, 0x02, 0xff, 0xff, 0xff,
    0xff, {0x00, 0x20}, {0x00, 0x80}, {0x00, 0x00, 0x08, 0x00}, 0x20}
  },
  {"ATtiny28",
   {0x00, 0xD7, 0xA0, 0x00},
   {0x42, 0x22, 0x00, 0x00, 0x01, 0x00, 0x01, 0x01, 0x01, 0x00, 0x00, 0x00,
    0x00, {0x00, 0x00}, {0x00, 0x00}, {0x00, 0x00, 0x08, 0x00}, 0x20}
  },
  {"ATmega8",
   {0x04, 0xD7, 0xA0, 0x01},
   {0x42, 0x70, 0x00, 0x00, 0x01, 0x01, 0x01, 0x01, 0x02, 0xff, 0xff, 0xff,
    0xff, {0x00, 0x40}, {0x02, 0x00}, {0x00, 0x00, 0x20, 0x00}, 0x20}
  },
  {"ATmega323",
   {0x00, 0xD7, 0xA0, 0x00},
   {0x42, 0x90, 0x00, 0x00, 0x01, 0x01, 0x01, 0x01, 0x02, 0xff, 0xff, 0xff,
    0xff, {0x00, 0x80}, {0x04, 0x00}, {0x00, 0x00, 0x80, 0x00}, 0x20}
  },
  {"ATmega32",
   {0x04, 0xD7, 0xA0, 0x00},
   {0x42, 0x91, 0x00, 0x00, 0x01, 0x01, 0x01, 0x01, 0x02, 0xff, 0xff, 0xff,
    0xff, {0x00, 0x80}, {0x04, 0x00}, {0x00, 0x00, 0x80, 0x00}, 0x20}
  },
  // FIXME: add mega64
  {"ATmega161",
   {0x00, 0xD7, 0xA0, 0x00},
   {0x42, 0x80, 0x00, 0x00, 0x01, 0x01, 0x01, 0x01, 0x01, 0xff, 0xff, 0xff,
    0xff, {0x00, 0x80}, {0x02, 0x00}, {0x00, 0x00, 0x40, 0x00}, 0x20}
  },
  {"ATmega163",
   {0x00, 0xD7, 0xA0, 0x00},
   {0x42, 0x81, 0x00, 0x00, 0x01, 0x01, 0x01, 0x01, 0x02, 0xff, 0xff, 0xff,
    0xff, {0x00, 0x80}, {0x02, 0x00}, {0x00, 0x00, 0x40, 0x00}, 0x20}
  },
  {"ATmega16",
   {0x04, 0xD7, 0xA0, 0x00},
   {0x42, 0x82, 0x00, 0x00, 0x01, 0x01, 0x01, 0x01, 0x02, 0xff, 0xff, 0xff,
    0xff, {0x00, 0x80}, {0x02, 0x00}, {0x00, 0x00, 0x40, 0x00}, 0x20}
  },
  {"ATmega162",
   {0x04, 0xD7, 0xA0, 0x00},
   {0x42, 0x83, 0x00, 0x00, 0x01, 0x01, 0x01, 0x01, 0x03, 0xff, 0xff, 0xff,
    0xff, {0x00, 0x80}, {0x02, 0x00}, {0x00, 0x00, 0x40, 0x00}, 0x20}
  },
  {"ATmega169",
   {0x04, 0xD7, 0xA0, 0x01},
   {0x42, 0x84, 0x00, 0x00, 0x01, 0x01, 0x01, 0x01, 0x03, 0xff, 0xff, 0xff,
    0xff, {0x00, 0x80}, {0x02, 0x00}, {0x00, 0x00, 0x40, 0x00}, 0x20}
  },
  {"ATmega103",
   {0x00, 0xA0, 0xD7, 0x00},
   {0x42, 0xb1, 0x00, 0x00, 0x01, 0x00, 0x00, 0x01, 0x02, 0x00, 0x00, 0x00,
    0x00, {0x01, 0x00}, {0x10, 0x00}, {0x00, 0x02, 0x00, 0x00}, 0x20}
  },
  {"ATmega128",
   {0x08, 0xD7, 0xA0, 0x00},
   {0x42, 0xb2, 0x00, 0x00, 0x01, 0x01, 0x01, 0x01, 0x03, 0xff, 0xff, 0xff,
    0xff, {0x01, 0x00}, {0x10, 0x00}, {0x00, 0x02, 0x00, 0x00}, 0x20}
  },
  // FIXME: add at86rf401, at89s51, at89s52
  {"", {0,0,0,0},{0,0,0,0, 0,0,0,0, 0,0,0,0, 0, {0}, {0}, {0}, 0}}
};

/* Get a stk500 parameter value */

TByte
TStk500::ReadParam(TByte param)
{
  TByte buf[0x80];

  TByte rd_param[] = { 0x41, param, 0x20 };
  TByte rd_param_reply[] = { 0x14, '?', 0x10 };

  memcpy(buf, rd_param, sizeof(rd_param));
  Send(buf, sizeof(rd_param), sizeof(rd_param_reply));

  if ((buf[0] != rd_param_reply[0]) || (buf[2] != rd_param_reply[2]))
  {
      throw Error_Device ("Failed to read parameter", pNodename);
  }

  return buf[1];
}

/* Set a stk500 parameter value */

void
TStk500::WriteParam(TByte param, TByte val)
{
  TByte buf[0x80];

  TByte wr_param[] = { 0x40, param, val, 0x20 };
  TByte wr_param_reply[] = { 0x14, 0x10 };

  memcpy(buf, wr_param, sizeof(wr_param));
  Send(buf, sizeof(wr_param), sizeof(wr_param_reply));

  if (memcmp(buf, wr_param_reply, sizeof(wr_param_reply)) != 0)
  {
      throw Error_Device ("Failed to write parameter", pNodename);
  }
}

/* Read byte from active segment at address addr. */
TByte TStk500::ReadByte(TAddr addr)
{
  TByte val = 0xff;

  if (segment == SEG_FUSE)
  {
    switch (addr) 
    {
      case AVR_FUSE_LOW_ADDR:
        if (TestFeatures(AVR_FUSE_RD))
          val = ReadFuseLowBits();
        else
          Info (1, "Cannot read low fuse bits on this device. "
                "Returning 0xff\n");
        break;

      case AVR_FUSE_HIGH_ADDR:
        if (TestFeatures(AVR_FUSE_HIGH))
          val = ReadFuseHighBits();
        else
          Info (1, "Cannot read high fuse bits on this device. "
                "Returning 0xff\n");
        break;

      case AVR_CAL_ADDR:
        if (TestFeatures(AVR_CAL_RD))
          val = ReadCalFuseBits(0);
        else
          Info (1, "Cannot read calibration byte on this device. "
                "Returning 0xff\n");
        break;

      case AVR_LOCK_ADDR:
        val = ReadLockBits();
        break;

      case AVR_FUSE_EXT_ADDR:
        if (TestFeatures(AVR_FUSE_EXT))
          val = ReadFuseExtBits();
        else
          Info (1, "Cannot read extended fuse bits on this device. "
                "Returning 0xff\n");
        break;
    }
  }
  else
  {
    /* FIXME: TRoth/2002-05-29: This is still broken. If flash or eeprom
       changes after the calling ReadMem(), you won't ever see the change. */

    // Xbow: the original STK500 version reads all 128K of Atmega memory
    // before checking. This takes ~15sec on the mib510. This version reads
    // a 256 byte page. If a new 256 byte page is needed then it retreives
    // it from the mib510

    if (read_buffer[segment] == NULL) {
      page =  addr >> 8;                                  //page number
      read_buffer[segment] = new TByte[GetSegmentSize()]; //create buffer for data
      ReadMemPage(addr & 0xfff00);                        //read the page
    }
    int new_page = addr >> 8;
    if (new_page != page){
      page = new_page;
      ReadMemPage(addr & 0xfff00);
    }   
    val = read_buffer[segment][addr];
  }
  return val;
}

/* Write byte to active segment */
void TStk500::WriteByte(TAddr addr, TByte byte, bool flush_buffer)
{
  if (segment == SEG_FUSE)
  {
    switch (addr) 
    {
      case AVR_FUSE_LOW_ADDR:
        if (TestFeatures(AVR_FUSE_RD))
          WriteFuseLowBits(byte);
        else
          Info (1, "Cannot write low fuse bits on this device.\n");
        break;

      case AVR_FUSE_HIGH_ADDR:
        if (TestFeatures(AVR_FUSE_HIGH))
          WriteFuseHighBits(byte);
        else
          Info (1, "Cannot write high fuse bits on this device.\n");
        break;

      case AVR_CAL_ADDR:
        /* Calibration byte is always readonly. */
        break;

      case AVR_LOCK_ADDR:
        WriteLockBits(byte);
        break;

      case AVR_FUSE_EXT_ADDR:
        if (TestFeatures(AVR_FUSE_EXT))
          WriteFuseExtBits(byte);
        else
          Info (1, "Cannot read extended fuse bits on this device.\n");
        break;
    }
  }
  else
  {
    if (write_buffer[segment] == NULL) {
      write_buffer[segment] = new TByte[GetSegmentSize()];
      minaddr = GetSegmentSize();
      memset(write_buffer[segment], 0xff, GetSegmentSize());
    }

    if (addr > maxaddr)
      maxaddr = addr;

    if (addr < minaddr)
      minaddr = addr;

    write_buffer[segment][addr] = byte;

    if (flush_buffer) {
      FlushWriteBuffer();
    }
  }
}


void TStk500::FlushWriteBuffer(){
  TByte buf[0x200];
  int wordsize;
  TAddr addr;
  TByte seg;
  const TByte *pgsz;
  int pagesize;

  if (segment == SEG_FLASH) {
    wordsize = 2;
    seg = Flash;
  } else {
    wordsize = 1;
    seg = EEPROM;
  }

  pgsz = prg_part[desired_part].params.pagesize;
  pagesize = (pgsz[0]) << 8 + pgsz[1];

  if (pagesize == 0) {
    pagesize = 128;
  }

  EnterProgrammingMode();

  addr = 0;
  for (unsigned int addr=minaddr; addr<maxaddr; addr+=pagesize) {
    memcpy(buf, SetAddress, sizeof(SetAddress));
    buf[1] = (addr/wordsize) & 0xff;
    buf[2] = ((addr/wordsize) >> 8) & 0xff;
    Send(buf, sizeof(SetAddress), sizeof(SetAddress_Reply));
    if (memcmp(buf, SetAddress_Reply, sizeof(SetAddress_Reply)) != 0) {
      throw Error_Device ("[FWB 1] Device is not responding correctly.", pNodename); }

    memcpy(buf, WriteMemory, sizeof(WriteMemory));
    buf[1] = pagesize >> 8;
    buf[2] = pagesize & 0xff;
    buf[3] = seg;
    memcpy(buf+sizeof(WriteMemory), write_buffer[segment]+addr, pagesize);
    memcpy(buf+sizeof(WriteMemory)+pagesize,
       CmdStopByte, sizeof(CmdStopByte));
    Send(buf, sizeof(WriteMemory)+pagesize+sizeof(CmdStopByte),
     sizeof(WriteMemory_Reply));
    if (memcmp(buf, WriteMemory_Reply, sizeof(WriteMemory_Reply)) != 0) {
      throw Error_Device ("[FWB 2] Device is not responding correctly.", pNodename); }
  }   
  LeaveProgrammingMode();
}


/* Chip Erase */
void TStk500::ChipErase(){
  TByte buf[100];

  EnterProgrammingMode();

  memcpy(buf, EraseDevice, sizeof(EraseDevice));
  Send(buf, sizeof(EraseDevice), sizeof(EraseDevice_Reply));
  if (memcmp(buf, EraseDevice_Reply, sizeof(EraseDevice_Reply)) != 0) {
    throw Error_Device ("[CE] Device is not responding correctly.",  pNodename); }

  LeaveProgrammingMode();
}


TByte TStk500::ReadLockFuseBits()
{
  TByte cmd[] = { 0x58, 0x00, 0x00, 0x00 };

  return UniversalCmd(cmd);
}


/* ReadLockBits tries to return the lock bits in a uniform order, despite the
   differences in different AVR versions.  The goal is to get the lock bits
   into this order:
       x x BLB12 BLB11 BLB02 BLB01 LB2 LB1
   For devices that don't support a boot block, the BLB bits will be 1. */

TByte TStk500::ReadLockBits()
{
  TByte rbits = 0xFF;
  if (TestFeatures(AVR_LOCK_BOOT)) {
    /* x x BLB12 BLB11 BLB02 BLB01 LB2 LB1 */
    rbits = ReadLockFuseBits();
  } else if (TestFeatures(AVR_LOCK_RD76)) {
    rbits = ReadLockFuseBits();
    /* LB1 LB2 x x x x x x -> 1 1 1 1 1 1 LB2 LB1 */
    rbits = ((rbits >> 7) & 1) | ((rbits >> 5) & 1) | 0xFC;
  } else if (TestFeatures(AVR_LOCK_RD12)) {
    rbits = ReadLockFuseBits();
    /* x x x x x LB2 LB1 x -> 1 1 1 1 1 1 LB2 LB1 */
    rbits = ((rbits >> 1) & 3) | 0xFC;
  } else {
    /* if its signature returns 0,1,2 then say it's locked. */
    EnterProgrammingMode();
    ReadSignature();
    LeaveProgrammingMode();
    if (vendor_code == 0 &&
        part_family == 1 &&
        part_number == 2)
    {
      rbits = 0xFC;
    }
    else
    {
      throw Error_Device ("ReadLockBits failed: are you sure this device "
                          "has lock bits?", pNodename);
    }
  }
  return rbits;
}


TByte TStk500::ReadCalFuseBits(int addr)
{
  TByte cmd[] = { 0xc8, 0x00, addr, 0x00 };

  return UniversalCmd(cmd);
}


TByte TStk500::ReadFuseLowBits()
{
  TByte cmd[] = { 0x50, 0x00, 0x00, 0x00 };

  return UniversalCmd(cmd);
}


TByte TStk500::ReadFuseHighBits()
{
  TByte cmd[] = { 0x58, 0x08, 0x00, 0x00 };

  return UniversalCmd(cmd);
}


TByte TStk500::ReadFuseExtBits()
{
  TByte cmd[] = { 0x50, 0x08, 0x00, 0x00 };

  return UniversalCmd(cmd);
}


void TStk500::WriteLockFuseBits(TByte bits)
{
  TByte cmd[] = { 0xac, 0xff, 0xff, bits };

  UniversalCmd(cmd);
}


void TStk500::WriteFuseLowBits(TByte bits)
{
  TByte cmd[] = { 0xac, 0xa0, 0xff, bits };

  UniversalCmd(cmd);
}


void TStk500::WriteFuseHighBits(TByte bits)
{
  TByte cmd[] = { 0xac, 0xa8, 0xff, bits };

  UniversalCmd(cmd);
}


void TStk500::WriteFuseExtBits(TByte bits)
{
  TByte cmd[] = { 0xac, 0xa4, 0xff, bits };

  UniversalCmd(cmd);
}


/*
   0 = program (clear bit), 1 = leave unchanged
   bit 0 = LB1
   bit 1 = LB2
   bit 2 = BLB01
   bit 3 = BLB02
   bit 4 = BLB11
   bit 5 = BLB12
   bit 6 = 1 (reserved)
   bit 7 = 1 (reserved)
 */
void TStk500::WriteLockBits(TByte bits)
{
  TByte wbits;
  if (TestFeatures(AVR_LOCK_BOOT))
  {
    /* x x BLB12 BLB11 BLB02 BLB01 LB2 LB1 */
    wbits = bits;
  }
  else if (TestFeatures(AVR_LOCK_RD76))
  {
    /* x x x x x x LB2 LB1 -> LB1 LB2 1 1 1 1 1 1 */
    wbits = ((bits << 7) & 0x80) | ((bits << 5) & 0x40) | 0x3f;
  }
  else if (TestFeatures(AVR_LOCK_RD12))
  {
    /* x x x x x x LB2 LB1 -> 1 1 1 1 1 LB2 LB1 1 */
    wbits = ((bits << 1) & 0x06) | 0xF9;
  }
  else
  {
    Info (0, "WriteLockBits failed: are you sure this device has lock bits?");
    return;
  }
  WriteLockFuseBits(wbits);
}

void TStk500::Initialize()
{
  TByte buf[100];
  TByte vmajor;
  TByte vminor;

  TByte num_ext_parms = 3;
  bool bMIB510 = false;

  //----------------- XBOW mod for MIB510, cmd MIB510 to control RS232 lines----
  if (bMIB510 = strcmp(GetCmdParam("-dprog"), "mib510") == 0) {
    int itry= 5;      //try 5 times
    while (itry > 0){
      itry--;
      memcpy(buf, IspMode, sizeof(IspMode));
      buf[8] =  1;
      SendOnly(buf, sizeof(IspMode));
      try {
	Send(buf, sizeof(IspMode), sizeof(IspMode_Reply), 1);
	if (memcmp(buf, IspMode_Reply, sizeof(IspMode_Reply)) == 0) itry = 0;
      }
      catch (Error_Device e) {
      }
    }

    memcpy(buf, IspMode, sizeof(IspMode));
    buf[8] =  1;
    Send(buf, sizeof(IspMode), sizeof(IspMode_Reply));
    if (memcmp(buf, IspMode_Reply, sizeof(IspMode_Reply)) != 0) {
      throw Error_Device ("Device is not responding correctly.",pNodename); }
  }
//-----------------------------------------------------------------------------

  memcpy(buf, pSTK500, sizeof(pSTK500));
  Send(buf, sizeof(pSTK500), sizeof(pSTK500_Reply));
  if (memcmp(buf, pSTK500_Reply, sizeof(pSTK500_Reply)) != 0) {
    throw Error_Device ("[VP 1] Device is not responding correctly.", pNodename); }

  memcpy(buf, &prg_part[desired_part].params,
     sizeof(prg_part[desired_part].params));

  Send(buf, sizeof(prg_part[desired_part].params),
       sizeof(DeviceParam_Reply));
  if (memcmp(buf, DeviceParam_Reply, sizeof(DeviceParam_Reply)) != 0) {
    throw Error_Device ("[VP 2] Device is not responding correctly.", pNodename); }
  

  memcpy(buf, SWminor, sizeof(SWminor));
  Send(buf, sizeof(SWminor), sizeof(SWminor_Reply));
  vminor = buf[1];

  memcpy(buf, SWmajor, sizeof(SWmajor));
  Send(buf, sizeof(SWmajor), sizeof(SWmajor_Reply));
  vmajor = buf[1];
  
  if (bMIB510){
    printf ("Firmware Version: %c.%c\n", vmajor, vminor);
    return;
  }

  printf ("Firmware Version: %d.%d\n", vmajor, vminor);

#if 0
  if (! ((vmajor == 1 && vminor >= 7) || (vmajor > 1)))
    throw Error_Device ("Need STK500 firmware version 1.7 or newer.", pNodename);
#endif

  if ((vmajor == 1 && vminor >= 14) || (vmajor > 1))
      num_ext_parms = 4;

  buf[0] = 0x45;
  buf[1] = num_ext_parms;
  memcpy(buf+2, &prg_part[desired_part].ext_params, num_ext_parms);
  buf[num_ext_parms+2] = 0x20;
  Send(buf, num_ext_parms+3, sizeof(ExtDevParams_Reply));
  if (memcmp(buf, ExtDevParams_Reply, sizeof(ExtDevParams_Reply)) != 0) {
    throw Error_Device ("[VP 3] Device is not responding correctly.", pNodename); }
}

void TStk500::Cleanup() {
  TByte buf[100];

  //----------------- XBOW mod for MIB510, cmd MIB510 to release RS232 lines
  if (strcmp(GetCmdParam("-dprog"), "mib510") == 0)  {
    memcpy(buf, IspMode, sizeof(IspMode));
    buf[8] =  0;
    Send(buf, sizeof(IspMode), sizeof(IspMode_Reply));
    if (memcmp(buf, IspMode_Reply, sizeof(IspMode_Reply)) != 0) {
      throw Error_Device ("Device is not responding correctly.",pNodename); }
  }
}

void TStk500::EnterProgrammingMode() {
  TByte buf[100];

  memcpy(buf, EnterPgmMode, sizeof(EnterPgmMode));
  Send(buf, sizeof(EnterPgmMode), sizeof(EnterPgmMode_Reply));
  if (memcmp(buf, EnterPgmMode_Reply, sizeof(EnterPgmMode_Reply)) != 0) {
    throw Error_Device ("Failed to enter programming mode.", pNodename); }
}


void TStk500::LeaveProgrammingMode() {
  TByte buf[100];

  memcpy(buf, LeavePgmMode, sizeof(LeavePgmMode));
  Send(buf, sizeof(LeavePgmMode), sizeof(LeavePgmMode_Reply));
  if (memcmp(buf, LeavePgmMode_Reply, sizeof(LeavePgmMode_Reply)) != 0) {
    throw Error_Device ("[LPM] Device is not responding correctly.", pNodename); }
}


/* TRoth/2002-05-28: A Universal Command seems to be just the 4 bytes of an
   SPI command. I'm basing this on my interpretation of the doc/README.stk500
   and Table 129 of the mega128 datasheet (page 300). */

TByte TStk500::UniversalCmd(TByte cmd[])
{
  TByte buf[6] = { 0x56, 0x00, 0x00, 0x00, 0x00, 0x20 };

  memcpy(buf+1, cmd, 4);

  EnterProgrammingMode();

  /* Expected response is { 0x14, <output>, 0x10 } */
  Send(buf, sizeof(buf), 3);

  LeaveProgrammingMode();

  if ((buf[0] != 0x14) || (buf[2] != 0x10))
  {
    throw Error_Device ("[UC] Device is not responding correctly.", pNodename);
  }

  return buf[1];
}


void TStk500::ReadSignature() {
  TByte buf[100];

  memcpy(buf, GetSignature, sizeof(GetSignature));
  Send(buf, sizeof(GetSignature), sizeof(GetSignature_Reply));
  
  vendor_code = buf[1];
  part_family = buf[2];
  part_number = buf[3];
}

//mib510: read 256 bytes of flash memory starting at addr
void TStk500::ReadMemPage(TAddr  addr){
  TByte buf[0x200];
  int wordsize;
  TByte seg;

  if (segment == SEG_FLASH) {
    wordsize = 2;
    seg = Flash;
  } else if (segment == SEG_EEPROM) {
    wordsize = 1;
    seg = EEPROM;
  } else {
    throw Error_Device ("TStk500::ReadMemPage() called for invalid segment.",pNodename);
  }

  EnterProgrammingMode();
 
  memcpy(buf, SetAddress, sizeof(SetAddress));
  buf[1] = (addr/wordsize) & 0xff;
  buf[2] = ((addr/wordsize) >> 8) & 0xff;
  Send(buf, sizeof(SetAddress), sizeof(SetAddress_Reply));
  if (memcmp(buf, SetAddress_Reply, sizeof(SetAddress_Reply)) != 0) {
      throw Error_Device ("Device is not responding correctly.",pNodename); }
   
  memcpy(buf, ReadMemory, sizeof(ReadMemory));
  buf[3] = seg;
  Send(buf, sizeof(ReadMemory), 2+0x100);

  memcpy(read_buffer[segment]+addr, buf+1, 0x100);
  

  LeaveProgrammingMode();
}
void TStk500::ReadMem(){
  TByte buf[0x200];
  int wordsize;
  TAddr addr;
  TByte seg;

  if (segment == SEG_FLASH) {
    wordsize = 2;
    seg = Flash;
  } else if (segment == SEG_EEPROM) {
    wordsize = 1;
    seg = EEPROM;
  } else {
    throw Error_Device ("TStk500::ReadMem() called for invalid segment.",pNodename);
  }

  read_buffer[segment] = new TByte[GetSegmentSize()];

  EnterProgrammingMode();

  addr = 0;
  for (unsigned int addr=0; addr<GetSegmentSize(); addr+=0x100) {
    memcpy(buf, SetAddress, sizeof(SetAddress));
    buf[1] = (addr/wordsize) & 0xff;
    buf[2] = ((addr/wordsize) >> 8) & 0xff;
    Send(buf, sizeof(SetAddress), sizeof(SetAddress_Reply));
    if (memcmp(buf, SetAddress_Reply, sizeof(SetAddress_Reply)) != 0) {
      throw Error_Device ("[RM] Device is not responding correctly.", pNodename); }
   
    memcpy(buf, ReadMemory, sizeof(ReadMemory));
    buf[3] = seg;
    Send(buf, sizeof(ReadMemory), 2+0x100);

    memcpy(read_buffer[segment]+addr, buf+1, 0x100);
  }

  LeaveProgrammingMode();
}

static TByte
convert_voltage (const char *val)
{
    char *endptr;
    double v = strtod (val, &endptr);
    if (endptr == val)
        throw Error_Device ("Bad voltage value.");
    if (v > 6.0)
        throw Error_Device ("Voltages can not be greater than 6.0 volts");
    if (v < 0.0)
        throw Error_Device ("Voltages can not be less the 0.0 volts");

    TByte res = (int)(v * 10.01);

    return res;
}

TStk500::TStk500() {
  /* Select Part by name */
  desired_part=-1;
  const char* desired_partname = GetCmdParam("-dpart");
  pNodename = GetCmdParam("-dhost");
  if (desired_partname!=NULL) {
    int j;
    for (j=0; prg_part[j].name[0] != 0; j++){
      if (strcasecmp (desired_partname, prg_part[j].name)==0){
    desired_part = j;
    break;
      }
    }
    if (prg_part[j].name[0]==0){throw Error_Device("-dpart: Invalid name.",pNodename);}
  } else {
    int i = 0;
    Info(0, "No part specified, supported devices are:\n");
    while (prg_part[i].name[0] != '\0')
      Info(0, "%s\n", prg_part[i++].name);
    throw Error_Device("");
  }

  /* Force parallel programming mode if the use wants it, otherwise, just use
     what the device prefers (usually serial programming). */

  if (GetCmdParam("-dparallel",false))
      prg_part[desired_part].params.progtype = STK500_PROG_PARALLEL;

  Initialize();

  /* Handle Reading/Writing ARef voltage level. */

  const char *val;

  if ((val=GetCmdParam("--wr_vtg", true)))
  {
      TByte value = convert_voltage (val);
      printf ("Setting VTarget to %d.%d V\n", value/10, value%10);

      TByte aref = ReadParam(0x85);
      if (aref > value)
      {
          printf ("Setting ARef == VTarget to avoid damaging device.\n");
          WriteParam(0x85, value);
      }

      WriteParam(0x84, value);
  }

  if ((val=GetCmdParam("--wr_aref", true)))
  {
      TByte value = convert_voltage (val);
      printf ("Setting ARef to %d.%d V\n", value/10, value%10);

      TByte vtg = ReadParam(0x84);
      if (vtg < value)
      {
          printf ("Setting ARef == VTarget to avoid damaging device.\n");
          WriteParam(0x84, value);
      }

      WriteParam(0x85, value);
  }

  if (GetCmdParam("--rd_vtg", false))
  {
      TByte val = ReadParam(0x84);
      printf("VTarget = %d.%d V\n", val/10, val%10);
  }

  if (GetCmdParam("--rd_aref", false))
  {
      TByte val = ReadParam(0x85);
      printf("ARef = %d.%d V\n", val/10, val%10);
  }

  EnterProgrammingMode();
  ReadSignature();
  LeaveProgrammingMode();
  Identify();

  write_buffer[SEG_FLASH] = NULL;
  write_buffer[SEG_EEPROM] = NULL;

  read_buffer[SEG_FLASH] = NULL;
  read_buffer[SEG_EEPROM] = NULL;

  maxaddr = 0;
}


TStk500::~TStk500() {
  Cleanup();
  delete write_buffer[SEG_FLASH];
  delete write_buffer[SEG_EEPROM];

  delete read_buffer[SEG_FLASH];
  delete read_buffer[SEG_EEPROM];
}
