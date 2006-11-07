// $Id: Avr.C,v 1.3 2006-11-07 19:30:42 scipio Exp $

/*
 * $Id: Avr.C,v 1.3 2006-11-07 19:30:42 scipio Exp $
 *
 ****************************************************************************
 *
 * uisp - The Micro In-System Programmer for Atmel AVR microcontrollers.
 * Copyright (C) 1999, 2000, 2001, 2002, 2003  Uros Platise
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
	Avr.C
	
	Top class of the AVR micro controllers 
	Uros Platise (c) 1999
*/

#include "config.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include "Avr.h"
#include "Error.h"

#define TARGET_MISSING 0xff
#define DEVICE_LOCKED  0x1

/* ATMEL AVR codes */
TAvr::TPart TAvr::parts [] = {
  /* device         sig. bytes   flash page EEPROM twdFL twdEE  flags */
  { "AT90S1200",    0x90, 0x01,   1024,   0,   64,  4000, 4000, AVR_1200 },

  { "ATtiny12",     0x90, 0x05,   1024,   0,   64,  1700, 3400, AVR_TN12 },
  { "ATtiny15",     0x90, 0x06,   1024,   0,   64,  2000, 4000, AVR_TN15 },
#if 0
  /* 12V serial programming only; here just for the evidence */
  /* ATtiny10 = QuickFlash(TM) OTP */
  { "ATtiny10",     0x90, 0x03,   1024,   0,    0,  8000,    0, 0 },
  { "ATtiny11",     0x90, 0x04,   1024,   0,    0,  8000,    0, 0 },
#endif

  { "AT90S2313",    0x91, 0x01,   2048,   0,  128,  4000, 4000, AVR_2313 },
  { "AT90S2343",    0x91, 0x03,   2048,   0,  128,  4000, 4000, AVR_8535 },
  { "AT90S2323",    0x91, 0x02,   2048,   0,  128,  4000, 4000, AVR_8535 },

  /* no longer in production?  2333 -> 4433, tiny22 -> 2343? */
  { "AT90S2333",    0x91, 0x05,   2048,   0,  128,  4000, 4000, AVR_4433 },
  { "ATtiny22",     0x91, 0x06,   2048,   0,  128,  4000, 4000, AVR_TN22 },

  { "ATtiny26",     0x91, 0x09,   2048,  32,  128,  4500, 9000, AVR_TN26 },

#if 0
  /* 12V parallel programming only; here just for the evidence */
  { "ATtiny28",     0x91, 0x07,   2048,   0,    0,  8000,    0, 0 },
#endif

  { "AT90S4433",    0x92, 0x03,   4096,   0,  256,  4000, 4000, AVR_4433 },

  /* no longer in production? -> use 8515, 8535 instead */
  { "AT90S4414",    0x92, 0x01,   4096,   0,  256,  4000, 4000, AVR_2313 },
  { "AT90S4434",    0x92, 0x02,   4096,   0,  256,  4000, 4000, AVR_8535 },

  { "AT90S8515",    0x93, 0x01,   8192,   0,  512,  4000, 4000, AVR_2313 },
  { "AT90S8535",    0x93, 0x03,   8192,   0,  512,  4000, 4000, AVR_8535 },

#if 0
  /* aka AT90S8555 - probably doesn't exist, use ATmega8535 */
  { "ATmega83",     0x93, 0x05,   8192, 128,  512, 11000, 4000, AVR_M163 },
#endif

  { "ATmega8515",   0x93, 0x06,   8192,  64,  512,  4500, 9000, AVR_M163 },
  { "ATmega8",      0x93, 0x07,   8192,  64,  512,  4500, 9000, AVR_M163 },
  { "ATmega8535",   0x93, 0x08,   8192,  64,  512,  4500, 9000, AVR_M163 },

#if 0
  /* 12V parallel programming only; here just for the evidence */
  { "AT90C8534",    0x93, 0x04,   8192,   0,  512,  8000, 4000, 0 }, 
#endif

  { "ATmega161",    0x94, 0x01,  16384, 128,  512, 11000, 4000, AVR_M161 },
  { "ATmega163",    0x94, 0x02,  16384, 128,  512, 15000, 3800, AVR_M163 },
  { "ATmega16",     0x94, 0x03,  16384, 128,  512,  4500, 9000, AVR_M163 },
  { "ATmega162",    0x94, 0x04,  16384, 128,  512,  4500, 9000, AVR_M128 },
  { "ATmega169",    0x94, 0x05,  16384, 128,  512,  4500, 9000, AVR_M128 },

  { "ATmega323",    0x95, 0x01,  32768, 128, 1024, 15000, 3800, AVR_M163 },
  { "ATmega32",     0x95, 0x02,  32768, 128, 1024,  4500, 9000, AVR_M163 },

  { "ATmega64",     0x96, 0x02,  65536, 256, 2048,  4500, 9000, AVR_M128 },

  { "ATmega103",    0x97, 0x01, 131072, 256, 4096, 22000, 4000, AVR_M103 },
  { "ATmega128",    0x97, 0x02, 131072, 256, 4096,  4500, 9000, AVR_M128 },

  { "ATmega103-old",0x01, 0x01, 131072, 256, 4096, 22000, 4000, AVR_M103 },

#if 0
  { "ATmega603",    0x96, 0x01,  65536, 256, 2048, 22000, 4000, AVR_M103 },
  { "ATmega603-old",0x06, 0x01,  65536, 256, 2048, 22000, 4000, AVR_M103 },
#endif

#if 0 /* not yet */
  { "AT89S52",      0x52, 0x06,   8192,   0,    0,  1000,    0, AT89S52 },
#endif

  { "",          TARGET_MISSING, 0,  0,   0,    0,     0,    0, 0 },
  { "locked",    DEVICE_LOCKED,  0,  0,   0,    0,     0,    0, 0 },
  { "",          0x0,            0,  0,   0,    0,     0,    0, 0 }
};

