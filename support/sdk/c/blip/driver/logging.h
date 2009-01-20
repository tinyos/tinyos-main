/*
 * "Copyright (c) 2008 The Regents of the University  of California.
 * All rights reserved."
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */
#ifndef LOGGING_H_
#define LOGGING_H_

#include <stdio.h>

// SDH : log levels defined here
//      also edit the log names in logging.h
typedef enum {
  LOGLVL_DEBUG = 0,
  LOGLVL_INFO = 1,
  LOGLVL_WARN = 2,
  LOGLVL_ERROR = 3,
  LOGLVL_FATAL = 4,
} loglevel_t;

extern char *log_names[5];
extern loglevel_t log_level;
extern FILE *log_dest;

void log_init();

loglevel_t log_setlevel(loglevel_t l);
loglevel_t log_getlevel();

void log_log  (loglevel_t level, const char *fmt, ...);
void log_clear (loglevel_t level, const char *fmt, ...);

#define debug(fmt, args...) \
           log_log(LOGLVL_DEBUG, fmt, ## args)
#define info(fmt, args...) \
           log_log(LOGLVL_INFO, fmt, ## args)
#define warn(fmt, args...) \
           log_log(LOGLVL_WARN, fmt, ## args)
#define error(fmt, args...) \
           log_log(LOGLVL_ERROR, fmt, ## args)
#define fatal(fmt, args...) \
           log_log(LOGLVL_FATAL, fmt, ## args)

#define log_fprintf(X, FMT, ...) ;

void log_dump_serial_packet(unsigned char *packet, const int len);

#endif
