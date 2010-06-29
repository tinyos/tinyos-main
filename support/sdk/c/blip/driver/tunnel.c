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
 * Implementation of user-mode driver and IP gateway using a node
 * running IPBaseStation as 802.15.4 hardware.  Uses kernel tun
 * interface to route addresses.
 * 
 */
#include <stdio.h>
#include <stdint.h>
#include <unistd.h>

#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>

uint16_t shortAddr;
int tun_fd;
char *tun_dev = "/dev/net/tun";

void usage(char **args) {
  fprintf(stderr, "\n\t%s <my-short-addr>\n\n", args[0]);
}

int create_tunnel() {
  struct ifreq ifr;
  if ((tun_fd = open(tun_dev, O_RDWR)) < 0) {
    fprintf(stderr, "Failed to open '%s' : ", tun_dev);
    perror("");
    return 1;
  }
  ifr.irf_flags = IFF_TAP | IFF_NO_PI;
  str

  return 0;
}

int main(int argc, char **argv) {
  if (argc != 2) {
    usage(argv);
    return 1;
  }
  shortAddr = atoi(argv[1]);

  if (create_tunnel())
    return 1;

  sleep(20);

  return 0;
}
