// $Id: timeradd.h,v 1.4 2006-12-12 18:23:01 vlahan Exp $

/*
 * $Id: timeradd.h,v 1.4 2006-12-12 18:23:01 vlahan Exp $
 *
 ****************************************************************************
 *
 * uisp - The Micro In-System Programmer for Atmel AVR microcontrollers.
 * Copyright (C) 2002, 2003  Marek Michalkiewicz
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

/* I'm not sure how portable is to use these macros (they are available
   on my system, but not mentioned in the glibc manual I have).
   Similar macros are provided here for systems that don't have them.  -MM */

#include <sys/time.h>

#ifndef timeradd
#define timeradd(_a, _b, _res)				\
  do {							\
    (_res)->tv_usec = (_a)->tv_usec + (_b)->tv_usec;	\
    (_res)->tv_sec = (_a)->tv_sec + (_b)->tv_sec;	\
    if ((_res)->tv_usec >= 1000000)			\
      {							\
        (_res)->tv_usec -= 1000000;			\
        (_res)->tv_sec++;				\
      }							\
  } while (0)
#endif

#ifndef timersub
#define timersub(_a, _b, _res)				\
  do {							\
    (_res)->tv_usec = (_a)->tv_usec - (_b)->tv_usec;	\
    (_res)->tv_sec = (_a)->tv_sec - (_b)->tv_sec;	\
    if ((_res)->tv_usec < 0) {				\
      (_res)->tv_usec += 1000000;			\
      (_res)->tv_sec--;					\
    }							\
  } while (0)
#endif

#ifndef timercmp
#define timercmp(_a, _b, _cmp)				\
  (((_a)->tv_sec == (_b)->tv_sec) ?			\
   ((_a)->tv_usec _cmp (_b)->tv_usec) :			\
   ((_a)->tv_sec _cmp (_b)->tv_sec))
#endif

