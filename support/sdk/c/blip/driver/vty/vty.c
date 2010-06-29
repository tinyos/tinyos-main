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
#include <stdint.h>
#include <signal.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <string.h>
#include <stdarg.h>

#include "vty.h"
#include "../logging.h"

#define max(X,Y)  (((X) > (Y)) ?  (X) : (Y))

typedef enum {
  FALSE = 0,
  TRUE  = 1,
} bool;

enum {
  VTY_REMOVE_PENDING = 0x1,
};

struct vty_client {
  int                 flags;
  int                 readfd;
  int                 writefd;
  struct sockaddr_in6 ep;
  struct vty_client  *next;
  
  int                 buf_off;
  unsigned char       buf[2][1024];
  int                 argc;
  char                *argv[N_ARGS];
};

static int sock = -1;
static struct vty_client *conns = NULL;
static struct vty_cmd_table *cmd_tab;
static char prompt_str[40];

int vty_init(struct vty_cmd_table * cmds, short port) {
  struct sockaddr_in6 si_me = {
    .sin6_family = AF_INET6,
    .sin6_port = htons(port),
    .sin6_addr = IN6ADDR_ANY_INIT,
  };
  struct vty_client *tty_client;
  int len, yes = 1;

  conns = NULL;
  cmd_tab = cmds;

  strncpy(prompt_str, "blip:", 5);
  gethostname(prompt_str+5, sizeof(prompt_str)- 5);
  len=strlen(prompt_str+5);
  prompt_str[len+5]='>';
  prompt_str[len+6]=' ';
  prompt_str[len+7]='\0';

  if (isatty(fileno(stdin))) {
    setbuf(stdin, NULL);
    tty_client = (struct vty_client *)malloc(sizeof(struct vty_client));
    memset(tty_client, 0, sizeof(struct vty_client));
    tty_client->flags = 0;
    tty_client->readfd = fileno(stdin);
    tty_client->writefd = fileno(stdout);
    tty_client->next = NULL;
    conns = tty_client;
  }

  sock = socket(PF_INET6, SOCK_STREAM, 0);
  if (sock < 0) {
    log_fatal_perror("vty: socket");
    return -1;
  }

  if (setsockopt(sock, SOL_SOCKET, SO_REUSEADDR, &yes, sizeof(yes)) < 0) {
    log_fatal_perror("vty: setsockopt");
    goto abort;
  }

  if (bind(sock, (struct sockaddr *)&si_me, sizeof(si_me)) < 0) {
    log_fatal_perror("vty: bind");
    goto abort;
  }

  if (listen(sock, 2) < 0) {
    log_fatal_perror("vty: listen");
    goto abort;
  }

  return 0;
 abort:
  close(sock);
  sock = -1;
  return -1;
}

int vty_add_fds(fd_set *fds) {
  int maxfd;
  struct vty_client *cur;
  if (sock >= 0) FD_SET(sock, fds);
  maxfd = sock;

  for (cur = conns; cur != NULL; cur = cur->next) {
    if (cur->flags & VTY_REMOVE_PENDING) continue;
    FD_SET(cur->readfd, fds);
    maxfd = max(maxfd, cur->readfd);
  }
  return maxfd;
}

static void vty_print_string(struct vty_client *c, const char *fmt, ...) {
  char buf[1024];
  int len;
  va_list ap;
  va_start(ap, fmt);
  len = vsnprintf(buf, 1024, fmt, ap);
  len = write(c->writefd, buf, len);
}

static void prompt(struct vty_client *c) {
  vty_print_string(c, prompt_str);
}

static void vty_new_connection() {
  char addr_buf[512];
  struct vty_client * c = malloc(sizeof(struct vty_client));
  socklen_t len;
  if (c == NULL) return;

  len = sizeof(struct sockaddr_in6);
  c->readfd = c->writefd = accept(sock, (struct sockaddr *)&c->ep, &len);
  if (c->readfd < 0) {
    error("Accept failed!\n");
    log_fatal_perror(0);
    free(c);
    return;
  }
  c->buf_off = 0;
  memset(c->buf, 0, sizeof(c->buf));

  inet_ntop(AF_INET6, c->ep.sin6_addr.s6_addr, addr_buf, 512);
  info("VTY: new connection accepted from %s\n", addr_buf);
  vty_print_string(c, "Welcome to the blip console!\r\n");
  vty_print_string(c, " type 'help' to print the command options\r\n");
  prompt(c);
  c->flags = 0;
  c->next = conns;
  conns = c;
}

void vty_close_connection(struct vty_client *c) {
  close(c->readfd);
  if (c->readfd != c->writefd) close(c->writefd);
  c->flags |= VTY_REMOVE_PENDING;
}


