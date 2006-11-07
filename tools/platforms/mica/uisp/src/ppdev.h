// $Id: ppdev.h,v 1.3 2006-11-07 19:30:42 scipio Exp $

/*
 * $Id: ppdev.h,v 1.3 2006-11-07 19:30:42 scipio Exp $
 *
 ****************************************************************************
 *
 * uisp - The Micro In-System Programmer for Atmel AVR microcontrollers.
 * Copyright (C) 1998-9 Tim Waugh <tim@cyberelk.demon.co.uk>
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
 * linux/drivers/char/ppdev.h
 *
 * User-space parallel port device driver (header file).
 *
 * Added PPGETTIME/PPSETTIME, Fred Barnes, 1999.
 */

#define PP_MAJOR	99

#define PP_IOCTL	'p'

/* Set mode for read/write (e.g. IEEE1284_MODE_EPP) */
#define PPSETMODE	_IOW(PP_IOCTL, 0x80, int)

/* Read status */
#define PPRSTATUS	_IOR(PP_IOCTL, 0x81, unsigned char)
#define PPWSTATUS	OBSOLETE__IOW(PP_IOCTL, 0x82, unsigned char)

/* Read/write control */
#define PPRCONTROL	_IOR(PP_IOCTL, 0x83, unsigned char)
#define PPWCONTROL	_IOW(PP_IOCTL, 0x84, unsigned char)

struct ppdev_frob_struct {
	unsigned char mask;
	unsigned char val;
};
#define PPFCONTROL      _IOW(PP_IOCTL, 0x8e, struct ppdev_frob_struct)

/* Read/write data */
#define PPRDATA		_IOR(PP_IOCTL, 0x85, unsigned char)
#define PPWDATA		_IOW(PP_IOCTL, 0x86, unsigned char)

/* Read/write econtrol (not used) */
#define PPRECONTROL	OBSOLETE__IOR(PP_IOCTL, 0x87, unsigned char)
#define PPWECONTROL	OBSOLETE__IOW(PP_IOCTL, 0x88, unsigned char)

/* Read/write FIFO (not used) */
#define PPRFIFO		OBSOLETE__IOR(PP_IOCTL, 0x89, unsigned char)
#define PPWFIFO		OBSOLETE__IOW(PP_IOCTL, 0x8a, unsigned char)

/* Claim the port to start using it */
#define PPCLAIM		_IO(PP_IOCTL, 0x8b)

/* Release the port when you aren't using it */
#define PPRELEASE	_IO(PP_IOCTL, 0x8c)

/* Yield the port (release it if another driver is waiting,
 * then reclaim) */
#define PPYIELD		_IO(PP_IOCTL, 0x8d)

/* Register device exclusively (must be before PPCLAIM). */
#define PPEXCL		_IO(PP_IOCTL, 0x8f)

/* Data line direction: non-zero for input mode. */
#define PPDATADIR	_IOW(PP_IOCTL, 0x90, int)

/* Negotiate a particular IEEE 1284 mode. */
#define PPNEGOT		_IOW(PP_IOCTL, 0x91, int)

/* Set control lines when an interrupt occurs. */
#define PPWCTLONIRQ	_IOW(PP_IOCTL, 0x92, unsigned char)

/* Clear (and return) interrupt count. */
#define PPCLRIRQ	_IOR(PP_IOCTL, 0x93, int)

/* Set the IEEE 1284 phase that we're in (e.g. IEEE1284_PH_FWD_IDLE) */
#define PPSETPHASE	_IOW(PP_IOCTL, 0x94, int)

/* Set and get port timeout (struct timeval's) */
#define PPGETTIME	_IOR(PP_IOCTL, 0x95, struct timeval)
#define PPSETTIME	_IOW(PP_IOCTL, 0x96, struct timeval)

/* IEEE1284 modes: 
   Nibble mode, byte mode, ECP, ECPRLE and EPP are their own
   'extensibility request' values.  Others are special.
   'Real' ECP modes must have the IEEE1284_MODE_ECP bit set.  */
#define IEEE1284_MODE_NIBBLE             0
#define IEEE1284_MODE_BYTE              (1<<0)
#define IEEE1284_MODE_COMPAT            (1<<8)
#define IEEE1284_MODE_BECP              (1<<9) /* Bounded ECP mode */
#define IEEE1284_MODE_ECP               (1<<4)
#define IEEE1284_MODE_ECPRLE            (IEEE1284_MODE_ECP | (1<<5))
#define IEEE1284_MODE_ECPSWE            (1<<10) /* Software-emulated */
#define IEEE1284_MODE_EPP               (1<<6)
#define IEEE1284_MODE_EPPSL             (1<<11) /* EPP 1.7 */
#define IEEE1284_MODE_EPPSWE            (1<<12) /* Software-emulated */
#define IEEE1284_DEVICEID               (1<<2)  /* This is a flag */
#define IEEE1284_EXT_LINK               (1<<14) /* This flag causes the
						 * extensibility link to
						 * be requested, using
						 * bits 0-6. */

/* For the benefit of parport_read/write, you can use these with
 * parport_negotiate to use address operations.  They have no effect
 * other than to make parport_read/write use address transfers. */
#define IEEE1284_ADDR			(1<<13)	/* This is a flag */
#define IEEE1284_DATA			 0	/* So is this */

/* IEEE1284 phases */
enum ieee1284_phase {
	IEEE1284_PH_FWD_DATA,
	IEEE1284_PH_FWD_IDLE,
	IEEE1284_PH_TERMINATE,
	IEEE1284_PH_NEGOTIATION,
	IEEE1284_PH_HBUSY_DNA,
	IEEE1284_PH_REV_IDLE,
	IEEE1284_PH_HBUSY_DAVAIL,
	IEEE1284_PH_REV_DATA,
	IEEE1284_PH_ECP_SETUP,
	IEEE1284_PH_ECP_FWD_TO_REV,
	IEEE1284_PH_ECP_REV_TO_FWD
};
