// $Id: DAPA.C,v 1.4 2006-12-12 18:23:01 vlahan Exp $

/*
 * $Id: DAPA.C,v 1.4 2006-12-12 18:23:01 vlahan Exp $
 *
 ****************************************************************************
 *
 * uisp - The Micro In-System Programmer for Atmel AVR microcontrollers.
 * Copyright (C) 1999, 2000, 2001, 2002, 2003  Sergey Larin
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
	DAPA.C

	Direct AVR Parallel Access (c) 1999
	
	Originally written by Sergey Larin.
	Corrected by 
	  Denis Chertykov, 
	  Uros Platise and 
	  Marek Michalkiewicz
*/

#ifndef NO_DAPA
//#define DEBUG
//#define DEBUG1

#include "config.h"

#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <ctype.h>

#ifndef NO_DIRECT_IO

/* Linux and FreeBSD differ in the order of outb() arguments.
   XXX any other OS/architectures with PC-style parallel ports?
   XXX how about the other *BSDs?  */

#if defined(__linux__) && defined(__i386__)

#include <sys/io.h>

#define ioport_read(port)         inb(port)
#define ioport_write(port, val)   outb(val, port)
#define ioport_enable(port, num)  ({ \
    int x = ioperm(port, num, 1); usleep(1); x; }) 
#define ioport_disable(port, num) ({ \
    int x = ioperm(port, num, 0); usleep(1); x; })

#elif defined(__CYGWIN__)

#include "cygwinp.h"

#define ioport_read(port)         inb(port)
#define ioport_write(port, val)   outb(val, port)
#define ioport_enable(port, num)  ioperm(port, num, 1)
#define ioport_disable(port, num) ioperm(port, num, 0)

#elif defined(__FreeBSD__) && defined(__i386__)

#include <sys/fcntl.h>
#include <machine/cpufunc.h>
#include <machine/sysarch.h>

#define ioport_read(port)         inb(port)
#define ioport_write(port, val)   outb(port, val)
#define ioport_enable(port, num)  i386_set_ioperm(port, num, 1)
#define ioport_disable(port, num) i386_set_ioperm(port, num, 0)

#else

/* Direct I/O port access not supported - ppdev/ppi kernel driver
   required for parallel port support to work at all.  Only likely to
   work on PC-style parallel ports (all signals implemented) anyway.

   The only lines believed to be implemented in all parallel ports are:
	D0-D6 outputs	(long long ago I heard of some non-PC machine with
			D7 hardwired to GND - don't remember what it was)
	BUSY input

   So far, only the dt006 interface happens to use a subset of the above.

	STROBE output might be pulsed by hardware and not be writable
	ACK input might only trigger an interrupt and not be readable

   Future designers of these "dongles" might want to keep this in mind.
 */

#define ioport_read(port)         (0xFF)
#define ioport_write(port, val)
#define ioport_enable(port, num)  (-1)
#define ioport_disable(port, num) (0)

#endif

#else /* NO_DIRECT_IO */

#define ioport_read(port)         (0xFF)
#define ioport_write(port, val)
#define ioport_enable(port, num)  (-1)
#define ioport_disable(port, num) (0)

#endif /* NO_DIRECT_IO */

#include <unistd.h>
#include <signal.h>
#include "timeradd.h"

#include <sys/ioctl.h>
#include <fcntl.h>

#include "parport.h"

/* These should work on any architecture, not just i386.  */
#if defined(__linux__)

#include "ppdev.h"

#define par_claim(fd)            ioctl(fd, PPCLAIM, 0)
#define par_read_status(fd, ptr) ioctl(fd, PPRSTATUS, ptr)
#define par_write_data(fd, ptr)  ioctl(fd, PPWDATA, ptr)
#define par_write_ctrl(fd, ptr)  ioctl(fd, PPWCONTROL, ptr)
#define par_set_dir(fd, ptr)     ioctl(fd, PPDATADIR, ptr)
#define par_release(fd)          ioctl(fd, PPRELEASE, 0)

#elif defined(__FreeBSD__)

#include </sys/dev/ppbus/ppi.h>

#define par_claim(fd)            (0)
#define par_read_status(fd, ptr) ioctl(fd, PPIGSTATUS, ptr)
#define par_write_data(fd, ptr)  ioctl(fd, PPISDATA, ptr)
#define par_write_ctrl(fd, ptr)  ioctl(fd, PPISCTRL, ptr)
/* par_set_dir not defined, par_write_ctrl used instead */
#define par_release(fd)

#else

/* Dummy defines if ppdev/ppi not supported by the kernel.  */

#define par_claim(fd)            (-1)
#define par_read_status(fd, ptr)
#define par_write_data(fd, ptr)
#define par_write_ctrl(fd, ptr)
#define par_release(fd)

#endif

#include "Global.h"
#include "Error.h"
#include "DAPA.h"
#include "Avr.h"

