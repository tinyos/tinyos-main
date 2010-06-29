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
#include "config.h"
#include "logging.h"
#include "vty/vty.h"

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
  c->retries = BLIP_L2_RETRIES;

  while (fgets(real_buf, BUF_LEN, fp) != NULL) {
    buf = real_buf;
    rm_comment(buf);
    upd_start(&buf);
    if (sscanf(buf, "addr %s\n", arg) > 0) {
      inet_pton6(arg, &c->router_addr);
      gotargs ++;
    } else if (sscanf(buf, "proxy %s\n", c->proxy_dev) > 0) {
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
    } else if (*buf != '\0') {
      // anything else indicates that there's invalid input.
      return 1;
    }
  }
  fclose(fp);

  if (gotargs != 3) return 1;

  info("Read config from '%s'\r\n", file);
  if (strncmp(c->proxy_dev, "lo", 3) != 0) {
    info("Proxying neighbor advertisements to %s\r\n", c->proxy_dev);
  }
  info("Using channel %i\r\n", c->channel);
  info("Retries: %i\r\n", c->retries);
  lastconfig = c;
  return 0;
}

#define STR(X) #X

void config_print(int fd, int argc, char **argv) { //struct config *c) {
  VTY_HEAD;
  char buf[64];
  VTY_printf ("configuration:\r\n");
  inet_ntop(AF_INET6, &lastconfig->router_addr, buf, 64);
  VTY_printf ("  router address: %s\r\n", buf);
  VTY_printf("  proxy dev: %s\r\n", lastconfig->proxy_dev);
  VTY_printf("  channel: %i\r\n", lastconfig->channel);
  VTY_printf("  version: %s\r\n", " $Id: config.c,v 1.2 2009/08/09 23:36:05 sdhsdh Exp ");
  VTY_printf("  retries: %i\r\n", lastconfig->retries);
  VTY_flush();
}
