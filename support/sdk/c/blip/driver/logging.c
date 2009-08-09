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
#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <time.h>
#include <sys/time.h>
#include <stdarg.h>
#include "logging.h"


loglevel_t log_level;
FILE *log_dest;


const char *log_names[5] = {"DEBUG",
                            "INFO",
                            "WARN",
                            "ERROR",
                            "FATAL"};

static void timestamp(){
  struct timeval tv;
  struct tm *ltime;
  gettimeofday(&tv, NULL);
  // automatically calls tzset()
  ltime = localtime(&tv.tv_sec);
  fprintf(log_dest, ISO8601_FMT(ltime, &tv));
  fprintf(log_dest, ": ");
}

loglevel_t log_setlevel(loglevel_t l) {
  loglevel_t old_lvl = log_level;
  log_level = l;
  return old_lvl;
}

loglevel_t log_getlevel() {
  return log_level;
}

void log_init() {
  log_level = LOGLVL_INFO;
  log_dest = stderr;
}

void log_log  (loglevel_t level, const char *fmt, ...) {
    if (log_level > level) return;
    va_list ap;
    va_start(ap, fmt);
    timestamp();
    fprintf(log_dest, "%s: ", log_names[level]);
    vfprintf(log_dest, fmt, ap);
    va_end(ap);
}

void log_fatal_perror(const char *msg) {
  int in_errno = errno;
  if (in_errno < 0) return;
  timestamp();
  fprintf(log_dest, "%s: ", log_names[LOGLVL_FATAL]);
  if (msg != NULL) fprintf(log_dest, "%s: ", msg);
  fprintf(log_dest, "%s\n", strerror(in_errno));
}

void log_clear (loglevel_t level, const char *fmt, ...) {
  if (log_level > level) return;
  va_list ap;
  va_start(ap, fmt);
  vfprintf(log_dest, fmt, ap);
  va_end(ap);
}

/* print char* in hex format */
void log_dump_serial_packet(unsigned char *packet, const int len) {
    int i;
    if (log_level > LOGLVL_DEBUG) return;

    printf("len: %d\n", len);
    if (!packet)
	return;
    for (i = 0; i < len; i++) {
	printf("%02x ", packet[i]);
	//printf("%02x(%c) ", packet[i], packet[i]);
	//printf("%c", packet[i]);
    }
    putchar('\n');
}
