// $Id: AvrAtmel.C,v 1.3 2006-11-07 19:30:42 scipio Exp $

/*
 * $Id: AvrAtmel.C,v 1.3 2006-11-07 19:30:42 scipio Exp $
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
	AvrAtmel.C
	
	Device driver for the Serial Atmel Low Cost Programmer
	Uros Platise (c) 1999
*/

#include "config.h"

#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "AvrAtmel.h"

#define AUTO_SELECT	0

/* Low Cost Atmel Programmer AVR Codes
   Valid for software version: SW_MAJOR=2 SW_MINOR=0
   
   Code 0xff is reserved for invalid code. Update the
   TAvrAtmel constructor if Atmel comes up with it.

   The list is current as of AVRProg 1.37 (shipped with AVR Studio 3.54).
*/
TAvrAtmel::SPrgPart TAvrAtmel::prg_part [] = {
  {"S1200A", 0x10, "AT90S1200 rev. A", false}, /* old */
  {"S1200B", 0x11, "AT90S1200 rev. B", false}, /* old */
  {"S1200C", 0x12, "AT90S1200 rev. C", false}, /* old */
  {"S1200",  0x13, "AT90S1200", false},
  {"S2313",  0x20, "AT90S2313", false},
  {"S4414",  0x28, "AT90S4414", false},
  {"S4433",  0x30, "AT90S4433", false},
  {"S2333",  0x34, "AT90S2333", false},
  {"S8515",  0x38, "AT90S8515", false},
  {"M8515",  0x3A, "ATmega8515", false},
  {"M8515b", 0x3B, "ATmega8515 BOOT", false},
  {"M103C",  0x40, "ATmega103 rev. C", false}, /* old */
  {"M103",   0x41, "ATmega103", false},
  {"M603",   0x42, "ATmega603", false},
  {"M128",   0x43, "ATmega128", false},
  {"M128b",  0x44, "ATmega128 BOOT", false},
  {"S2323",  0x48, "AT90S2323", false},
  {"S2343",  0x4C, "AT90S2343", false}, /* ATtiny22 too */
  {"TN11",   0x50, "ATtiny11",  false}, /* parallel */
  {"TN10",   0x51, "ATtiny10",  false}, /* parallel */
  {"TN12",   0x55, "ATtiny12",  false},
  {"TN15",   0x56, "ATtiny15",  false},
  {"TN19",   0x58, "ATtiny19",  false}, /* parallel */
  {"TN28",   0x5C, "ATtiny28",  false}, /* parallel */
  {"TN26",   0x5E, "ATtiny26",  false},
  {"M161",   0x60, "ATmega161", false},
  {"M161b",  0x61, "ATmega161 BOOT", false},
  {"M163",   0x64, "ATmega163", false},
  {"M83",    0x65, "ATmega83",  false}, /* ATmega8535 ??? */
  {"M163b",  0x66, "ATmega163 BOOT", false},
  {"M83b",   0x67, "ATmega83 BOOT", false},
  {"S8535",  0x68, "AT90S8535", false},
  {"S4434",  0x6C, "AT90S4434", false},
  {"C8534",  0x70, "AT90C8534", false}, /* parallel */
  {"C8544",  0x71, "AT90C8544", false}, /* parallel ??? */
  {"M32",    0x72, "ATmega32",  false}, /* XXX no ATmega323 */
  {"M32b",   0x73, "ATmega32 BOOT", false},
  {"M16",    0x74, "ATmega16",  false},
  {"M16b",   0x75, "ATmega16 BOOT", false},
  {"M8",     0x76, "ATmega8",   false},
  {"M8b",    0x77, "ATmega8 BOOT", false},
  {"89C1051",0x80, "AT89C1051", false}, /* parallel */
  {"89C2051",0x81, "AT89C2051", false}, /* parallel */
  {"89C51",  0x82, "AT89C51",   false}, /* parallel */
  {"89LV51", 0x83, "AT89LV51",  false}, /* parallel */
  {"89C52",  0x84, "AT89C52",   false}, /* parallel */
  {"89LV52", 0x85, "AT89LV52",  false}, /* parallel */
  {"S8252",  0x86, "AT89S8252", false},
  {"89S53",  0x87, "AT89S53",   false},
  /* 0x88..0xDF reserved for AT89,
     0xE0..0xFF reserved */
  {"auto",   AUTO_SELECT, "Auto detect", false},  
  {"",       0x00, "", false}
};

