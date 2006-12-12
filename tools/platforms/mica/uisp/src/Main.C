// $Id: Main.C,v 1.4 2006-12-12 18:23:01 vlahan Exp $

/*
 * $Id: Main.C,v 1.4 2006-12-12 18:23:01 vlahan Exp $
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
  Main.C

  Micro In-System Programmer
  Uros Platise (C) 1997-1999
*/

#include "config.h"

#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#include <exception>
#include "Terminal.h"
#include "MotIntl.h"
#include "AvrAtmel.h"
#include "Stk500.h"
#include "AvrStargate.h"
#ifndef NO_DAPA
# include "AvrDummy.h"
#endif

/* Globals
*/

int argc;
const char** argv;
char* argv_ok;
unsigned verbose_level;

PDevice device;
TMotIntl motintl;
TTerminal terminal;

const char* version = "uisp version %s\n"
"(C) 1997-1999 Uros Platise, 2000-2003 Marek Michalkiewicz\n"
"(c) 2003-2005 Philip Buonadonna, Intel Corporation\n"
"(c) 2003           ,        Crossbow Technology\n"
"\nuisp is free software, covered by the GNU General Public License.\n"
"You are welcome to change it and/or distribute copies of it under\n"
"the conditions of the GNU General Public License.\n\n";

