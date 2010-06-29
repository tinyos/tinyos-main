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
#include <unistd.h>
#include <fcntl.h>
#include <stdio.h>
#include <sys/select.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <linux/if.h>
#include <signal.h>
#include <string.h>
#include <limits.h>


#include "ip.h"
#include "tcplib.h"
#include "tun_dev.h"
#include "ip_malloc.h"


#define BUFSZ 1000
#define LOSS_RATE_RECPR 200
#define LOSS_RATE_TRANS 200

int sock = 0;
struct in6_addr iface_addr[16] = {{{0x20, 0x05, 0x00, 0x00, 0x00, 0x0, 0x00, 0x00,
                                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01}}};
struct sockaddr_in6 laddr;


void printBuf(uint8_t *buf, uint16_t len) {
  int i;
  // print("len: %i: ", len);
  for (i = 1; i <= len; i++) {
    printf(" 0x%02x", buf[i-1]);
    // if (i % 16 == 0) printf("\n");
  }
  printf("\n");
}

void print_split_msg(struct split_ip_msg *msg) {
  int i;
  printf("src_addr: ");
  for (i = 0; i < 16; i++) printf("0x%x ", msg->hdr.ip6_src.s6_addr[i]);
  printf("\ndst_addr: ");
  for (i = 0; i < 16; i++) printf("0x%x ", msg->hdr.ip6_dst.s6_addr[i]);
  printf("\nplen: %i hlim: %i\n", ntohs(msg->hdr.plen), msg->hdr.hlim);

  printBuf(msg->data, msg->data_len);
}

void tcplib_extern_recv(struct tcplib_sock *sock, void *data, int len) {
  // printBuf(data, len);
  if (tcplib_send(sock, data, len) < 0)
    printf("tcplib_send: fail\n");

  if (strncmp((char *)data, "close", 5) == 0) {
    printf("Server closing sock\n");
    tcplib_close(sock);
  }
}

void tcplib_extern_closed(struct tcplib_sock *sock) {
  printf("remote conn closed\n");
  tcplib_close(sock);
}

void tcplib_extern_closedone(struct tcplib_sock *sock) {
  printf("close done\n");
  free(sock->tx_buf);
  tcplib_init_sock(sock);
/*   printf("rebinding...\n"); */
}

/* called when a new connection request is received: not 
 *
 * return: a tcplib_struc, with the ops table filled in and send and
 * receive buffers allocated.
 */

struct tcplib_sock *tcplib_accept(struct tcplib_sock *conn,
                                  struct sockaddr_in6 *from) {
  printf("tcplib_accept\n");
  
  conn->tx_buf = malloc(BUFSZ);
  conn->tx_buf_len = BUFSZ;


  return conn;
}

void tcplib_send_out(struct split_ip_msg *msg, struct tcp_hdr *tcph) {
  uint8_t buf[8192];
  struct timespec tv;
  if (sock <= 0) return;

  // printf("sending message\n");

  memcpy(msg->hdr.ip6_src.s6_addr, iface_addr, 16);
  msg->hdr.ip6_src.s6_addr[15] = 2;
  msg->hdr.hlim = 64;

  memset(msg->hdr.vlfc, 0, 4);
  msg->hdr.vlfc[0] = 6 << 4;

  tcph->chksum = htons(msg_cksum(msg, IANA_TCP));
  
  tv.tv_sec = 0;
  // sleep for a ms to give up the cpu...
  tv.tv_nsec = 1000000;
  nanosleep(&tv);

  // print_split_msg(msg);
  if (rand() % LOSS_RATE_TRANS == 0) {
    printf("dropping packet on write\n");
  } else {
    printf("tun_write\n");
    tun_write(sock, msg);
  }
}

/* practice accepting connections and transfering data */
int main(int argg, char **argv) {
  char buf[8192], dev[IFNAMSIZ];
  uint8_t *payload;
  int len, i, flags;

  ip_malloc_init();

  payload = buf + sizeof(struct tun_pi);
  dev[0] = 0;
  if ((sock = tun_open(dev)) < 0) 
    exit(1);

  if (tun_setup(dev, iface_addr) < 0)
    exit(1);

  /* tun_setup turns on non-blocking IO.  Turn it off. */
  flags = fcntl(sock, F_GETFL);
  flags &= ~O_NONBLOCK;
  fcntl(sock,F_SETFL, flags);

  struct tcplib_sock srv_sock;
  tcplib_init_sock(&srv_sock);
  memcpy(laddr.sin6_addr.s6_addr, iface_addr, 16);
  laddr.sin6_addr.s6_addr[15] = 2;
  laddr.sin6_port = htons(atoi(argv[1]));

  tcplib_bind(&srv_sock, &laddr);

  fd_set fds;
  struct timeval timeout;
  FD_ZERO(&fds);
  FD_SET(sock, &fds);
  FD_SET(fileno(stdin), &fds);

  timeout.tv_sec = 0;
  timeout.tv_usec = 500000;

  while (select(sock + 1, &fds, NULL, NULL, &timeout) >= 0) {
    if (FD_ISSET(sock, &fds)) {
      if ((len = read(sock, buf, 8192)) <= 0) break;
      // printf("read %i bytes\n", len);
      struct ip6_hdr *iph = (struct ip6_hdr *)payload;
      if (iph->nxt_hdr == IANA_TCP) {
        if (rand() % LOSS_RATE_RECPR == 0) {
          printf("dropping packet on rx\n");
        } else {
          void *p = buf + sizeof(struct tun_pi) + sizeof(struct ip6_hdr);
          // printBuf(p, len - sizeof(struct tun_pi) - sizeof(struct tcp_hdr));
          if (tcplib_process(iph, p)) // len - sizeof(struct tun_pi)))
            printf("TCPLIB_PROCESS: ERROR!\n");
        }
      }
    } else if (FD_ISSET(fileno(stdin), &fds)) {
      char c = getchar();
      switch (c) {
      case 'a':
        printf("ABORTING CONNETION\n");
        tcplib_abort(&srv_sock);
        break;
      case 'c':
        printf("CLOSING CONNETION\n");
        tcplib_close(&srv_sock);
        break;
      case 's':
        printf("connection state: %i\n", srv_sock.state);
        break;
      }
    } else {
      timeout.tv_sec = 0;
      timeout.tv_usec = 500000;
      tcplib_timer_process();
    }
    if (srv_sock.state == TCP_CLOSED) {
      tcplib_bind(&srv_sock, &laddr);
    }

    FD_ZERO(&fds);
    FD_SET(sock, &fds);
    FD_SET(fileno(stdin), &fds);
  }
  tun_close(sock, dev);
}