const char* TAvr::segment_names[] = {"flash", "eeprom", "fuse", NULL};


/* Private Functions
*/

TAddr TAvr::GetWritePageSize(){
  if (device_locked){return 0;}
  assert(part!=NULL);
  return part->flash_page_size;
}

/* Protected Functions
*/

void TAvr::OverridePart(const char *part_name)
{
  int i;

  for (i = 0; parts[i].name[0]; i++) {
    if (strcasecmp(parts[i].name, part_name) == 0)
      break;
  }
  if (parts[i].name[0]) {
    if (vendor_code != 0x1e
	|| part_family != parts[i].part_family
	|| part_number != parts[i].part_number) {
      vendor_code = 0x1e;
      part_family = parts[i].part_family;
      part_number = parts[i].part_number;

      Info(3, "Override signature bytes, device %s assumed.\n",
	   parts[i].name);
    }
  } else
    throw Error_Device("Unknown device specified", part_name);
}

void TAvr::Identify()
{
  const char* vendor = "Device";

  Info(3, "Vendor Code: 0x%02x\nPart Family: 0x%02x\nPart Number: 0x%02x\n",
    vendor_code, part_family, part_number);  

  /* Identify AVR Part according to the vendor_code ... */
  if (vendor_code==0x1e){vendor = "Atmel AVR";}
  
  if (vendor_code==0 && part_family==DEVICE_LOCKED && part_number==0x02){
    device_locked=true;
    Info(0, "Cannot identify device because it is locked.\n");
    /* XXX hack to avoid "invalid parameter" errors if device is locked */
    GetCmdParam("-dt_wd_eeprom");
    GetCmdParam("-dt_wd_flash");
    GetCmdParam("-dvoltage");
#if 0
    return;
#endif
  } else{device_locked=false;}
  if (part_family==TARGET_MISSING){
    Info(0, "An error has occurred during the AVR initialization.\n"
	    " * Target status:\n"
	    "   Vendor Code = 0x%02x, Part Family = 0x%02x, Part Number = 0x%02x\n\n",
	    vendor_code, part_family, part_number);
    throw 
      Error_Device("Probably the wiring is incorrect or target"
        " might be `damaged'.");
  }
  int i,n;
  for(i=0; parts[i].part_family != 0x0; i++){
    if (part_family == parts[i].part_family){
      for (n=i; parts[n].part_family==part_family; n++){
        if (part_number == parts[n].part_number){i=n; break;}
      }
      if (i==n){Info(1, "%s %s is found.\n", vendor, parts[i].name);}
      else{Info(1, "%s similar to the %s is found.\n", vendor, parts[i].name);}
      part = &parts[i];
      break;
    }
  }
  if (parts[i].part_family == 0x0) {
    throw Error_Device ("Probably the AVR MCU is not in the RESET state.\n"
			"Check it out and run me again.");}

  if (!GetCmdParam("--download", false))
    SetWriteTimings();
}

/* This looks like a good approximation to make the device table simpler
   (only specify the 5V timings).  */

#define CALC_FLASH_T_wd(voltage) ((long) \
  ((part ? part->t_wd_flash_50 : 22000) * (5.0 * 5.0) / (voltage * voltage)))
#define CALC_EEPROM_T_wd(voltage) ((long) \
  ((part ? part->t_wd_eeprom_50 : 4000) * (5.0 * 5.0) / (voltage * voltage)))

