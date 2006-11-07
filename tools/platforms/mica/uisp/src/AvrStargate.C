// $Id: AvrStargate.C,v 1.3 2006-11-07 19:30:42 scipio Exp $

/*
 * $Id: AvrStargate.C,v 1.3 2006-11-07 19:30:42 scipio Exp $
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

#include "config.h"

#include "timeradd.h"
#include "AvrStargate.h"

/* Private Functions
*/

void TAvrStargate::EnableAvr(){
  unsigned char prg  [4] = { 0xAC, 0x53, 0, 0 };
  int try_number = 32;
  bool no_retry = GetCmdParam("-dno-retry", false);
  const char *part_name = GetCmdParam("-dpart");

  if (part_name && strcasecmp(part_name, "at90s1200") == 0)
    no_retry = true;  /* XXX */

  /* Enable AVR programming mode */
  do{
    prg[0]=0xAC; prg[1]=0x53; prg[2]=prg[3]=0;
    Send(prg, 4);
    if (no_retry) break;
    if (prg[2] == 0x53) break;
    PulseSck();
  } while (try_number--);
  
  if (try_number>=0){
    Info(2,"AVR Stargate SSP Access succeeded after %d retries.\n", 
      32-try_number);
  } else {
    Info(2,"AVR Stargate SSP Access failed after 32 retries.\n");
  }
  
  /* Get AVR Info */
  vendor_code = GetPartInfo(0);
  part_family = GetPartInfo(1);
  part_number = GetPartInfo(2);

  if (part_name)
    OverridePart(part_name);

  Identify();
}

TByte
TAvrStargate::GetPartInfo(TAddr addr)
{
  TByte info [4] = { 0x30, 0, addr, 0 };
  Send(info, 4);
  return info[3];
}

void
TAvrStargate::WriteProgramMemoryPage()
{
  struct timeval t_start_wr, t_start_poll, t_wait, t_timeout, t_end, t_write;

  bool poll_data = use_data_polling && TestFeatures(AVR_PAGE_POLL)
		   && (page_poll_byte != 0xFF);

  TByte prg_page [4] = { 0x4C,
			(TByte)((page_addr >> 9) & 0xff),
			(TByte)((page_addr >> 1) & 0xff),
			0 };

  gettimeofday(&t_start_wr, NULL);
  t_wait.tv_sec = 0;
  t_wait.tv_usec = Get_t_wd_flash();

  Info(4, "Programming page address: %d (%.2x, %.2x, %.2x, %.2x)\n", 
    page_addr, prg_page[0], prg_page[1], prg_page[2], prg_page[3]);
  Send(prg_page, 4);

  gettimeofday(&t_start_poll, NULL);
  timeradd(&t_start_poll, &t_wait, &t_timeout);

  /* Wait */
  do {
    gettimeofday(&t_end, NULL);
    if (poll_data) {
      TByte rbyte = ReadByte(page_poll_addr);
      if (rbyte == page_poll_byte)
	break;
    }
  } while (timercmp(&t_end, &t_timeout, <));

  /* Write Statistics */
  timersub(&t_end, &t_start_wr, &t_write);  /* t_write = t_end - t_start_wr */
  if (poll_data) {
    float write_time = 1.0e-6 * t_write.tv_usec + t_write.tv_sec;
    total_poll_time += write_time;
    if (max_poll_time < write_time)
      max_poll_time = write_time;
    if (min_poll_time > write_time)
      min_poll_time = write_time;
    total_poll_cnt++;
  }

  page_addr_fetched=false;
  page_poll_byte = 0xFF;
}


/* Device Interface Functions
*/