/* Private Functions
*/

void TAvrAtmel::EnterProgrammingMode(){
  /* Select Device Type */
  TByte set_device[2] = {'T', desired_avrcode};
  Send(set_device, 2, 1);
  CheckResponse(set_device[0]);

  /* Enter Programming Mode */
  TByte enter_prg[1] = {'P'};
  Send(enter_prg, 1);
  CheckResponse(enter_prg[0]);

  /* Read Signature Bytes */
  TByte sig_bytes[3] = {'s', 0, 0};
  Send(sig_bytes, 1, 3);
  part_number = sig_bytes[0];
  part_family = sig_bytes[1];
  vendor_code = sig_bytes[2];
}

void TAvrAtmel::LeaveProgrammingMode(){
  TByte leave_prg [1] = { 'L' };
  Send(leave_prg, 1);    
}

void TAvrAtmel::CheckResponse(TByte x){
  if (x!=13){throw Error_Device ("Device is not responding correctly.");}
}

void TAvrAtmel::EnableAvr(){
  bool auto_select = desired_avrcode == AUTO_SELECT;
  
  for (unsigned pidx=0; prg_part[pidx].code != AUTO_SELECT; pidx++){
  
    if (!prg_part[pidx].supported && auto_select){continue;}
    if (auto_select){
      desired_avrcode = prg_part[pidx].code;
      Info(2, "Trying with: %s\n", prg_part[pidx].description);
    }    
    EnterProgrammingMode();
    if (!auto_select ||
        !(vendor_code==0 && part_family==1 && part_number==2)){
      break;
    }
    LeaveProgrammingMode();    
  }

 // OverridePart("atmega163"); // XXXXX local hack for broken signature bytes
  
  Identify();
  
  if (auto_select){
    /* If avr was recongnized by the Identify(), try to find better match
       in the support list.
    */    
    unsigned better_pidx = 0;
    TByte better_avrcode = desired_avrcode;
    
    for (unsigned pidx=0; prg_part[pidx].code != AUTO_SELECT; pidx++){
      if (!prg_part[pidx].supported){continue;}      
      if (strstr(prg_part[pidx].description, GetPartName())){
        better_avrcode = prg_part[better_pidx = pidx].code;
      }
    }
    if (better_avrcode != desired_avrcode){
      Info(2, "Retrying with better match: %s\n", 
        prg_part[better_pidx].description);
      desired_avrcode = better_avrcode;
      LeaveProgrammingMode();
      EnterProgrammingMode();
      Identify();
    }
  }
}

void TAvrAtmel::SetAddress(TAddr addr){
  apc_address = addr;
  TByte setAddr [3] = { 'A', (addr>>8)&0xff, addr&0xff};
  Send(setAddr, 3, 1);
  CheckResponse(setAddr [0]);
}

void TAvrAtmel::WriteProgramMemoryPage(){
  SetAddress(page_addr >> 1);
  TByte prg_page [1] = { 'm' };
  Send(prg_page, 1);    
}

/* Device Interface Functions
*/

TByte TAvrAtmel::ReadByte(TAddr addr){
  CheckMemoryRange(addr);
  if (segment==SEG_FLASH){
    TAddr saddr = addr>>1;
    TByte rdF [2] = { 'R', 0 };
    
    if (buf_addr==addr && cache_lowbyte==true){return buf_lowbyte;}
    if (apc_address!=saddr || apc_autoinc==false) SetAddress(saddr);    
    apc_address++;
    Send(rdF, 1, 2);
    /* cache low byte */
    cache_lowbyte = true;
    buf_addr = (saddr<<1) + 1;
    buf_lowbyte = rdF[0];
    return rdF [1 - (addr&1)];
  }
  else if (segment==SEG_EEPROM){    
    SetAddress(addr);
    TByte readEE [1] = { 'd' };    
    Send(readEE, 1);
    return readEE[0];
  }
  else if (segment==SEG_FUSE) {
    TByte readback = 0xff;
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
      else
        Info (1, "Cannot read high fuse bits on this device. Returning 0xff\n");
      break;
    case AVR_CAL_ADDR:
      if (TestFeatures(AVR_CAL_RD))
        readback = ReadCalByte(0);
      else
        Info (1, "Cannot read calibration byte on this device. Returning 0xff\n");
      break;
    case AVR_LOCK_ADDR:
      readback = ReadLockBits();
      break;
    case AVR_FUSE_EXT_ADDR:
      if (TestFeatures(AVR_FUSE_EXT))
        readback = ReadFuseExtBits();
      else
        Info (1, "Cannot read extended fuse bits on this device. Returning 0xff\n");
      break;
    }
    Info(3, "Read fuse/cal/lock: byte %d = 0x%02X\n",
             (int) addr, (int) readback);
    return readback;
  }
  else return 0;
}

