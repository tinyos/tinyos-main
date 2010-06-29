/*
 * Copyright (c) 2008 The Regents of the University  of California.
 * All rights reserved."
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holders nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
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

extern const char *log_names[5];
extern loglevel_t log_level;
extern FILE *log_dest;

void log_init();

loglevel_t log_setlevel(loglevel_t l);
loglevel_t log_getlevel();

void log_log  (loglevel_t level, const char *fmt, ...);
void log_fatal_perror(const char *msg);
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


#define ISO8601_FMT(ltime, tv) "%04d-%02d-%02dT%02d:%02d:%02d.%03d%s",   \
    (ltime)->tm_year+1900, (ltime)->tm_mon+1, (ltime)->tm_mday,               \
    (ltime)->tm_hour, (ltime)->tm_min, (ltime)->tm_sec, (int)(tv)->tv_usec/ 1000, \
    tzname[0]

void log_dump_serial_packet(unsigned char *packet, const int len);

#endif
