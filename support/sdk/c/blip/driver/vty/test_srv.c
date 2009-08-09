/*
 * "Copyright (c) 2008, 2009 The Regents of the University  of California.
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

#include <stdlib.h>
#include <signal.h>
#include <string.h>
#include "logging.h"
#include "vty.h"


void do_echo(int fd, int argc, char ** argv) {
  VTY_HEAD;
  if (argc > 1) {
    VTY_printf("%s\r\n", argv[1]);
    VTY_flush();
  }
}

struct vty_cmd echo = {"echo", do_echo};

void shutdown() {
  vty_shutdown();
  exit(0);
}

int main(int argc, char **argv) {
  int maxfd;
  fd_set fds;
  struct vty_cmd_table t;
  log_init();
  log_setlevel(LOGLVL_DEBUG);
  
  signal(SIGINT, shutdown);

  t.n = 1;
  t.table = &echo;


  vty_init(&t, atoi(argv[1]));
  while (1) {
    FD_ZERO(&fds);
    maxfd = vty_add_fds(&fds);

    select(maxfd+1, &fds, NULL, NULL, NULL);

    vty_process(&fds);
  }
  info("Done, exiting\n");

}