/* Parallel Port Base Address
*/
#define IOBASE parport_base
#define IOSIZE 3

/* FIXME: rewrite using tables to define new interface types.

   For each of the logical outputs (SCK, MOSI, RESET, ENA1, ENA2,
   power, XTAL1) there should be two bit masks that define which
   physical bits (from the parallel port output data or control
   registers, or serial port DTR/RTS/TXD) are affected, and if
   they should be inverted.  More than one output may be changed.
   For each of the inputs (MISO, maybe TEST?), define which bit
   (only one, from parallel port status or CTS/DCD/DSR/RI) should
   be tested and if it should be inverted.
   One struct as described above should be initialized for each
   of the supported hardware interfaces.
 */

/* Alex's Direct Avr Parallel Access 
*/
#define DAPA_SCK    PARPORT_CONTROL_STROBE	/* base + 2 */
#define DAPA_RESET  PARPORT_CONTROL_INIT	/* base + 2 */
#define DAPA_DIN    PARPORT_STATUS_BUSY		/* base + 1 */
#define DAPA_DOUT   0x1		/* base */

/* STK200 Direct Parallel Access 
*/
#define STK2_TEST1  0x01	/* D0 (base) - may be connected to POUT input */
#define STK2_TEST2  0x02	/* D1 (base) - may be connected to BUSY input */
#define STK2_ENA1   0x04    	/* D2 (base) - ENABLE# for RESET#, MISO */
#define STK2_ENA2   0x08    	/* D3 (base) - ENABLE# for SCK, MOSI, LED# */
#define STK2_SCK    0x10    	/* D4 (base) - SCK */
#define STK2_DOUT   0x20    	/* D5 (base) - MOSI */
#define STK2_LED    0x40	/* D6 (base) - LED# (optional) */
#define STK2_RESET  0x80    	/* D7 (base) - RESET# */
#define STK2_DIN    PARPORT_STATUS_ACK    	/* ACK (base + 1) - MISO */

/* Altera Byte Blaster Port Configuration
*/
#define ABB_EN      PARPORT_CONTROL_AUTOFD	/* low active */
#define ABB_LPAD    0x80	/* D7: loop back throught enable auto-detect */
#define ABB_SCK	    0x01	/* D0: TCK (ISP conn. pin 1) */
#define ABB_RESET   0x02	/* D1: TMS (ISP conn. pin 5) */
#define ABB_DOUT    0x40	/* D6: TDI (ISP conn. pin 9) */
#define ABB_DIN	    PARPORT_STATUS_BUSY	/* BUSY: TDO (ISP conn. pin 3) */
/* D5 (pin 7) connected to ACK (pin 10) directly */
/* D7 (pin 9) connected to POUT (pin 12) via 74HC244 buffer */
/* optional modification for AVREAL: D3 (pin 5) = XTAL1 (ISP conn. pin 8) */
#define ABB_XTAL1   0x08

/*
   XXX not yet supported, just documented here...

   Atmel-ISP Download Cable (P/N ATDH1150VPC)
   (10-pin connector similar to Altera Byte Blaster, but no 3-state outputs)
   http://www.atmel.com/atmel/acrobat/isp_c_v5.pdf

   VCC ---- 4
   GND ---- 2,10 ---- GND
   SCK   <- TCK(1) <- nSTROBE
   MISO  -> TDO(3) -> nACK
   RESET <- TMS(5) <- SELECT
   MOSI  <- TDI(9) <- D0
   XTAL1 <- AF(8)  <- AUTOFD (optional, not yet supported)
 */
#define ATDH_SCK    PARPORT_CONTROL_STROBE
#define ATDH_DOUT   0x01
#define ATDH_RESET  PARPORT_CONTROL_SELECT
#define ATDH_DIN    PARPORT_STATUS_ACK
#define ATDH_XTAL1  PARPORT_CONTROL_AUTOFD

/* "Atmel AVR ISP" cable (?)
 */
#define AISP_TSTOUT 0x08	/* D3 (base) - dongle test output */
#define AISP_SCK    0x10	/* D4 (base) - SCK */
#define AISP_DOUT   0x20	/* D5 (base) - MOSI */
#define AISP_ENA    0x40	/* D6 (base) - ENABLE# for MISO, MOSI, SCK */
#define AISP_RESET  0x80	/* D7 (base) - RESET# */
#define AISP_DIN    PARPORT_STATUS_ACK /* ACK (base + 1) - MISO */
/* BUSY and POUT used as inputs to test for the dongle */

/* Yet another AVR ISP cable from http://www.bsdhome.com/avrprog/
 */
