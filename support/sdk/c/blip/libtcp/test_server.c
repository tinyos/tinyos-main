
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


#include "ip.h"
#include "tcplib.h"
#include "tun_dev.h"
#include "ip_malloc.h"


#define BUFSZ 1024
#define LOSS_RATE_RECPR 100

int sock = 0;
uint8_t iface_addr[16] = {0x20, 0x01, 0x00, 0x00, 0xde, 0xad, 0xbe, 0xef,
                          0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01};

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
  for (i = 0; i < 16; i++) printf("0x%x ", msg->hdr.src_addr[i]);
  printf("\ndst_addr: ");
  for (i = 0; i < 16; i++) printf("0x%x ", msg->hdr.dst_addr[i]);
  printf("\nplen: %i hlim: %i\n", ntohs(msg->hdr.plen), msg->hdr.hlim);

  printBuf(msg->data, msg->data_len);
}

void rx(struct tcplib_sock *sock, void *data, int len) {
  // printBuf(data, len);
  if (tcplib_send(sock, data, len) < 0)
    printf("tcplib_send: fail\n");
}

void cl(struct tcplib_sock *sock) {
  printf("remote conn closed\n");
  tcplib_close(sock);
}

void cd(struct tcplib_sock *sock) {
  printf("local close done\n");
  free(sock->rx_buf);
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
  conn->rx_buf = malloc(BUFSZ);
  conn->rx_buf_len = BUFSZ;
  
  conn->tx_buf = malloc(BUFSZ);
  conn->tx_buf_len = BUFSZ;

  conn->ops.recvfrom = rx;
  conn->ops.closed = cl;
  conn->ops.close_done = cd;

  return conn;
}

void tcplib_send_out(struct split_ip_msg *msg, struct tcp_hdr *tcph) {
  uint8_t buf[8192];
  if (sock <= 0) return;

  memcpy(msg->hdr.src_addr, iface_addr, 16);
  msg->hdr.src_addr[15] = 2;
  msg->hdr.hlim = 64;

  memset(msg->hdr.vlfc, 0, 4);
  msg->hdr.vlfc[0] = 6 << 4;

  tcph->chksum = msg_cksum(msg, IANA_TCP);
  
  // print_split_msg(msg);
  if (rand() % LOSS_RATE_RECPR == 0) {
    printf("dropping packet on write\n");
  } else {
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

  timeout.tv_sec = 0;
  timeout.tv_usec = 500000;

  while (select(sock + 1, &fds, NULL, NULL, &timeout) >= 0) {
    if (FD_ISSET(sock, &fds)) {
      if ((len = read(sock, buf, 8192)) <= 0) break;
      struct ip6_hdr *iph = (struct ip6_hdr *)payload;
      if (iph->nxt_hdr == IANA_TCP) {
        if (rand() % LOSS_RATE_RECPR == 0) {
          printf("dropping packet on rx\n");
        } else {
          if (tcplib_process(payload, len - sizeof(struct tun_pi)))
            printf("TCPLIB_PROCESS: ERROR!\n");
        }
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
  }
  tun_close(sock, dev);
}