void TAvr::SetWriteTimings(){
  const char* val;

  page_size = GetWritePageSize();
  if (page_size)
    Info(3, "Page Write Enabled, size=%d\n", (int) page_size);
  else
    Info(3, "Page Write Disabled\n");

  /* defaults */
  t_wd_flash = CALC_FLASH_T_wd(AVR_DEFAULT_VOLTAGE);
  t_wd_eeprom = CALC_EEPROM_T_wd(AVR_DEFAULT_VOLTAGE);  
    
  /* set FLASH write delay */  
  if ((val=GetCmdParam("-dt_wd_flash"))){
    t_wd_flash = atol(val);
    Info(0, "t_wd_flash = %ld\n", t_wd_flash);
    if (t_wd_flash < CALC_FLASH_T_wd(AVR_MAX_VOLTAGE)){
      Info(0, " * According to the Atmel specs the t_wd_flash\n"
              "   should be at least %ld us\n", 
	      CALC_FLASH_T_wd(AVR_MAX_VOLTAGE));
#if 0
      throw Error_Device("-dt_wd_flash: Value out of range.");
#endif
    }
  }
  
  /* set EEPROM write delay */  
  if ((val=GetCmdParam("-dt_wd_eeprom"))){
    t_wd_eeprom = atol(val);
    if (t_wd_eeprom < CALC_EEPROM_T_wd(AVR_MAX_VOLTAGE)){
      Info(0, " * According to the Atmel specs the t_wd_eeprom\n"
              "   should be at least %ld us\n", 
	      CALC_EEPROM_T_wd(AVR_MAX_VOLTAGE));
#if 0
      throw Error_Device("-dt_wd_eeprom: Value out of range.");
#endif
    }
  }

  /* Set Timings according to the Power Supply Voltage */
  if ((val=GetCmdParam("-dvoltage"))){
    double voltage = atof(val);
    if (voltage < AVR_MIN_VOLTAGE || voltage > AVR_MAX_VOLTAGE){
      Info(0, " * Atmel AVR MCUs operate in range from %.1f to %.1f V\n",
           AVR_MIN_VOLTAGE, AVR_MAX_VOLTAGE);
	   
      throw Error_Device("-dvoltage: Value out of range.");
    }
    
    t_wd_flash = CALC_FLASH_T_wd(voltage);
    t_wd_eeprom = CALC_EEPROM_T_wd(voltage);
  }
  
  Info(3, "FLASH Write Delay (t_wd_flash): %ld us\n"
          "EEPROM Write Delay (t_wd_eeprom): %ld us\n",
	  t_wd_flash, t_wd_eeprom);
}

const char* TAvr::GetPartName(){
  return part->name;
}

TAddr
TAvr::GetSegmentSize()
{
  switch (segment) {
  case SEG_FLASH: return part->flash_size;
  case SEG_EEPROM: return part->eeprom_size;
  case SEG_FUSE: return 5;
  }
  throw Error_MemoryRange();
}

bool
TAvr::TestFeatures(unsigned int mask)
{
  return ((part->flags & mask) == mask);
}

void TAvr::CheckMemoryRange(TAddr addr){
  if (device_locked){
    Info(0, "Device is locked.\n");
    throw Error_MemoryRange();
  }
  if (addr >= GetSegmentSize()) {
    throw Error_MemoryRange();
  }
}

long TAvr::Get_t_wd_flash() const {
  return t_wd_flash;
}

long TAvr::Get_t_wd_eeprom() const {
  return t_wd_eeprom;
}

long TAvr::Get_t_wd_erase() const{
#if 0
  return 3*t_wd_flash;	/* right factor is 2, but just in case */
#else
  /* Device might be locked and not possible to identify, assume 200ms
     which should be long enough for any device, and is not that long
     compared to the program time itself.  */
  return 200000;
#endif
}

/* Device Interface Functions
*/

bool TAvr::SetSegment(const char* segment_name){
  for (int i=0; segment_names[i]!=NULL; i++){
    if (strcmp(segment_names[i], segment_name)==0){
      segment=i; 
      return true;
    }
  }
  return false;
}

const char* TAvr::TellActiveSegment(){
  return segment_names[segment];
}

const char* TAvr::ListSegment(unsigned index){
  if (index>3){return NULL;}
  return segment_names[index];
}

const char* TAvr::ReadByteDescription(TAddr addr){
  static const char* no_desc = "No description available.";
  CheckMemoryRange(addr);
  return no_desc;
}

/* Constructor/Destructor
*/

TAvr::TAvr():
  part(NULL), 
  page_size(0), page_addr_fetched(false),
  page_poll_byte(0xFF),
  segment(SEG_FLASH){
}

TAvr::~TAvr(){
}
