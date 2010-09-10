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
/*
 * @author Stephen Dawson-Haggerty <stevedh@eecs.berkeley.edu>
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <arpa/inet.h>

#include <lib6lowpan/ip.h>
#include "device-config.h"
#include "logging.h"

#define BUF_LEN 200
struct config *lastconfig;

void rm_comment (char *buf) {
  while (*buf != '#' && *buf != '\0')
    buf++;
  *buf = '\0';
}

void upd_start(char **buf) {
  while ((**buf == ' ' || **buf == '\t' || **buf == '\n') && **buf != '\0')
    *buf = (*buf) + 1;
}

int config_parse(const char *file, struct config *c) {
  char *buf, real_buf[BUF_LEN], arg[BUF_LEN];
  FILE *fp = fopen(file, "r");
  int gotargs = 0;
  if (fp == NULL) return 1;

  // defaults
  c->retries = 3; // BLIP_L2_RETRIES;
  c->lpl_interval = 0;
  c->delay = 30;
  c->panid = 0x22;

  while (fgets(real_buf, BUF_LEN, fp) != NULL) {
    buf = real_buf;
    rm_comment(buf);
    upd_start(&buf);
    if (sscanf(buf, "prefix %s\n", arg) > 0) {
      inet_pton6(arg, &c->router_addr);
      gotargs ++;
    } else if (sscanf(buf, "channel %i\n", &c->channel) > 0) {
      if (c->channel < 11 || c->channel > 26) {
        fatal("Invalid channel specified in '%s'\n", file);
        exit(1);
      }
      gotargs ++;
    } else if (sscanf(buf, "log %s\n", arg) > 0) {
      int i;
      for (i = 0; i < 5; i++) {
        if (strncmp(log_names[i], arg, strlen(log_names[i])) == 0) {
          info("Read log level: %s\n", arg);
          log_setlevel(i);
          break;
        }
      }
    } else if (sscanf(buf, "retry %i\n", &c->retries) > 0) {
      if (c->retries <= 0 || c->retries > 25) {
        warn("retry value set to %i: outside of the recommended range (0,25]\n", c->retries);
      }
    } else if (sscanf(buf, "lpl %i\n", &c->lpl_interval) > 0) {
      debug("LPL interval set to %i\n", c->lpl_interval);
    } else if (sscanf(buf, "delay %i\n", &c->delay) > 0) {
      debug("Radio delay set to %ims\n", c->delay);
    } else if (*buf != '\0') {
      // anything else indicates that there's invalid input.
      return 1;
    }
  }
  fclose(fp);

  if (gotargs < 2) return 1;

  info("Read config from '%s'\r\n", file);
  info("Using channel %i\r\n", c->channel);
  debug("Retries: %i\r\n", c->retries);
  lastconfig = c;
  return 0;
}

#if 0

#define STR(X) #X

void config_print(int fd, int argc, char **argv) { //struct config *c) {
  VTY_HEAD;
  char buf[64];
  VTY_printf ("configuration:\r\n");
  inet_ntop(AF_INET6, &lastconfig->router_addr, buf, 64);
  VTY_printf("  router address: %s\r\n", buf);
  VTY_printf("  proxy dev: %s\r\n", lastconfig->proxy_dev);
  VTY_printf("  version: %s\r\n", " $Id: config.c,v 1.2 2009/08/09 23:36:05 sdhsdh Exp ");
  VTY_printf("  radio retries: %i delay: %ims channel: %i lpl interval: %ims \r\n",
             lastconfig->retries, lastconfig->delay, lastconfig->channel, lastconfig->lpl_interval);
  VTY_flush();
}

#endif
