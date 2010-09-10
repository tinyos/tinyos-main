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
#include <stdlib.h>
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

/* buffers for log history */
static int  log_size, log_end;
static char log_history[LOGHISTSIZ][LOGLINESIZ];

#define LOG_INCR do { \
  log_end = (log_end + 1) % LOGHISTSIZ; \
  log_size = (log_size < LOGHISTSIZ) ? (log_size + 1) : log_size; \
} while (0);

static int timestamp(char *buf, int len){
  struct timeval tv;
  struct tm *ltime;
  int rv = 0;
  gettimeofday(&tv, NULL);
  // automatically calls tzset()
  ltime = localtime(&tv.tv_sec);
  rv += snprintf(buf, len, ISO8601_FMT(ltime, &tv));
  rv += snprintf(buf + rv, len - rv, ": ");
  return rv;
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
  log_end = log_size = 0;
}

void log_addentry(char *buf) {
  strncpy(log_history[log_end], buf, LOGLINESIZ);
  log_history[log_end][LOGLINESIZ-1] = '\0';
  LOG_INCR;
}

void log_log  (loglevel_t level, const char *fmt, ...) {
  char buf[1024];
  int buf_used = 0;
  va_list ap;
  va_start(ap, fmt);

  if (log_level > level) return;
    
  buf_used += timestamp(buf, 1024 - buf_used);
  buf_used += snprintf(buf + buf_used, 1024 - buf_used, "%s: ", log_names[level]);
  buf_used += vsnprintf(buf + buf_used, 1024 - buf_used, fmt, ap);

  fputs(buf, log_dest);
  log_addentry(buf);

  va_end(ap);
}

void log_fatal_perror(const char *msg) {
  char buf[1024];
  int in_errno = errno;
  if (in_errno < 0) return;
  timestamp(buf, 1024);
  fputs(buf, log_dest);

  fprintf(log_dest, "%s: ", log_names[LOGLVL_FATAL]);
  if (msg != NULL) fprintf(log_dest, "%s: ", msg);
  fprintf(log_dest, "%s\n", strerror(in_errno));
}

void log_clear (loglevel_t level, const char *fmt, ...) {
  char buf[1024];
  if (log_level > level) return;
  va_list ap;
  va_start(ap, fmt);
  vsnprintf(buf, 1024, fmt, ap);
  fputs(buf, log_dest);
  log_addentry(buf);
  va_end(ap);
}

/* print char* in hex format */
void log_dump_serial_packet(unsigned char *packet, const int len) {
    int i;
    if (log_level > LOGLVL_DEBUG) return;

    printf("[%d]\t", len);
    if (!packet)
      return;
    for (i = 0; i < len; i++) {
      if ((i % 16) == 0 && i) printf("\n\t");
      printf("%02x ", packet[i]);
    }
    putchar('\n');
}
#if 0
void log_show_log(int fd, int argc, char **argv) {
  VTY_HEAD;
  int n = 10, i, start_point;

  if (argc == 2) {
    n = atoi(argv[1]);
  }

  if (n == 0 || n > log_size) {
    n = log_size;
  } 

  start_point = (log_end - n);
  if (start_point < 0) start_point += LOGHISTSIZ;
    
  for (i = 0; i < n; i++) {
    int idx = (start_point + i) % LOGHISTSIZ;
    VTY_printf("%s", log_history[idx]);
    VTY_flush();
  }

  VTY_flush();
}
#endif