#define BSD_POWER   0x0F	/* D0-D3 (base) - power */
#define BSD_ENA     0x10	/* D4 (base) - ENABLE# */
#define BSD_RESET   0x20	/* D5 (base) - RESET# */
#define BSD_SCK     0x40	/* D6 (base) - SCK */
#define BSD_DOUT    0x80	/* D7 (base) - MOSI */
#define BSD_DIN     PARPORT_STATUS_ACK /* ACK (base + 1) - MISO */
/* optional status LEDs, active low, not yet supported (base + 2) */
#define BSD_LED_ERR PARPORT_CONTROL_STROBE  /* error */
#define BSD_LED_RDY PARPORT_CONTROL_AUTOFD  /* ready */
#define BSD_LED_PGM PARPORT_CONTROL_INIT    /* programming */
#define BSD_LED_VFY PARPORT_CONTROL_SELECT  /* verifying */

/*
   FBPRG - http://ln.com.ua/~real/avreal/adapters.html
*/
#define FBPRG_POW    0x07	/* D0,D1,D2 (base) - power supply (XXX D7 too?) */
#define FBPRG_XTAL1  0x08	/* D3 (base) (not supported) */
#define FBPRG_RESET  0x10	/* D4 (base) */
#define FBPRG_DOUT   0x20	/* D5 (base) */
#define FBPRG_SCK    0x40	/* D6 (base) */
#define FBPRG_DIN    PARPORT_STATUS_ACK /* ACK (base + 1) - MISO */

/* DT006/Sample Electronics Parallel Cable
   http://www.dontronics.com/dt006.html
*/
/* all at base, except for DT006_DIN at base + 1 */
#define DT006_SCK    0x08
#define DT006_RESET  0x04
#define DT006_DIN    PARPORT_STATUS_BUSY
#define DT006_DOUT   0x01

/* ETT-AVR V2.0 Programmer / Futurlec AT90S8535 */ 
#define ETT_SCK      0x01                   /* DB25 Pin  2: D0 (Base + 0) -> SCK      */
#define ETT_RESET    0x02                   /* DB25 Pin  3: D1 (Base + 0) -> RESET    */
#define ETT_DIN      PARPORT_STATUS_ACK     /* DB25 Pin 10: ACK (Base + 1) -> MISO    */
#define ETT_DOUT     PARPORT_CONTROL_STROBE /* DB25 Pin  1: STROBE (Base + 2) -> MOSI */

/* ABC Maxi - just like DT006 with two pins swapped */
/* all at base, except for MAXI_DIN at base + 1 */
#define MAXI_SCK    0x02
#define MAXI_RESET  0x04
#define MAXI_DIN    PARPORT_STATUS_ACK
#define MAXI_DOUT   0x01

/* Xilinx JTAG download cable
   RESET=TMS, SCK=TCK, MISO=TDO, MOSI=TDI
*/
#define XIL_DOUT    0x01        /* D0: TDI */
#define XIL_SCK     0x02        /* D1: TCK */
#define XIL_RESET   0x04        /* D2: TMS */
#define XIL_ENA     0x08        /* D3: ENABLE# */
#define XIL_DIN	    PARPORT_STATUS_SELECT /* SLCT: TDO */

/* Default value for minimum SCK high/low time in microseconds.  */
#ifndef SCK_DELAY
#define SCK_DELAY 5
#endif

/* Minimum RESET# high time in microseconds.
   Should be enough to charge a capacitor between RESET# and GND
   (it is recommended to use a voltage detector with open collector
   output, and only something like 100 nF for noise immunity).
   Default value may be changed with -dt_reset=N microseconds.  */
#ifndef RESET_HIGH_TIME
#define RESET_HIGH_TIME 1000
#endif

/* Delay from RESET# low to sending program enable command
   (the datasheet says it must be at least 20 ms).  Also wait time
   for crystal oscillator to start after possible power down mode.  */
#ifndef RESET_LOW_TIME
#define RESET_LOW_TIME 30000
#endif

void
TDAPA::SckDelay()
{
  Delay_usec(t_sck);
}

#ifndef MIN_SLEEP_USEC
#define MIN_SLEEP_USEC 20000
#endif

void
TDAPA::Delay_usec(long t)
{
  struct timeval t1, t2;

#if defined(__CYGWIN__)
  if (cygwinp_delay_usec(t)) {
    return;
  }
#endif

  if (t <= 0)
    return;  /* very short delay for slow machines */
  gettimeofday(&t1, NULL);
  if (t > MIN_SLEEP_USEC)
    usleep(t - MIN_SLEEP_USEC);
  /* loop for the remaining time */
  t2.tv_sec = t / 1000000UL;
  t2.tv_usec = t % 1000000UL;
  timeradd(&t1, &t2, &t1);
  do {
    gettimeofday(&t2, NULL);
  } while (timercmp(&t2, &t1, <));
}

void
TDAPA::ParportSetDir(int dir)
{
  if (dir)
    par_ctrl |= PARPORT_CONTROL_DIRECTION;
  else
    par_ctrl &= ~PARPORT_CONTROL_DIRECTION;

  if (ppdev_fd != -1) {
#ifdef par_set_dir
    par_set_dir(ppdev_fd, &dir);
#else
    par_write_ctrl(ppdev_fd, &par_ctrl);
#endif
  } else
    ioport_write(IOBASE+2, par_ctrl);
}