TByte
TAvrStargate::ReadByte(TAddr addr)
{
  TByte readback = 0xFF;
    
  CheckMemoryRange(addr);
  if (segment == SEG_FLASH) {
    TByte hl = (addr & 1) ? 0x28 : 0x20;
    TByte flash[4] = { hl,
		       (TByte)((addr >> 9) & 0xff),
		       (TByte)((addr >> 1) & 0xff),
			 0 };
    Send(flash, 4);
    readback = flash[3];
  } else if (segment == SEG_EEPROM) {
    TByte eeprom [4] = { 0xA0, 
			 (TByte)((addr>>8)&0xff), 
			 (TByte)(addr&0xff), 
			 0 };
    Send(eeprom, 4);
    readback = eeprom[3];
  } else if (segment==SEG_FUSE) {
    switch (addr) {
    case AVR_FUSE_LOW_ADDR:
      if (TestFeatures(AVR_FUSE_RD))
	readback = ReadFuseLowBits();
#if 0
      /* TRoth/2002-06-03: This case is handled by ReadLockBits() so we don't
         need it here. Can I delete it completely? */
      else if (TestFeatures(AVR_LOCK_RD76))
	readback = ReadLockFuseBits();
#endif
      break;
    case AVR_FUSE_HIGH_ADDR:
      if (TestFeatures(AVR_FUSE_HIGH))
	readback = ReadFuseHighBits();
      break;
    case AVR_CAL_ADDR:
      if (TestFeatures(AVR_CAL_RD))
	readback = ReadCalByte(0);
      break;
    case AVR_LOCK_ADDR:
      readback = ReadLockBits();
      break;
    case AVR_FUSE_EXT_ADDR:
      if (TestFeatures(AVR_FUSE_EXT))
	readback = ReadFuseExtBits();
    }
    Info(3, "Read fuse/cal/lock: byte %d = 0x%02X\n",
	 (int) addr, (int) readback);
  }
  return readback;
}

/*
 Read Lock/Fuse Bits:           7     6     5     4     3     2     1     0
 2333,4433,m103,m603,tn12,tn15: x     x     x     x     x     LB2   LB1   x
 2323,8535:                     LB1   LB2   SPIEN x     x     x     x     FSTRT
 2343:                          LB1   LB2   SPIEN x     x     x     x     RCEN
 tn22:                          LB1   LB2   SPIEN x     x     x     x     0
 m161,m163,m323,m128:           x     x     BLB12 BLB11 BLB02 BLB01 LB2   LB1
 tn26:                          x     x     x     x     x     x     LB2   LB1
 */
TByte
TAvrStargate::ReadLockFuseBits()
{
  TByte lockfuse[4] = { 0x58, 0, 0, 0 };
  Send(lockfuse, 4);
  return lockfuse[3];
}

/*
 Read Fuse Bits (Low):          7     6     5     4     3     2     1     0
 2333,4433:                     x     x     SPIEN BODLV BODEN CKSL2 CKSL1 CKSL0
 m103,m603:                     x     x     SPIEN x     EESAV 1     SUT1  SUT0
 tn12:                          BODLV BODEN SPIEN RSTDI CKSL3 CKSL2 CKSL1 CKSL0
 tn15:                          BODLV BODEN SPIEN RSTDI x     x     CKSL1 CKSL0
 m161:                          x     BTRST SPIEN BODLV BODEN CKSL2 CKSL1 CKSL0
 m163,m323:                     BODLV BODEN x     x     CKSL3 CKSL2 CKSL1 CKSL0
 m8,m16,m32,m64,m128:           BODLV BODEN SUT1  SUT0  CKSL3 CKSL2 CKSL1 CKSL0
 tn26:                          PLLCK CKOPT SUT1  SUT0  CKSL3 CKSL2 CKSL1 CKSL0
 */
TByte
TAvrStargate::ReadFuseLowBits()
{
  TByte fuselow[4] = { 0x50, 0, 0, 0 };
  Send(fuselow, 4);
  return fuselow[3];
}

/*
 Read Fuse Bits High:           7     6     5     4     3     2     1     0
 m163:                          x     x     x     x     1     BTSZ1 BTSZ0 BTRST
 m323:                          OCDEN JTGEN x     x     EESAV BTSZ1 BTSZ0 BTRST
 m16,m32,m64,m128:              OCDEN JTGEN SPIEN CKOPT EESAV BTSZ1 BTSZ0 BTRST
 m8:                            RSTDI WDTON SPIEN CKOPT EESAV BTSZ1 BTSZ0 BTRST
 tn26:                          1     1     1     RSTDI SPIEN EESAV BODLV BODEN
 */