const char* help_screen =
"Syntax: uisp [-v{=level}] [-h] [--help] [--version] [--hash=perbytes]\n"
"             [-dprog=avr910|pavr|stk500|mib510|stargate]"
#ifndef NO_DAPA
" [-dprog=type]\n"
"             [-dlpt=address|/dev/parportX] [-dno-poll] [-dno-retry]\n"
"             [-dvoltage=...] [-dt_sck=time] [-dt_wd_{flash|eeprom}=time]\n"
"             [-dt_reset=time] [-dinvert=sck,mosi,miso,reset]"
#endif
"\n"
"             [-dserial=device] [-dpart=name|no]\n"
"             [-dspeed=1200|2400|4800|9600|19200|38400|57600|115200]"
"\n"
"             [--upload] [--verify] [--erase] [if=input_file]\n"
"             [--download] [of=output_file]\n"
"             [--segment=flash|eeprom|fuse] [--terminal]\n"
"             [--rd_fuses] [--wr_fuse_l=byte] [--wr_fuse_h=byte]\n"
"             [--wr_fuse_e=byte] [--wr_lock=byte]\n\n"
"Programming Methods:\n"
"  -dprog=avr910    Standard Atmel Serial Programmer/Atmel Low Cost Programmer\n"
"         pavr      http://www.avr1.org/pavr/pavr.html\n"
"         stk500    Atmel STK500 or Atmel ATAVRISP\n"
"         mib510    Crossbow MIB510 (for Atmega128, 115200 baud serial only) \n"
"         stargate  PXA Based Stargate \n"
#ifndef NO_DAPA
"  -dprog=dapa|stk200|abb|avrisp|bsd|fbprg|dt006|maxi|xil|dasa|dasa2\n"
"       Programmer type:\n"
"         dapa      Direct AVR Parallel Access\n"
"         stk200    Parallel Starter Kit STK200, STK300\n"
"         abb       Altera ByteBlasterMV Parallel Port Download Cable\n"
"         avrisp    Atmel AVR ISP (?)\n"
"         bsd       http://www.bsdhome.com/avrdude/ (parallel)\n"
"         fbprg     http://ln.com.ua/~real/avreal/adapters.html (parallel)\n"
"         dt006     http://www.dontronics.com/dt006.html (parallel)\n"
"         maxi      Investment Technologies Maxi (parallel)\n"
"         xil       Xilinx HW-JTAG-PC Cable (parallel)\n"
"         ett       ETT AVR Programmer V2.0 [from Futurlec] (parallel)\n"
"         dasa      serial (RESET=RTS SCK=DTR MOSI=TXD MISO=CTS)\n"
"         dasa2     serial (RESET=!TXD SCK=RTS MOSI=DTR MISO=CTS)\n"
"\n"
"Target Device Selection:\n"
"  -dpart       Set  target abbreviated name or number. For some programmers, if\n"
"               -dpart is not given programmer's supported devices  are  listed.\n"
"               Set  -dpart=auto for auto-select. Auto-select does not work with\n"
"               all programmers, so it is recommended to always specify a target\n"
"               device explicitly.\n"
"\n"
"Parallel Device Settings:\n"
"  -dlpt=       specify device name (Linux ppdev, FreeBSD ppi, serial)\n"
#ifndef NO_DIRECT_IO
"               or direct I/O parallel port address (0x378, 0x278, 0x3BC)\n"
#endif
"  -dno-poll    Program without data polling (a little slower)\n"
"  -dno-retry   Disable retries of program enable command\n"
"  -dvoltage    Set timing specs according to the power supply voltage in [V]\n"
"               (default 3.0)\n"
"  -dt_sck      Set minimum SCK high/low time in micro-seconds (default 5)\n"
"  -dt_wd_flash Set FLASH maximum write delay time in micro-seconds\n"
"  -dt_wd_eeprom Set EEPROM maximum write delay time in micro-seconds\n"
"  -dt_reset    Set reset inactive (high) time in micro-seconds\n"
"  -dinvert=... Invert specified lines\n"
"               Use -v=3 option to see current settings.\n"
#endif
"\n"
"Atmel Low Cost Programmer Serial Device Settings:\n"
"  -dserial     Set serial interface as /dev/ttyS* (default /dev/avr)\n"
"  -dspeed      Set speed of the serial interface (default 19200)\n"
"  -dhost       IP Address or hostname of serial server. This option\n"
"               overrides the -dserial option\n"
"  -dport       Port number of the serial server (default 10001)\n"
"\n"
"Stk500 specific options:\n"
"  -dparallel   Use Hi-V parallel programming instead of serial (default is\n"
"               serial)\n"
"  --rd_aref    Read the ARef Voltage. Note that due to a bug in the\n"
"               stk500 firmware, the read value is sometimes off by 0.1\n"
"               from the actual value measured with a volt meter.\n"
"  --rd_vtg     Read the Vtarget Voltage. Note that due to a bug in the\n"
"               stk500 firmware, the read value is sometimes off by 0.1\n"
"               from the actual value measured with a volt meter.\n"
"  --wr_aref    Set the ARef Voltage. Valid values are 0.0 to 6.0 volts in\n"
"               0.1 volt increments. Value can not be larger than the\n"
"               VTarget value.\n"
"  --wr_vtg     Set the VTarget Voltage. Valid values are 0.0 to 6.0 volts in\n"
"               0.1 volt increments. Value can not be smaller than the\n"
"               ARef value.\n"
"\n"
"Functions:\n"
"  --upload     Upload \"input_file\" to the AVR memory.\n"
"  --verify     Verify \"input_file\" (processed after the --upload opt.)\n"
"  --download   Download AVR memory to \"output_file\" or stdout.\n"
"  --erase      Erase device.\n"
"  --segment    Set active segment (auto-select for AVA Motorola output)\n"
"\n"
"Fuse/Lock Bit Operations:\n"
"  --rd_fuses   Read all fuses and print values to stdout\n"
"  --wr_fuse_l  Write fuse low byte\n"
"  --wr_fuse_h  Write fuse high byte\n"
"  --wr_fuse_e  Write fuse extended byte\n"
"  --wr_lock    Write lock bits. Argument is a byte where each bit is:\n"
"                   Bit5 -> blb12\n"
"                   Bit4 -> blb11\n"
"                   Bit3 -> blb02\n"
"                   Bit2 -> blb01\n"
"                   Bit1 -> lb2\n"
"                   Bit0 -> lb1\n"
"  --lock       Write lock bits [old method; deprecated].\n" 
"\n"
"Files:\n"
"  if           Input file for the --upload and --verify functions in\n"
"               Motorola S-records (S1 or S2) or 16 bit Intel format\n"
"  of           Output file for the --download function in\n"
"               Motorola S-records format, default is standard output\n"
"\n"
"Other Options:\n"
"  -v           Set verbose level (-v equals -v=2, min/max: 0/4, default 1)\n"
"  --hash       Print hash (default is 32 bytes)\n"
"  --help -h    Help\n"
"  --version    Print version information\n"
"  --terminal   Invoke shell-like terminal\n"
"\n"
"Report bugs to: Maintainers <uisp-dev@nongnu.org>\n"
"Updates:        http://savannah.nongnu.org/projects/uisp\n";