void
TDAPA::ParportWriteCtrl()
{
  if (ppdev_fd != -1)
    par_write_ctrl(ppdev_fd, &par_ctrl);
  else
    ioport_write(IOBASE+2, par_ctrl);
}

void
TDAPA::ParportWriteData()
{
  if (ppdev_fd != -1)
    par_write_data(ppdev_fd, &par_data);
  else
    ioport_write(IOBASE, par_data);
}

void
TDAPA::ParportReadStatus()
{
  if (ppdev_fd != -1)
    par_read_status(ppdev_fd, &par_status);
  else
    par_status = ioport_read(IOBASE+1);
}

void
TDAPA::SerialReadCtrl()
{
#ifdef TIOCMGET
  ioctl(ppdev_fd, TIOCMGET, &ser_ctrl);
#else
  ser_ctrl = 0;
#endif
}

void
TDAPA::SerialWriteCtrl()
{
#ifdef TIOCMGET
  ioctl(ppdev_fd, TIOCMSET, &ser_ctrl);
#endif
}

void
TDAPA::OutReset(int b)
  /* FALSE means active Reset at the AVR */ 
{
  if (reset_invert)
    b = !b;
  switch (pa_type) {
  case PAT_DAPA:
  case PAT_DAPA_2:
    if (b) par_ctrl |= DAPA_RESET; else par_ctrl &= ~DAPA_RESET;
    ParportWriteCtrl();
    break;

  case PAT_STK200:
    if (b) par_data |= STK2_RESET; else par_data &= ~STK2_RESET;
    ParportWriteData();
    break;

  case PAT_ABB:
    if (b) par_data |= ABB_RESET; else par_data &= ~ABB_RESET;
    ParportWriteData();
    break;

  case PAT_AVRISP:
    if (b) par_data |= AISP_RESET; else par_data &= ~AISP_RESET;
    ParportWriteData();
    break;

  case PAT_BSD:
    if (b) par_data |= BSD_RESET; else par_data &= ~BSD_RESET;
    ParportWriteData();
    break;

  case PAT_FBPRG:
    if (b) par_data |= FBPRG_RESET; else par_data &= ~FBPRG_RESET;
    ParportWriteData();
    break;

  case PAT_DT006:
    if (b) par_data |= DT006_RESET; else par_data &= ~DT006_RESET;
    ParportWriteData();
    break;

  case PAT_ETT:
    if (b) par_data |= ETT_RESET; else par_data &= ~ETT_RESET;
    ParportWriteData();
    break;

  case PAT_MAXI:
    if (b) par_data |= MAXI_RESET; else par_data &= ~MAXI_RESET;
    ParportWriteData();
    break;

  case PAT_XIL:
    if (b) par_data |= XIL_RESET; else par_data &= ~XIL_RESET;
    ParportWriteData();
    break;

  case PAT_DASA:
#ifdef TIOCMGET
    SerialReadCtrl();
    if (b) ser_ctrl |= TIOCM_RTS; else ser_ctrl &= ~TIOCM_RTS;
    SerialWriteCtrl();
#endif /* TIOCMGET */
    break;

  case PAT_DASA2:
#if defined(TIOCMGET) && defined(TIOCCBRK)
    ioctl(ppdev_fd, b ? TIOCCBRK : TIOCSBRK, 0);
#endif /* TIOCMGET */
    break;
  }
  Delay_usec(b ? reset_high_time : RESET_LOW_TIME );
}

void
TDAPA::OutSck(int b)
{
  if (sck_invert)
    b = !b;
#ifdef DEBUG1
  printf("%c",(b)?'S':'s');
#endif
  switch (pa_type) {
  case PAT_DAPA:
  case PAT_DAPA_2:
    if (b) par_ctrl &= ~DAPA_SCK; else par_ctrl |= DAPA_SCK;
    ParportWriteCtrl();
    break;

  case PAT_STK200:
    if (b) par_data |= STK2_SCK; else par_data &= ~STK2_SCK;
    ParportWriteData();
    break;

  case PAT_ABB:
    if (b) par_data |= ABB_SCK; else par_data &= ~ABB_SCK;
    ParportWriteData();
    break;

  case PAT_AVRISP:
    if (b) par_data |= AISP_SCK; else par_data &= ~AISP_SCK;
    ParportWriteData();
    break;

  case PAT_BSD:
    if (b) par_data |= BSD_SCK; else par_data &= ~BSD_SCK;
    ParportWriteData();
    break;

  case PAT_FBPRG:
    if (b) par_data |= FBPRG_SCK; else par_data &= ~FBPRG_SCK;
    ParportWriteData();
    break;

  case PAT_DT006:
    if (b) par_data |= DT006_SCK; else par_data &= ~DT006_SCK;
    ParportWriteData();
    break;

  case PAT_ETT:
    if (b) par_data |= ETT_SCK; else par_data &= ~ETT_SCK;
    ParportWriteData();
    break;
  
  case PAT_MAXI:
    if (b) par_data |= MAXI_SCK; else par_data &= ~MAXI_SCK;
    ParportWriteData();
    break;

  case PAT_XIL:
    if (b) par_data |= XIL_SCK; else par_data &= ~XIL_SCK;
    ParportWriteData();
    break;

  case PAT_DASA:
#if defined(TIOCMGET)
    SerialReadCtrl();
    if (b) ser_ctrl |= TIOCM_DTR; else ser_ctrl &= ~TIOCM_DTR;
    SerialWriteCtrl();
#endif /* TIOCMGET */
    break;

  case PAT_DASA2:
#if defined(TIOCMGET)
    if (b) ser_ctrl |= TIOCM_RTS; else ser_ctrl &= ~TIOCM_RTS;
    SerialWriteCtrl();
#endif /* TIOCMGET */
    break;
  }
}