TByte
TAvrStargate::ReadFuseHighBits()
{
  TByte fusehigh[4] = { 0x58, 0x08, 0, 0 };
  Send(fusehigh, 4);
  return fusehigh[3];
}

/*
 Read Extended Fuse Bits:       7     6     5     4     3     2     1     0
 m64,m128:                      x     x     x     x     x     x     M103C WDTON
 */
TByte
TAvrStargate::ReadFuseExtBits()
{
  TByte fuseext[4] = { 0x50, 0x08, 0, 0 };
  Send(fuseext, 4);
  return fuseext[3];
}

/* Read Calibration Byte (m163, m323, m128, tn12, tn15, tn26)
   addr=0...3 for tn26, addr=0 for other devices */
TByte
TAvrStargate::ReadCalByte(TByte addr)
{
  TByte cal[4] = { 0x38, 0, addr, 0 };
  Send(cal, 4);
  return cal[3];
}

/*
 Write Fuse Bits (old):         7     6     5     4     3     2     1     0
 2323,8535:                     x     x     x     1     1     1     1     FSTRT
 2343:                          x     x     x     1     1     1     1     RCEN
 2333,4433:                     x     x     x     BODLV BODEN CKSL2 CKSL1 CKSL0
 m103,m603:                     x     x     x     1     EESAV 1     SUT1  SUT0
 */
void
TAvrStargate::WriteOldFuseBits(TByte val)
{
  TByte oldfuse[4] = { 0xAC, (val & 0x1F) | 0xA0, 0, 0xD2 };
  Send(oldfuse, 4);
}

/*
 Write Fuse Bits (Low, new):    7     6     5     4     3     2     1     0
 m161:                          1     BTRST 1     BODLV BODEN CKSL2 CKSL1 CKSL0
 m163,m323:                     BODLV BODEN 1     1     CKSL3 CKSL2 CKSL1 CKSL0
 m8,m16,m64,m128:               BODLV BODEN SUT1  SUT0  CKSL3 CKSL2 CKSL1 CKSL0
 tn12:                          BODLV BODEN SPIEN RSTDI CKSL3 CKSL2 CKSL1 CKSL0
 tn15:                          BODLV BODEN SPIEN RSTDI 1     1     CKSL1 CKSL0
 tn26:                          PLLCK CKOPT SUT1  SUT0  CKSL3 CKSL2 CKSL1 CKSL0

 WARNING (tn12,tn15): writing SPIEN=1 disables further low voltage programming!
 */
void
TAvrStargate::WriteFuseLowBits(TByte val)
{
  TByte fuselow[4] = { 0xAC, 0xA0, 0, val };
  Send(fuselow, 4);
}

/*
 Write Fuse Bits High:          7     6     5     4     3     2     1     0
 m163:                          1     1     1     1     1     BTSZ1 BTSZ0 BTRST
 m323:                          OCDEN JTGEN 1     1     EESAV BTSZ1 BTSZ0 BTRST
 m16,m64,m128:                  OCDEN JTGEN x     CKOPT EESAV BTSZ1 BTSZ0 BTRST
 m8:                            RSTDI WDTON x     CKOPT EESAV BTSZ1 BTSZ0 BTRST
 tn26:                          1     1     1     RSTDI SPIEN EESAV BODLV BODEN
 */
void
TAvrStargate::WriteFuseHighBits(TByte val)
{
  TByte fusehigh[4] = { 0xAC, 0xA8, 0, val };
  Send(fusehigh, 4);
}

/*
 Write Extended Fuse Bits:      7     6     5     4     3     2     1     0
 m64,m128:                      x     x     x     x     x     x     M103C WDTON
 */
void
TAvrStargate::WriteFuseExtBits(TByte val)
{
  TByte fuseext[4] = { 0xAC, 0xA4, 0, val };
  Send(fuseext, 4);
}


