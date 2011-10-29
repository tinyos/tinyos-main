// $Id: cygwinp.h,v 1.4 2006-12-12 18:23:01 vlahan Exp $

/*
 * $Id: cygwinp.h,v 1.4 2006-12-12 18:23:01 vlahan Exp $
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


#include <sys/time.h>

unsigned char inb(unsigned short port);
void outb(unsigned char value, unsigned short port);
int ioperm(unsigned short port, int num, int enable);
/* cfmakeraw() is declared in termios.h in Cygwin >= 1.7.2 */
#ifdef __CYGWIN__
#include <cygwin/version.h>
# if CYGWIN_VERSION_DLL_COMBINED < CYGWIN_VERSION_DLL_MAKE_COMBINED (1007, 2)
int cfmakeraw(struct termios *termios_p);
#endif
#endif
bool cygwinp_delay_usec(long t);