void
TDAPA::OutEnaReset(int b)
{
  bool no_ps2_hack = GetCmdParam("-dno-ps2-hack", false);
  switch (pa_type) {
  case PAT_DAPA:
  case PAT_DAPA_2:
  case PAT_FBPRG:
  case PAT_DT006:
  case PAT_ETT:
  case PAT_MAXI:
    if (b) {
      ParportSetDir(0);
    } else if (!no_ps2_hack) {
      /* No special enable line on these interfaces, for PAT_DAPA
         this only disables the data line (MOSI) and not SCK.  */
      ParportSetDir(1);
    }
    break;

  case PAT_STK200:
    if (b) {
      /* Make sure outputs are enabled.  */
      ParportSetDir(0);
      SckDelay();
      par_data &= ~STK2_ENA1;
      ParportWriteData();
    } else {
      par_data |= STK2_ENA1;
      ParportWriteData();
      if (!no_ps2_hack) {
        /* Experimental: disable outputs (PS/2 parallel port), for cheap
	   STK200-like cable without the '244.  Should work with the real
           STK200 too (disabled outputs should still have pull-up resistors,
	   ENA1 and ENA2 are high, and the '244 remains disabled).
	   This way the SPI pins can be used by the application too.
	   Please report if it doesn't work on some parallel ports.  */
	SckDelay();
	ParportSetDir(1);
      }
    }
    break;

  case PAT_ABB:
    if (b) {
      ParportSetDir(0);
      par_ctrl |= ABB_EN;
      ParportWriteCtrl();
    } else {
      par_ctrl &= ~ABB_EN;
      ParportWriteCtrl();
      if (!no_ps2_hack) {
	SckDelay();
	ParportSetDir(1);
      }
    }
    break;

  case PAT_AVRISP:
    if (b) {
      ParportSetDir(0);
      SckDelay();
      par_data &= ~AISP_ENA;
      ParportWriteData();
    } else {
      par_data |= AISP_ENA;
      ParportWriteData();
      if (!no_ps2_hack) {
	SckDelay();
	ParportSetDir(1);
      }
    }
    break;

  case PAT_BSD:
    if (b) {
      ParportSetDir(0);
      SckDelay();
      par_data &= ~BSD_ENA;
      ParportWriteData();
    } else {
      par_data |= BSD_ENA;
      ParportWriteData();
      if (!no_ps2_hack) {
	SckDelay();
	ParportSetDir(1);
      }
    }
    break;

  case PAT_XIL:
    if (b) {
      ParportSetDir(0);
      par_data &= ~XIL_ENA;
      ParportWriteData();
    } else {
      par_data |= XIL_ENA;
      ParportWriteData();
      if (!no_ps2_hack) {
	SckDelay();
	ParportSetDir(1);
      }
    }
    break;

  case PAT_DASA:
  case PAT_DASA2:
    break;
  }
}

void
TDAPA::OutEnaSck(int b)
{
  switch (pa_type) {
  case PAT_STK200:
    if (b)
      par_data &= ~(STK2_ENA2 | STK2_LED);
    else
      par_data |= (STK2_ENA2 | STK2_LED);
    ParportWriteData();
    break;

  case PAT_DAPA:
  case PAT_DAPA_2:
  case PAT_ABB:
  case PAT_AVRISP:
  case PAT_BSD:
  case PAT_FBPRG:
  case PAT_DT006:
  case PAT_ETT:
  case PAT_MAXI:
  case PAT_XIL:
  case PAT_DASA:
  case PAT_DASA2:
    /* no separate enable for SCK nad MOSI */
    break;
  }
}

void
TDAPA::PulseSck()
{
  SckDelay();
  OutSck(1);
  SckDelay();
  OutSck(0);
}