void
TAvrStargate::WriteByte(TAddr addr, TByte byte, bool flush_buffer)
{
  struct timeval t_start_wr, t_start_poll, t_wait, t_timeout, t_end, t_write;
  TByte rbyte=0;
  bool device_not_erased=false;
  
  /* Poll data if use_data_polling is enabled and if page mode
     is enabled, flash is not selected */
  bool poll_data = ((segment==SEG_FLASH && !page_size) || segment==SEG_EEPROM)
		   && use_data_polling && TestFeatures(AVR_BYTE_POLL);

  CheckMemoryRange(addr);
  
  /* For speed, don't program a byte that is already there
     (such as 0xFF after chip erase).  */
  if (poll_data){
    rbyte=ReadByte(addr);
    if (rbyte == byte){return;}
    if (rbyte != 0xff){device_not_erased=true;}
  }
  
  t_wait.tv_sec = 0;
  t_wait.tv_usec = 500000;

  gettimeofday(&t_start_wr, NULL);

  if (segment==SEG_FLASH){
      
    /* PAGE MODE PROGRAMMING:
       If page mode is enabled cache page address.
       When current address is out of the page address
       flush page buffer and continue programming.
    */
    if (page_size) {
      Info(4, "Loading data to address: %d (page_addr_fetched=%s)\n", 
        addr, page_addr_fetched?"Yes":"No");
	
      if (page_addr_fetched && page_addr != (addr & ~(page_size - 1))){
        WriteProgramMemoryPage();	
      }
      if (page_addr_fetched==false){
        page_addr=addr & ~(page_size - 1);
	page_addr_fetched=true;
      }
      if (flush_buffer){WriteProgramMemoryPage();}
    }

    TByte hl = (addr & 1) ? 0x48 : 0x40;
    TByte flash [4] = { hl,
			(TByte)((addr >> 9) & 0xff),
			(TByte)((addr >> 1) & 0xff),
			byte };
    Send(flash, 4);

    /* Remember the last non-0xFF byte written, for page write polling.  */
    if (byte != 0xFF) {
      page_poll_addr = addr;
      page_poll_byte = byte;
    }

    /* We do not need to wait for each byte in page mode programming */
    if (page_size){return;}    
    t_wait.tv_usec = Get_t_wd_flash();
  }
  else if (segment==SEG_EEPROM){
    TByte eeprom [4] = { 0xC0, 
			 (TByte)((addr>>8)&0xff), 
			 (TByte)(addr&0xff),
			 byte };
    Send(eeprom, 4);  
    t_wait.tv_usec = Get_t_wd_eeprom();    
  }
  else if (segment==SEG_FUSE) {
    Info(3, "Write fuse/lock: byte %d = 0x%02X\n",
	 (int) addr, (int) byte);
    switch (addr) {
    case AVR_FUSE_LOW_ADDR:
      if (TestFeatures(AVR_FUSE_NEWWR))
	WriteFuseLowBits(byte);
      else if (TestFeatures(AVR_FUSE_OLDWR))
	WriteOldFuseBits(byte);
      break;
    case AVR_FUSE_HIGH_ADDR:
      if (TestFeatures(AVR_FUSE_HIGH))
	WriteFuseHighBits(byte);
      break;
    case AVR_CAL_ADDR:
      /* calibration byte (addr == 2) is read only */
      break;
    case AVR_LOCK_ADDR:
      WriteLockBits(byte);
      break;
    case AVR_FUSE_EXT_ADDR:
      if (TestFeatures(AVR_FUSE_EXT))
	WriteFuseExtBits(byte);
    }
    t_wait.tv_usec = Get_t_wd_eeprom();
  }

  gettimeofday(&t_start_poll, NULL);
  /* t_timeout = now + t_wd_prog */
  timeradd(&t_start_poll, &t_wait, &t_timeout);

  do {
    /* Data Polling: if the programmed value reads correctly, and
       is not equal to any of the possible P1, P2 read back values,
       it is done; else wait until tWD_PROG time has elapsed.
       The busy loop here is to avoid rounding up the programming
       wait time to 10ms timer ticks (for Linux/x86).  Programming
       is not really "hard real time" but 10ms instead of ~4ms for
       every byte makes it slow.  gettimeofday() reads the 8254
       timer registers (or Pentium cycle counter if available),
       so it has much better (microsecond) resolution.  
    */
    gettimeofday(&t_end, NULL);
    if (poll_data){
      if ((byte == (rbyte = ReadByte(addr))) &&
          (byte != 0) && (byte != 0x7F) && (byte != 0x80) && (byte != 0xFF)){
	break;
      }
    }
  } while (timercmp(&t_end, &t_timeout, <));
  
  /* Write Statistics */
  timersub(&t_end, &t_start_wr, &t_write);  /* t_write = t_end - t_start_wr */
  if (poll_data) {
    float write_time = 1.0e-6 * t_write.tv_usec + t_write.tv_sec;
    total_poll_time += write_time;
    if (max_poll_time < write_time)
      max_poll_time = write_time;
    if (min_poll_time > write_time)
      min_poll_time = write_time;
    total_poll_cnt++;
  }

  if (poll_data && byte != rbyte){
    if (device_not_erased){
      Info(0, "Warning: It seems that device is not erased.\n"
              "         Erase it with the --erase option.\n");
    }
    Info(0, "Error: Data polling readback status: write=0x%02x read=0x%02x\n", 
      byte, rbyte);
    throw Error_Device("If device was erased disable polling with the "
      "-dno-poll option.");
  }
}

