// $Id: Error.h,v 1.4 2006-12-12 18:23:01 vlahan Exp $

/*
 * $Id: Error.h,v 1.4 2006-12-12 18:23:01 vlahan Exp $
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
** Error.h
** Uros Platise, (c) 1997, November
*/

#ifndef __Error
#define __Error
#include <stdio.h>

/* This error class is used to express standard C errors. */
class Error_C {
 public:
  Error_C (const char* _arg) : arg(_arg) { }
  void print (void) {
    if (arg != NULL) { printf (" -> %s\n", arg); }
  }
 private:
    const char *arg;
};

/* Out of memory error class informs terminal or upload/download
   tools that it has gone out of valid memory - and that's all.
   Program should not terminate. */
class Error_MemoryRange {};

/* General internal error reporting class that normally force
   uisp to exit after proper destruction of all objects. */
class Error_Device {
public:
  Error_Device (const char *_errMsg, const char *_arg=NULL) : 
    errMsg(_errMsg), arg(_arg) { }
  void print () { 
    if (arg==NULL) { printf ("%s\n", errMsg); }
    else { printf ("%s: %s\n", errMsg, arg); }
  }
private:
  const char* errMsg;
  const char* arg;
};

#endif
