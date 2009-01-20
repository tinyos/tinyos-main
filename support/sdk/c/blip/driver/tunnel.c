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