void
TAvrStargate::FlushWriteBuffer()
{
  if (page_addr_fetched){
    WriteProgramMemoryPage();  
  }
}

void
TAvrStargate::ChipErase()
{
  TByte init[4] = { 0xAC, 0x53, 0x00, 0x00 };
  TByte chip_erase [4] = { 0xAC, 0x80, 0x00, 0x00 };
  Info(1, "Erasing device ...\n");
  Send(init, 4);
  Send(chip_erase, 4);
  Delay_usec(Get_t_wd_erase());
  Delay_usec(Get_t_wd_erase());
  Delay_usec(9000);
  Delay_usec(9000);
  PulseReset();
  Delay_usec(9000);
  Info(1, "Reinitializing device\n");  
  EnableAvr();
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
void
TAvrStargate::WriteLockBits(TByte bits)
{
  /* This handles both old (byte 2, bits 1-2)
     and new (byte 4, bits 0-5) devices.  */
  TByte lock[4] = { 0xAC, 0xF9 | ((bits << 1) & 0x06), 0xFF, bits };
  TByte rbits;

  Info(1, "Writing lock bits ...\n");
  Send(lock, 4);
  Delay_usec(Get_t_wd_erase());
  PulseReset();
  Info(1, "Reinitializing device\n");
  EnableAvr();
  rbits = ReadLockBits();
  if (rbits & ~bits)
    Info(0, "Warning: lock bits write=0x%02X read=0x%02X\n",
	 (int) bits, (int) rbits);
}

TByte
TAvrStargate::ReadLockBits()
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
  } else if (GetPartInfo(0) == 0 &&
	     GetPartInfo(1) == 1 &&
	     GetPartInfo(2) == 2) {
    rbits = 0xFC;
  } else throw Error_Device ("ReadLockBits failed: are you sure this device has lock bits?");
  return rbits;
}

unsigned int
TAvrStargate::GetPollCount()
{
  return total_poll_cnt;
}

float
TAvrStargate::GetMinPollTime()
{
  return min_poll_time;
}

float
TAvrStargate::GetMaxPollTime()
{
  return max_poll_time;
}

float
TAvrStargate::GetTotPollTime()
{
  return total_poll_time;
}

void
TAvrStargate::ResetMinMax()
{
  min_poll_time = 1.0;
  max_poll_time = 0.0;
  total_poll_time = 0.0;
  total_poll_cnt = 0;
}

/* Constructor
*/

TAvrStargate::TAvrStargate():
  use_data_polling(true)
{
  ResetMinMax();
  
  /* Device Command line options ... */ 
  if (GetCmdParam("-dno-poll", false)){use_data_polling=false;} 
  
  EnableAvr();
}

/* eof */
