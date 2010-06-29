/*
 * Copyright (c) 2008, 2009 The Regents of the University  of California.
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