void vty_dispatch_command(struct vty_client *c) {
  int i;

  if (c->argc > 0) {
    for (i = 0; i < cmd_tab->n; i++) {
      if (strncmp(c->argv[0], cmd_tab->table[i].name, 
                  strlen(cmd_tab->table[i].name) + 1) == 0) {
        cmd_tab->table[i].fn(c->writefd, c->argc, c->argv);
        break;
      }
      
      if (strncmp(c->argv[0], "quit", 4) == 0) {
        vty_close_connection(c);
        return;
      }
    }
    if (i == cmd_tab->n) {
      vty_print_string(c, "vty: %s: command not found\r\n", c->argv[0]);
    }
  }
  prompt(c);
}

void vty_handle_data(struct vty_client *c) {
  int len, i;
  char addr_buf[512];
  bool prompt_pending = FALSE;
  len = read(c->readfd, c->buf[0] + c->buf_off, sizeof(c->buf) - c->buf_off);
  if (len <= 0) {
    inet_ntop(AF_INET6, c->ep.sin6_addr.s6_addr, addr_buf, 512);
    warn("Invalid read on connection from %s: closing\n", addr_buf);
    vty_close_connection(c);
  }
  c->buf_off += len;
  // try to scan the whole line we're building up and remove/process
  // any telnet escapes in there
  
  for (i = 0; i < c->buf_off; i++) {
    int escape_len;

    if (c->buf[0][i] == 255) {
      escape_len = 2;
      // process and remove a command;
      // the command code is in buf[i+1]
      switch (c->buf[0][i+1]) {
      case TELNET_INTERRUPT:
        // ignore the command buffer we've accumulated
        memmove(&c->buf[0][0], &c->buf[0][i+2], c->buf_off - i - 2);
        c->buf_off -= i + 2;
        i = -1;
        prompt_pending = TRUE;
        continue;
      }
      if (c->buf[0][i+1] >= 250) {
        unsigned char response[3];
        // we don't do __anything__
        response[0] = 255;
        response[1] = TELNET_WONT;
        response[2] = c->buf[0][i+2];
        len = write(c->writefd, response, 3);
        escape_len++;
      }

      // this isn't like the most efficient parser ever, but since we
      // don't ask for anything and reply to everyone with DONT it seems okay.
      memmove(&c->buf[0][i], &c->buf[0][i+escape_len], 
              c->buf_off - (i + escape_len));
      c->buf_off -= escape_len;
      // restart processing at the same place
      i--;
    } else if (c->buf[0][i] == 4) {
      // EOT : make C-d work
      vty_close_connection(c);
    }
    // technically, clients are supposed to send \r\n as a newline.
    // however, the client in busybox (an important one) doesn't
    // escape the terminal input and so only sends \n.
    if (/* i > 0 && c->buf[i-1] == '\r' && */ c->buf[0][i] == '\n') {

      if (!(i <= 1 && (c->buf[0][i] == '\n' || c->buf[0][i] == '\r'))) {
        c->buf[0][i] = '\0';
        memcpy(c->buf[1], c->buf[0], i + 1);
        init_argv((char *)c->buf[1], i + 1, c->argv, &c->argc);
      }

      prompt_pending = FALSE;
      vty_dispatch_command(c);

      // start a new command at the head of the buffer
      memmove(&c->buf[0][0], &c->buf[0][i+1], c->buf_off - i - 1);
      c->buf_off -= i + 1;
      i = -1;
    }
  }

  
  if (prompt_pending) {
    vty_print_string(c, "\r\n");
    prompt(c);
    prompt_pending = FALSE;
  }
}

int vty_process(fd_set *fds) {
  struct vty_client *prev, *cur, *next;
  if (sock >= 0 && FD_ISSET(sock, fds)) {
    vty_new_connection();
  }
  for (cur = conns; cur != NULL; cur = cur->next) {
    if (FD_ISSET(cur->readfd, fds)) {
      vty_handle_data(cur);
    }
  }

  prev = NULL;
  cur = conns;
  while (cur != NULL) {
    next = cur->next;
    if (cur->flags & VTY_REMOVE_PENDING) {
      char addr_buf[512];
      inet_ntop(AF_INET6, cur->ep.sin6_addr.s6_addr, addr_buf, 512);
      info("VTY: removing connection with endpoint %s\n", addr_buf);
      free(cur);
      if (cur == conns) conns = next;
      if (prev != NULL) prev->next = next;
    } else {
      prev = cur;
    }
    cur = next;
  }

  return 0;
}

void vty_shutdown() {
  struct vty_client *cur = conns, *next;
  if (sock >= 0) close(sock);

  while (cur != NULL) {
    next = cur->next;
    if (!(cur->flags & VTY_REMOVE_PENDING)) {
      close(cur->readfd);
      if (cur->readfd != cur->writefd) close(cur->writefd);
    }
    free(cur);
    cur = next;
  }
}