void
TDAPA::PulseReset()
{
  printf("pulse\n");
  /* necessary delays already included in these methods */
  OutReset(1);
  Delay_usec(1000); 
  OutReset(0);
}

void
TDAPA::OutData(int b)
{
  if (mosi_invert)
    b = !b;
#ifdef DEBUG1
  printf("%c",(b)?'D':'d');
#endif
  switch (pa_type) {
  case PAT_DAPA:
    if (b) par_data |= DAPA_DOUT; else par_data &= ~DAPA_DOUT;
    par_data &= ~0x6; //0x6
    par_data |= 0x0; //0x6
    ParportWriteData();
    break;

  case PAT_DAPA_2:
    if (b) par_data |= DAPA_DOUT; else par_data &= ~DAPA_DOUT;
    par_data &= ~0x6; //0x6
    par_data |= 0x4; //0x6
    ParportWriteData();
    break;

  case PAT_STK200:
    if (b) par_data |= STK2_DOUT; else par_data &= ~STK2_DOUT;
    ParportWriteData();
    break;

  case PAT_ABB:
    if (b) par_data |= ABB_DOUT; else par_data &= ~ABB_DOUT;
    ParportWriteData();
    break;

  case PAT_AVRISP:
    if (b) par_data |= AISP_DOUT; else par_data &= ~AISP_DOUT;
    ParportWriteData();
    break;

  case PAT_BSD:
    if (b) par_data |= BSD_DOUT; else par_data &= ~BSD_DOUT;
    ParportWriteData();
    break;

  case PAT_FBPRG:
    if (b) par_data |= FBPRG_DOUT; else par_data &= ~FBPRG_DOUT;
    ParportWriteData();
    break;

  case PAT_DT006:
    if (b) par_data |= DT006_DOUT; else par_data &= ~DT006_DOUT;
    ParportWriteData();
    break;

  case PAT_ETT:
    if (b) par_ctrl |= ETT_DOUT; else par_ctrl &= ~ETT_DOUT;
    ParportWriteCtrl();
    break;

  case PAT_MAXI:
    if (b) par_data |= MAXI_DOUT; else par_data &= ~MAXI_DOUT;
    ParportWriteData();
    break;

  case PAT_XIL:
    if (b) par_data |= XIL_DOUT; else par_data &= ~XIL_DOUT;
    ParportWriteData();
    break;

  case PAT_DASA:
#if defined(TIOCMGET) && defined(TIOCCBRK)
    ioctl(ppdev_fd, b ? TIOCSBRK : TIOCCBRK, 0);
#endif /* TIOCMGET */
    break;

  case PAT_DASA2:
#if defined(TIOCMGET)
    if (b) ser_ctrl |= TIOCM_DTR; else ser_ctrl &= ~TIOCM_DTR;
    SerialWriteCtrl();
#endif /* TIOCMGET */
    break;
  }
}

int
TDAPA::InData()
{
  int b = 0;

  switch (pa_type) {
  case PAT_DAPA:
  case PAT_DAPA_2:
  case PAT_ABB:
  case PAT_DT006:
    ParportReadStatus();
    b = (~par_status & PARPORT_STATUS_BUSY);
    break;
  case PAT_ETT:
    ParportReadStatus();
    b = (par_status & ETT_DIN);
    break;
  case PAT_STK200:
  case PAT_AVRISP:
  case PAT_BSD:
  case PAT_FBPRG:
  case PAT_MAXI:
    ParportReadStatus();
    b = (par_status & PARPORT_STATUS_ACK);
    break;
  case PAT_XIL:
    ParportReadStatus();
    b = (par_status & PARPORT_STATUS_SELECT);
    break;
  case PAT_DASA:
  case PAT_DASA2:
#ifdef TIOCMGET
    SerialReadCtrl();
#ifdef DEBUG1
    printf("%c",(ser_ctrl & TIOCM_CTS)?'I':'i');
#endif
    b = (ser_ctrl & TIOCM_CTS);
#endif /* TIOCMGET */
    break;
  }
  if (miso_invert)
    b = !b;
  return b;
}

