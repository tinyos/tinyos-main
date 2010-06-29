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
 *
 * This is a very simple set of functions to allow a program using a
 * single blocking select() loop to include a telnet server.  Most of
 * the telnet RFC854 protocol is not implemented; this just gives you
 * an easy way to add a simple shell that doesn't do much.
 *
 * Readline-like editing would be nice; unfortunatly readline itself
 * is GPL, so it's not an option.
 */

#ifndef _VTY_H_
#define _VTY_H_

#include <unistd.h>
#include <sys/select.h>

// helpful macros since you can't do straight printf() on a socket
#define VTY_HEAD                  char __vty_buf[4096]; int __vty_len = 0
#define VTY_printf(fmt, args...)  __vty_len += snprintf(__vty_buf + __vty_len, 4096 - __vty_len, \
                                                        fmt, ## args)
#define VTY_flush()               __vty_len = write(fd, __vty_buf, __vty_len); __vty_len = 0

#define VTYNAMSIZ 16

// set these up and pass it to vty_init().  the only builtin is 'quit'.
struct vty_cmd {
  char name[VTYNAMSIZ];
  void (*fn)(int fd, int argc, char **argv);
};

struct vty_cmd_table {
  int              n;
  struct vty_cmd * table;
};

int  vty_init(struct vty_cmd_table *cmd_tab, short port);
int  vty_add_fds(fd_set *fds);
int  vty_process(fd_set *fds);
void vty_shutdown();

// defined in util.c  N_ARGS is the maximum number length of argv.
#define N_ARGS  30
void init_argv(char *cmd, int len, char **argv, int *argc);


// values from telnet rfc854.  We don't implement very much at all of
// the telnet protocol
#define TELNET_INTERRUPT 244
#define TELNET_WONT      252

#endif