void TAvrAtmel::WriteByte(TAddr addr, TByte byte, bool flush_buffer){
  CheckMemoryRange(addr);
  
  /* do not check if byte is already written -- it spoils auto-increment
     feature which reduces the speed for 50%!
  */     
  if (segment==SEG_FLASH){
  
    cache_lowbyte = false;		/* clear read cache buffer */  
    if (!page_size && byte==0xff) return;
  
    /* PAGE MODE PROGRAMMING:
       If page mode is enabled cache page address.
       When current address is out of the page address
       flush page buffer and continue programming.
    */  
    if (page_size){
      Info(4, "Loading data to address: %d (page_addr_fetched=%s)\n", 
	addr, page_addr_fetched?"Yes":"No");

      if (page_addr_fetched && page_addr != (addr & ~(page_size - 1))){
	WriteProgramMemoryPage();
	page_addr_fetched = false;
      }
      if (page_addr_fetched==false){
	page_addr=addr & ~(page_size - 1);
	page_addr_fetched=true;
      }
      if (flush_buffer){WriteProgramMemoryPage();}
    }
    
    TByte wrF [2] = { (addr&1)?'C':'c', byte };
    
    if (apc_address!=(addr>>1) || apc_autoinc==false) SetAddress (addr>>1);
    if (wrF[0]=='C') apc_address++;
    Send(wrF, 2, 1);
    CheckResponse(wrF[0]);
  }
  else if (segment==SEG_EEPROM){
    SetAddress(addr);
    TByte writeEE [2] = { 'D', byte };
    Send(writeEE, 2, 1);
    CheckResponse(writeEE[0]);
  }  
  else if (segment==SEG_FUSE){
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
      else
        Info (1, "Cannot write high fuse bits on this device");
      break;
    /* calibration byte (addr == 2) is read only */
    case AVR_CAL_ADDR:
      Info (1, "Cannot write calibration byte. It is read-only.\n");
      break;
    case AVR_LOCK_ADDR:
      WriteLockBits(byte);
      break;
    case AVR_FUSE_EXT_ADDR:
      if (TestFeatures(AVR_FUSE_EXT))
	WriteFuseExtBits(byte);
    }
  }
}

/*
 Write Fuse Bits (old):         7     6     5     4     3     2     1     0
 2323,8535:                     x     x     x     1     1     1     1     FSTRT
 2343:                          x     x     x     1     1     1     1     RCEN
 2333,4433:                     x     x     x     BODLV BODEN CKSL2 CKSL1 CKSL0
 m103,m603:                     x     x     x     1     EESAV 1     SUT1  SUT0
 */
void TAvrAtmel::WriteOldFuseBits (TByte val)
{
  TByte buf[5] = {'.', 0xac, (val & 0x1f) | 0xa0, 0x00, 0xd2 };
  Info (2, "Write fuse high bits: %02x\n", (int)val);
  Send (buf, 5, 2);
  CheckResponse (buf[1]);
}

/*
 Write Fuse Bits (Low, new):    7     6     5     4     3     2     1     0
 m161:                          1     BTRST 1     BODLV BODEN CKSL2 CKSL1 CKSL0
 m163,m323:                     BODLV BODEN 1     1     CKSL3 CKSL2 CKSL1 CKSL0
 m8,m16,m64,m128:               BODLV BODEN SUT1  SUT0  CKSL3 CKSL2 CKSL1 CKSL0
 tn12:                          BODLV BODEN SPIEN RSTDI CKSL3 CKSL2 CKSL1 CKSL0
 tn15:                          BODLV BODEN SPIEN RSTDI 1     1     CKSL1 CKSL0

 WARNING (tn12,tn15): writing SPIEN=1 disables further low voltage programming!
 */