/* Find command line parameter's value.
   It searches the command line parameters of the form:
   
	argv_name=value
	
   Returns pointer to the value. 
*/
const char* GetCmdParam(const char* argv_name, bool value_required)
{
  int argv_name_len = strlen(argv_name);
  for (int i=1; i<argc; i++){
    if (strncmp(argv_name, argv[i], argv_name_len)==0){
      if (argv[i][argv_name_len]==0){
        if (value_required){
	  throw Error_Device("Incomplete parameter", argv[i]);
	}
	argv_ok[i]=1;
        return &argv[i][argv_name_len];	
      }
      if (argv[i][argv_name_len]=='='){
        argv_ok[i]=1;
        return &argv[i][argv_name_len+1];
      }
    }
  }
  return NULL;
}

/* Print Status Information to the Standard Error Output.
*/
bool Info(unsigned _verbose_level, const char* fmt, ...){
  if (_verbose_level > verbose_level){return false;}
  va_list ap;
  va_start(ap,fmt); 
  vfprintf(stderr,fmt,ap);
  va_end(ap);
  return true;
}

static void cleanup_exception() {
  fprintf(stderr, "problem during cleanup - exiting\n");
  _exit(2);
}

int main(int _argc, const char* _argv[]){
  int return_val=0;
  argc = _argc;
  argv = _argv;
  verbose_level=1;  
  
  if (argc==1){
    Info(0, "%s: No commands specified. "
         "Try '%s --help' for list of commands.\n",
         argv[0], argv[0]);
    exit(1);
  }  
  argv_ok = (char *)malloc(argc);
  for (int i=1; i<argc; i++){argv_ok[i]=0;}    
  
  /* Help Screen? */
  if (GetCmdParam("-h", false) || GetCmdParam("--help", false)){
    printf(version, VERSION);
    printf("%s\n", help_screen);
    return 0;
  }
  if (GetCmdParam("--version", false)){
    printf(version, VERSION);
    return 0;
  }
  
  /* Setup Verbose Level */
  const char *p = GetCmdParam("-v",false);
  if (p!=NULL){
    if (*p==0){verbose_level=2;} else{verbose_level = atoi(p);}
  }

  /* Invoke Terminal or Command Line Batch Processing */
  try{
    const char* val;

    val = GetCmdParam("-dprog");
    /* backwards compatibility, -datmel is now -dprog=avr910 */
    if (GetCmdParam("-datmel", false))
      val = "avr910";
    // BBD: add check for NULL on -dprog
    if (val && (strcmp(val, "avr910") == 0 || strcmp(val, "pavr") == 0)) {
      /* Drop setuid privileges (if any - not recommended) before
	 trying to open the serial device, they are only needed for
	 direct I/O access (not ppdev/ppi) to the parallel port.  */
      setgid(getgid());
      setuid(getuid());
      device = new TAvrAtmel();
    }
    else if ( (val && (strcmp(val, "stk500") == 0)) || (val && (strcmp(val, "mib510") == 0))   ) {
      setgid(getgid());
      setuid(getuid());
      device = new TStk500();
    }
    else if (val && (strcmp(val, "stargate") == 0)) {
      device = new TAvrStargate();
    }
#ifndef NO_DAPA
    else if (val) {
      /* The TDAPA() constructor will drop setuid privileges after
         opening the lpt ioport. */
      device = new TAvrDummy();
    }
#endif

    /* Check Device's bad command line params. */
    for (int i=1; i<argc; i++){
      if (argv_ok[i]==0 && strncmp(argv[i], "-d", 2)==0){
        Info(0,"Invalid parameter: %s\n", argv[i]); exit(1);
      }
    }    
    if (device()==NULL){
      throw Error_Device("Programming method is not selected.");
    }

    /* Set Current Active Segment */
    if ((val=GetCmdParam("--segment"))!=NULL){
      if (!device->SetSegment(val)){
	Info(0, "--segment=%s: bad segment name\n", val);
      }
    }

    	/* Device Operations: */

    if (GetCmdParam("--download", false)) {
      motintl.Write(GetCmdParam("of"));
    }

    if (GetCmdParam("--erase", false)){device->ChipErase();}

    /* Input file */
    if ((val=GetCmdParam("if"))) {
      if (GetCmdParam("--upload", false)){motintl.Read(val, true, false);}
      if (GetCmdParam("--verify", false)){motintl.Read(val, false, true);}
    }

    if (GetCmdParam("--rd_fuses",false))
    {
      TByte bits;
      const char *old_seg = device->TellActiveSegment();
      device->SetSegment("fuse");

      printf("\n");
      printf("Fuse Low Byte      = 0x%02x\n", device->ReadByte(AVR_FUSE_LOW_ADDR));
      printf("Fuse High Byte     = 0x%02x\n", device->ReadByte(AVR_FUSE_HIGH_ADDR));
      printf("Fuse Extended Byte = 0x%02x\n", device->ReadByte(AVR_FUSE_EXT_ADDR));
      printf("Calibration Byte   = 0x%02x  --  Read Only\n",
             device->ReadByte(AVR_CAL_ADDR));

      bits = device->ReadByte(AVR_LOCK_ADDR);
      printf("Lock Bits          = 0x%02x\n", bits);
      printf("    BLB12 -> %d\n", ((bits & BLB12) == BLB12));
      printf("    BLB11 -> %d\n", ((bits & BLB11) == BLB11));
      printf("    BLB02 -> %d\n", ((bits & BLB02) == BLB02));
      printf("    BLB01 -> %d\n", ((bits & BLB01) == BLB01));
      printf("      LB2 -> %d\n", ((bits & LB2) == LB2));
      printf("      LB1 -> %d\n", ((bits & LB1) == LB1));

      printf("\n");

      device->SetSegment(old_seg);
    }

    if ((val=GetCmdParam("--wr_fuse_l")) != NULL)
    {
      unsigned int bits;
      const char *old_seg = device->TellActiveSegment();
      device->SetSegment("fuse");

      if (sscanf(val, "%x", &bits) == 1)
      {
        device->WriteByte( AVR_FUSE_LOW_ADDR, (TByte)bits );
        printf("\nFuse Low Byte set to 0x%02x\n", (TByte)bits);
      }
      else
        throw Error_Device("Invalid argument for --wr_fuse_l.");

      device->SetSegment(old_seg);
    }

    if ((val=GetCmdParam("--wr_fuse_h")) != NULL)
    {
      unsigned int bits;
      const char *old_seg = device->TellActiveSegment();
      device->SetSegment("fuse");

      if (sscanf(val, "%x", &bits) == 1)
      {
        device->WriteByte( AVR_FUSE_HIGH_ADDR, (TByte)bits );
        printf("\nFuse High Byte set to 0x%02x\n", (TByte)bits);
      }
      else
        throw Error_Device("Invalid argument for --wr_fuse_h.");

      device->SetSegment(old_seg);
    }

    if ((val=GetCmdParam("--wr_fuse_e")) != NULL)
    {
      unsigned int bits;
      const char *old_seg = device->TellActiveSegment();
      device->SetSegment("fuse");

      if (sscanf(val, "%x", &bits) == 1)
      {
        device->WriteByte( AVR_FUSE_EXT_ADDR, (TByte)bits );
        printf("\nFuse Extended Byte set to 0x%02x\n", (TByte)bits);
      }
      else
        throw Error_Device("Invalid argument for --wr_fuse_e.");

      device->SetSegment(old_seg);
    }

    if ((val=GetCmdParam("--wr_lock")) != NULL)
    {
      unsigned int bits;

      if (sscanf(val, "%x", &bits) == 1)
      {
        device->WriteLockBits( (TByte)bits );
        printf("\nLock Bits set to 0x%02x\n", (TByte)bits);
      }
      else
        throw Error_Device("Invalid argument for --wr_lock.");
    }

    if (GetCmdParam("--lock", false))
    {
      Info(0, "NOTE: '--lock' is deprecated. Used '--wr_lock' instead.\n");
      device->WriteLockBits(0xFC);
      printf("\nLock Bits set to 0x%02x\n", 0xfc);
    }

    	/* enter terminal */ 
	
    if (GetCmdParam("--terminal", false)){terminal.Run();}
    
    /* Check bad command line parameters */
    for (int i=1; i<argc; i++){
      if (argv_ok[i]==0){Info(0,"Invalid parameter: %s\n", argv[i]);}
    }  
  } 
  catch(Error_C& errC){perror("Error"); errC.print(); return_val=1;}
  catch(Error_Device& errDev){errDev.print(); return_val=2;}
  catch(Error_MemoryRange& x){
    Info(0, "Address out of memory range.\n"); return_val=3;
  }

  std::set_terminate(cleanup_exception);

  return return_val;
}

