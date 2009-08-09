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
#define VTY_flush()               write(fd, __vty_buf, __vty_len); __vty_len = 0

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