void TAvrAtmel::WriteFuseLowBits (TByte val)
{
  // use new universal command.
  TByte buf[5] = {'.', 0xac, 0xa0, 0x00, val };
  Info (2, "Write fuse high bits: %02x\n", (int)val);
  Send (buf, 5, 2);
  CheckResponse (buf[1]);
}

/*
 Write Fuse Bits High:          7     6     5     4     3     2     1     0
 m163:                          1     1     1     1     1     BTSZ1 BTSZ0 BTRST
 m323:                          OCDEN JTGEN 1     1     EESAV BTSZ1 BTSZ0 BTRST
 m16,m64,m128:                  OCDEN JTGEN x     CKOPT EESAV BTSZ1 BTSZ0 BTRST
 m8:                            RSTDI WDTON x     CKOPT EESAV BTSZ1 BTSZ0 BTRST
 */
void TAvrAtmel::WriteFuseHighBits (TByte val)
{
  // use new universal command.
  TByte buf[5] = {'.', 0xac, 0xa8, 0x00, val };
  Info (2, "Write fuse high bits: %02x\n", (int)val);
  Send (buf, 5, 2);
  CheckResponse (buf[1]);
}

/*
 Write Extended Fuse Bits:      7     6     5     4     3     2     1     0
 m64,m128:                      x     x     x     x     x     x     M103C WDTON
 */
void TAvrAtmel::WriteFuseExtBits (TByte val)
{
  // use new universal command.
  TByte buf[5] = {'.', 0xac, 0xa4, 0x00, val };
  Info (2, "Write fuse extended bits: %02x\n", (int)val);
  Send (buf, 5, 2);
  CheckResponse (buf[1]);
}


void TAvrAtmel::FlushWriteBuffer(){
  if (page_addr_fetched){
    WriteProgramMemoryPage();  
  }
}

/* Chip erase can take a few seconds when talking to a boot loader,
   which does it one page at a time.  */

#ifndef CHIP_ERASE_TIMEOUT
#define CHIP_ERASE_TIMEOUT 5
#endif

void TAvrAtmel::ChipErase(){
  TByte eraseTarget [1] = { 'e' };
  Send (eraseTarget, 1, -1, CHIP_ERASE_TIMEOUT);
  CheckResponse(eraseTarget [0]);
  Info(1, "Erasing device ...\nReinitializing device\n");
  EnableAvr();
}

void TAvrAtmel::WriteLockBits(TByte bits){
  TByte lockTarget [2] = { 'l', 0xF9 | ((bits << 1) & 0x06) };
  Send (lockTarget, 2, 1);
  CheckResponse(lockTarget [0]);
  Info(1, "Writing lock bits ...\nReinitializing device\n");
  EnableAvr();
}

TByte TAvrAtmel::ReadFuseLowBits ()
{
  // use new universal command.
  TByte buf[5] = {'.', 0x50, 0x00, 0x00, 0x00 };
  Send (buf, 5, 2);
  CheckResponse (buf[1]);
  Info (2, "Read fuse low bits: %02x\n", (int)buf[0]);
  return buf[0];
}

TByte TAvrAtmel::ReadFuseHighBits ()
{
  // use new universal command.
  TByte buf[5] = {'.', 0x58, 0x08, 0x00, 0x00 };
  Send (buf, 5, 2);
  CheckResponse (buf[1]);
  Info (2, "Read fuse high bits: %02x\n", (int)buf[0]);
  return buf[0];
}

TByte TAvrAtmel::ReadCalByte(TByte addr)
{
  // use new universal command.
  TByte buf[5] = {'.', 0x38, 0x00, addr, 0x00 };
  Send (buf, 5, 2);
  CheckResponse (buf[1]);
  Info (2, "Read calibration byte: %02x\n", (int)buf[0]);
  return buf[0];
}

TByte TAvrAtmel::ReadFuseExtBits ()
{
  // use new universal command.
  TByte buf[5] = {'.', 0x50, 0x08, 0x00, 0x00 };
  Send (buf, 5, 2);
  CheckResponse (buf[1]);
  return buf[0];
  Info (2, "Read extended fuse bits: %02x\n", (int)buf[0]);
  return buf[0];
}

TByte TAvrAtmel::ReadLockFuseBits ()
{
  // use new universal command.
  TByte buf[5] = {'.', 0x58, 0x00, 0x00, 0x00 };
  Send (buf, 5, 2);
  CheckResponse (buf[1]);
  Info (2, "Read lock bits: %02x\n", (int)buf[0]);
  return buf[0];
}