void
TDAPA::Init()
{
  /* data=1, reset=0, sck=0 */
  switch (pa_type) {
  case PAT_DAPA:
    par_ctrl = DAPA_SCK;
    par_data = 0xFF;
    par_data &= ~0x6; //0x6
    par_data |= 0x0; //0x6
    break;
  case PAT_DAPA_2:
    par_ctrl = DAPA_SCK;
    par_data = 0xFF;
    par_data &= ~0x6; //0x6
    par_data |= 0x4; //0x6
    break;

  case PAT_STK200:
    par_ctrl = 0;
    par_data = 0xFF & ~(STK2_ENA1 | STK2_SCK);
    break;

  case PAT_ABB:
    par_ctrl = ABB_EN;
    par_data = 0xFF & ~ABB_SCK;
    break;

  case PAT_AVRISP:
    par_ctrl = 0;
    par_data = 0xFF & ~(AISP_ENA | AISP_SCK);
    break;

  case PAT_BSD:
    par_ctrl = 0;
    par_data = BSD_POWER | BSD_RESET;
    break;

  case PAT_FBPRG:
    par_ctrl = 0;
    par_data = FBPRG_POW | FBPRG_RESET;
    break;

  case PAT_ETT:
    par_ctrl = ETT_DOUT;
    par_data = ETT_SCK | ETT_RESET;
    mosi_invert = 1;
    break;

  case PAT_DT006:
  case PAT_MAXI:
    par_ctrl = 0;
    par_data = 0xFF;
    break;

  case PAT_XIL:
    par_ctrl = 0;
    par_data = 0xFF & ~(XIL_ENA | XIL_SCK | XIL_RESET);
    break;

  case PAT_DASA:
  case PAT_DASA2:
    break;
  }

  if (!pa_type_is_serial) {
    ParportWriteCtrl();
    ParportWriteData();
    SckDelay();
    ParportReadStatus();
  }

  OutEnaReset(1);
  OutReset(0);
  OutEnaSck(1);
  OutSck(0);
  /* Wait 100 ms as recommended for ATmega163 (SCK not low on power up).  */
  Delay_usec(100000);
  PulseReset();
}

int
TDAPA::SendRecv(int b)
{
  unsigned int mask, received=0;

  for (mask = 0x80; mask; mask >>= 1) {
     OutData(b & mask);
     SckDelay();
     /* MM 20020613: we used to read the bit here, but ... */
     OutSck(1);
     SckDelay();
     /* ... here we have more room for propagation delays (almost the
	whole SCK period, instead of half of it) - good for long cables,
	slow RS232 drivers/receivers, opto-isolated interfaces, etc.  */
     if (InData())
       received |= mask;
     OutSck(0);
  }
  return received;
}

int
TDAPA::Send (unsigned char* queue, int queueSize, int rec_queueSize)
{
  unsigned char *p = queue, ch;
  int i = queueSize;
  
  if (rec_queueSize==-1){rec_queueSize = queueSize;}
#ifdef DEBUG
  printf ("send(recv): ");
#endif
  while (i--){
#ifdef DEBUG
    printf ("%02X(", (unsigned int)*p);
#endif    
    ch = SendRecv(*p);
#ifdef DEBUG    
    printf ("%02X) ", (unsigned int)ch);
#endif    
    *p++ = ch;
  }
#ifdef DEBUG  
  printf ("\n");
#endif  
  return queueSize;
}


