/* debug.c -- debug utilities
 *
 * Copyright (C) 2010 Olaf Bergmann <bergmann@tzi.org>
 * 
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

#include <stdarg.h>
#include <stdio.h>
#include <time.h>

#include "debug.h"

#ifndef IDENT_APPNAME
void debug(char *format, ...) {
  static char timebuf[32];
  struct tm *tmp;
  time_t now;
  va_list ap;

  time(&now);
  tmp = localtime(&now);

  if ( strftime(timebuf,sizeof(timebuf), "%b %d %H:%M:%S", tmp) )
    printf("%s ", timebuf);
  
  va_start(ap, format);
  vprintf(format, ap);
  va_end(ap);
  fflush(stdout);
}
#else
#define debug(fmt, args ...) dbg(fmt, ## args)
#endif