// ReadLockBits tries to return the lock bits in a uniform order, despite
// the differences in different AVR versions.  The goal is to get the lock 
// bits into this order:
//       x x BLB12 BLB11 BLB02 BLB01 LB2 LB1
// For devices that don't support a boot block, the BLB bits will be 1.
TByte
TAvrAtmel::ReadLockBits()
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
    // if its signature returns 0,1,2 then say it's locked.
    /* Read Signature Bytes */
    TByte sig_bytes[3] = {'s', 0, 0};
    Send(sig_bytes, 1, 3);
    if (sig_bytes[0]==0 && sig_bytes[1]==1 && sig_bytes[2]==2)
      rbits = 0xFC;
    else
      throw Error_Device ("ReadLockBits failed: are you sure this device has lock bits?");
  }
  return rbits;
}


/* Constructor/Destructor
*/

TAvrAtmel::TAvrAtmel():
  cache_lowbyte(false), apc_address(0x10000), apc_autoinc(false)
  {

  /* Select Part by Number or Name */
  desired_avrcode=0xff;
  const char* desired_partname = GetCmdParam("-dpart");
  bool got_device=false;
  
  if (desired_partname!=NULL) {
    if (desired_partname[0] >= '0' && desired_partname[0] <= '9'){
      desired_avrcode = strtol(&desired_partname[0],(char**)NULL,16); 
    } else{
      int j;
      for (j=0; prg_part[j].name[0] != 0; j++){
        if ((strcasecmp (desired_partname, prg_part[j].name)==0) ||
            (strcasecmp (desired_partname, prg_part[j].description)==0))
        {
	  desired_avrcode = prg_part[j].code;
	  break;
	}
      }
      if (prg_part[j].name[0]==0){throw Error_Device("-dpart: Invalid name.");}
    }
  }
  
  /* check: software version and supported part codes */
  TByte sw_version [2] = {'V', 0};
  TByte hw_version [2] = {'v', 0};
  Send(sw_version, 1, 2);
  Send(hw_version, 1, 2);
  Info(1, "Programmer Information:\n"
          "  Software Version: %c.%c, Hardware Version: %c.%c\n", 
	  sw_version [0], sw_version [1],
	  hw_version [0], hw_version [1]);
  
  /* Detect Auto-Increment */
  if (sw_version[0]>='2'){
    apc_autoinc=true;
    Info(2, "Address Auto Increment Optimization Enabled\n");
  }
  
  /* Retrieve supported codes */
  TByte sup_codes[1] = {'t'};
  Tx(sup_codes, 1);
  TByte buf_code;
  timeval timeout = {1, 0};
  if (desired_partname==NULL){
    Info(1, "  Supported Parts:\n\tNo\tAbbreviation\tDescription\n");
  }
  do{
    Rx(&buf_code, 1, &timeout);
    if (buf_code==0){break;}    
    if (desired_partname!=NULL){ 
      if (buf_code==desired_avrcode){got_device=true;}
      if (desired_avrcode!=AUTO_SELECT) continue; 
    }
    int j;
    for (j=0; prg_part[j].name[0] != 0; j++){
      if (prg_part[j].code == buf_code){
        prg_part[j].supported = true;
	if (desired_avrcode!=AUTO_SELECT){
	  Info(1, "\t%.2x\t%s\t\t%s\n", 
	    buf_code, prg_part[j].name, prg_part[j].description);
	}
	break;
      }
    }
    if (prg_part[j].code == 0) {
      Info(1, "    - %.2xh (not on the uisp's list yet)\n", buf_code);
    }
  } while (1);  
  Info(1, "\n");
  
  if (got_device==false) {
    if (desired_partname==NULL){
      throw Error_Device("Select a part from the list with the: -dpart\n"
        "or use the -dpart=auto option for auto-select.\n");
    } 
    else if (desired_avrcode!=AUTO_SELECT){
      throw Error_Device("Programmer does not supported chosen device.");
    }
  }
  
  EnableAvr();
}

TAvrAtmel::~TAvrAtmel(){
  /* leave programming mode! Due to this 
     procedure, enableAvr had to be taken out
     of TAtmelAvr::TAtmelAvr func. */
  LeaveProgrammingMode();
}