TDAPA::TDAPA(): 
  parport_base(0x378), ppdev_fd(-1)
{
  const char *val;

  /* If the user doesn't specify -dlpt option, use /dev/parport0 as the
     default instead of defaulting to using ioperm (ick!). If the user wants
     to run uisp as root (or setuid root) they should know what they are doing
     and can suffer the consequences. Joe user should not be told about ioperm
     failure due to permission denied. */
#ifdef __CYGWIN__
  /* But on cygwin, /dev/parport0 does not exist. So... */
  const char *ppdev_name = NULL;
#else
  const char *ppdev_name = "/dev/parport0";
#endif

  /* Enable Parallel Port */
  val = GetCmdParam("-dprog");
  if (val && strcmp(val, "dapa") == 0)
    pa_type = PAT_DAPA;
  else if (val && strcmp(val, "dapa_2") == 0)
    pa_type = PAT_DAPA_2;
  else if (val && strcmp(val, "stk200") == 0)
    pa_type = PAT_STK200;
  else if (val && strcmp(val, "abb") == 0)
    pa_type = PAT_ABB;
  else if (val && strcmp(val, "avrisp") == 0)
    pa_type = PAT_AVRISP;
  else if (val && strcmp(val, "bsd") == 0)
    pa_type = PAT_BSD;
  else if (val && strcmp(val, "fbprg") == 0)
    pa_type = PAT_FBPRG;
  else if (val && strcmp(val, "dt006") == 0)
    pa_type = PAT_DT006;
  else if (val && strcmp(val, "ett") == 0)
    pa_type = PAT_ETT;
  else if (val && strcmp(val, "maxi") == 0)
    pa_type = PAT_MAXI;
  else if (val && strcmp(val, "xil") == 0)
    pa_type = PAT_XIL;
  else if (val && strcmp(val, "dasa") == 0)
    pa_type = PAT_DASA;
  else if (val && strcmp(val, "dasa2") == 0)
    pa_type = PAT_DASA2;
  else {
    throw Error_Device("Direct Parallel Access not defined.");
  }
  pa_type_is_serial = (pa_type == PAT_DASA || pa_type == PAT_DASA2);
  /* Parse Command Line Switches */
#ifndef NO_DIRECT_IO
  if ((val = GetCmdParam("-dlpt")) != NULL) {
    if (!strcmp(val, "1")) {
      parport_base = 0x378;
      ppdev_name = NULL;
    }
    else if (!strcmp(val, "2")) {
      parport_base = 0x278;
      ppdev_name = NULL;
    }
    else if (!strcmp(val, "3")) {
      parport_base = 0x3bc;
      ppdev_name = NULL;
    }    
    else if (isdigit(*val)) {
      parport_base = strtol(val, NULL, 0);
      ppdev_name = NULL;
    }
    else {
      ppdev_name = val;
    }
  }
  if (!ppdev_name && !pa_type_is_serial) {
    if (parport_base!=0x278 && parport_base!=0x378 && parport_base!=0x3bc) {
      /* TODO: option to override this if you really know
	 what you're doing (only if running as root).  */
      throw Error_Device("Bad device address.");
    }
    if (ioport_enable(IOBASE, IOSIZE) != 0) {
      perror("ioperm");
      throw Error_Device("Failed to get direct I/O port access.");
    }
  }
#endif

  /* Drop privileges (if installed setuid root - NOT RECOMMENDED).  */
  setgid(getgid());
  setuid(getuid());

#ifdef NO_DIRECT_IO
  if ((val = GetCmdParam("-dlpt")) != NULL) {
    ppdev_name = val;
  }
#endif

  if (ppdev_name) {
    if (pa_type_is_serial) {
      ppdev_fd = open(ppdev_name, O_RDWR | O_NOCTTY | O_NONBLOCK);
      if (ppdev_fd != -1) {
	struct termios pmode;

	tcgetattr(ppdev_fd, &pmode);
	saved_modes = pmode;

	cfmakeraw(&pmode);
	pmode.c_iflag &= ~(INPCK | IXOFF | IXON);
	pmode.c_cflag &= ~(HUPCL | CSTOPB | CRTSCTS);
	pmode.c_cflag |= (CLOCAL | CREAD);
	pmode.c_cc [VMIN] = 1;
	pmode.c_cc [VTIME] = 0;

	tcsetattr(ppdev_fd, TCSANOW, &pmode);

	/* Clear O_NONBLOCK flag.  */
	int flags = fcntl(ppdev_fd, F_GETFL, 0);
	if (flags == -1) { throw Error_C("Can not get flags"); }
	flags &= ~O_NONBLOCK;
	if (fcntl(ppdev_fd, F_SETFL, flags) == -1) { 
          throw Error_C("Can not clear nonblock flag");
        }
      }
    } else {
      ppdev_fd = open(ppdev_name, O_RDWR, 0);
    }
    if (ppdev_fd == -1) {
      perror(ppdev_name);
      throw Error_Device("Failed to open ppdev.");
    }
    if (!pa_type_is_serial && par_claim(ppdev_fd) != 0) {
      perror("ioctl PPCLAIM");
      close(ppdev_fd);
      ppdev_fd = -1;
      throw Error_Device("Failed to claim ppdev.");
    }
  }
  t_sck = SCK_DELAY;
  if (pa_type_is_serial)
    t_sck *= 3;  /* more delay for slow RS232 drivers */
  val = GetCmdParam("-dt_sck");
  if (val)
    t_sck = strtol(val, NULL, 0);

  sck_invert = 0;
  mosi_invert = 0;
  miso_invert = 0;
  reset_invert = 0;
  if ((val=GetCmdParam("-dinvert")))
    {
#define MAXLINESIZE    256
      char temp[MAXLINESIZE];
      char * p;
      strncpy(temp, val, MAXLINESIZE-1);
      temp[MAXLINESIZE-1] = '\0';
      for (p=temp; *p; p++)
        *p=toupper(*p);
      Info(3, "Inverting %s\n",temp);
      if (strstr(temp,"SCK"))
        sck_invert=1;

      if (strstr(temp,"MOSI"))
        mosi_invert=1;

      if (strstr(temp,"MISO"))
        miso_invert=1;

      if (strstr(temp,"RESET"))
        reset_invert=1;
    }

  reset_high_time = RESET_HIGH_TIME;
  if ((val=GetCmdParam("-dt_reset")))
    {
      reset_high_time = atoi(val);
    }
  Info(3, "Reset inactive time (t_reset) %d us\n", reset_high_time);

  Init();
}

TDAPA::~TDAPA()
{
  OutData(1); SckDelay();
  OutSck(1); SckDelay();
  OutEnaSck(0);
  OutReset(1);
  OutEnaReset(0);

  if (ppdev_fd != -1) {
    if (pa_type_is_serial)
      tcsetattr(ppdev_fd, TCSADRAIN, &saved_modes);
    else
      par_release(ppdev_fd);
    close(ppdev_fd);
    ppdev_fd = -1;
  } else
    (void) ioport_disable(IOBASE, IOSIZE);
}

#endif
/* eof */
