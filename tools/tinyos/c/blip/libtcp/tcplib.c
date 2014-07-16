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

/* A nonblocking library-based implementation of TCP
 *
 * There are some things like timers which need to be handled
 * externally with callbacks.
 *
 * @author Stephen Dawson-Haggerty <stevedh@eecs.berkeley.edu>
 */

#include <stdio.h>
#include <string.h>
#include "lib6lowpan/ip_malloc.h"
#include "lib6lowpan/in_cksum.h"
#include "lib6lowpan/6lowpan.h"
#include "lib6lowpan/ip.h"

#include "libtcp/tcplib.h"
#include "libtcp/circ.h"

static struct tcplib_sock *conns = NULL;

#define ONE_SEGMENT(X)  ((X)->mss)

#ifdef PC
uint16_t alloc_local_port() {
  return (time(NULL) & 0xffff) | 0x8000;
}
#else
uint16_t alloc_local_port() {
  return 21310;
}
#endif

static inline void conn_add_once(struct tcplib_sock *sock) {
  struct tcplib_sock *iter;

  for (iter = conns; iter != NULL; iter = iter->next) {
    if (iter == sock) break;
  }
  if (iter == NULL) {
    sock->next = conns;
    conns = sock;
  }

}
static int isInaddrAny(struct in6_addr *addr) {
  int i;
  for (i = 0; i < 8; i++)
    if (addr->s6_addr16[i] != 0) break;
  if (i != 8) return 0;
  return 1;
}

#ifdef PC
#include <arpa/inet.h>

void print_conn(struct tcplib_sock *sock) {
  char addr_buf[32];
  printf("tcplib socket state: %i:\n", sock->state);
  inet_ntop(AF_INET6, sock->l_ep.sin6_addr.s6_addr, addr_buf, 32);
  printf(" local ep: %s port: %u\n", addr_buf, ntohs(sock->l_ep.sin6_port));
  inet_ntop(AF_INET6, sock->r_ep.sin6_addr.s6_addr, addr_buf, 32);
  printf(" remote ep: %s port: %u\n", addr_buf, ntohs(sock->r_ep.sin6_port));
  printf(" tx buf length: %i\n", sock->tx_buf_len);
}
void print_headers(struct ip6_hdr *iph, struct tcp_hdr *tcph) {
  char addr_buf[32];
  printf("headers ip length: %i:\n", ntohs(iph->ip6_plen));
  inet_ntop(AF_INET6, iph->ip6_src.s6_addr, addr_buf, 32);
  printf(" source: %s port: %u\n", addr_buf, ntohs(tcph->srcport));
  inet_ntop(AF_INET6, iph->ip6_dst.s6_addr, addr_buf, 32);
  printf(" remote ep: %s port: %u\n", addr_buf, ntohs(tcph->dstport));
  printf(" tcp seqno: %u ackno: %u\n", ntohl(tcph->seqno), ntohl(tcph->ackno));
}
#else 
#undef printf
#define printf(FMT, args ...) ;
#endif

static struct tcplib_sock *conn_lookup(struct ip6_hdr *iph, 
                                       struct tcp_hdr *tcph) {
  struct tcplib_sock *iter;
  //printf("looking up conns: %p %p\n", iph, tcph);
  // print_headers(iph, tcph);
  for (iter = conns; iter != NULL; iter = iter->next) {
    // print_conn(iter);
    printf("conn lport: %i\n", ntohs(iter->l_ep.sin6_port));
    if (((memcmp(iph->ip6_dst.s6_addr, iter->l_ep.sin6_addr.s6_addr, 16) == 0) ||
         isInaddrAny(&iter->l_ep.sin6_addr)) &&
        tcph->dstport == iter->l_ep.sin6_port &&
        (iter->r_ep.sin6_port == 0 ||
         (memcmp(&iph->ip6_src, &iter->r_ep.sin6_addr, 16) == 0 &&
          tcph->srcport == iter->r_ep.sin6_port)))
      return iter;
  }
  return NULL;
}

static int conn_checkport(uint16_t port) {
  struct tcplib_sock *iter;

  for (iter = conns; iter != NULL; iter = iter->next) {
    if (iter->l_ep.sin6_port == port)
      return -1;
  }
  return 0;
}

struct tcp_hdr *find_tcp_hdr(struct ip6_packet *msg) {
  if (msg->ip6_hdr.ip6_nxt == IANA_TCP) {
    return (struct tcp_hdr *)msg->ip6_data->iov_base;
  }
  return NULL;
}

static struct ip6_packet *get_ipmsg(int plen) {
  int alen = sizeof(struct ip6_packet) + sizeof(struct tcp_hdr) + 
    sizeof(struct ip_iovec) + plen;
  char *buf = ip_malloc(alen);
  struct ip6_packet *msg = (struct ip6_packet *)buf;
  struct ip_iovec *iov = (struct ip_iovec *)(buf + alen - sizeof(struct ip_iovec));

  if (buf == NULL) return NULL;
  memset(msg, 0, sizeof(struct ip6_packet) + sizeof(struct tcp_hdr));
  msg->ip6_hdr.ip6_nxt = IANA_TCP;
  msg->ip6_hdr.ip6_plen = htons(sizeof(struct tcp_hdr) + plen);

  msg->ip6_data = iov;
  iov->iov_next = NULL;
  iov->iov_len = plen + sizeof(struct tcp_hdr);
  iov->iov_base = (void *)(msg + 1);

  return msg;
}

static void __tcplib_send(struct tcplib_sock *sock,
                          struct ip6_packet *msg) {
  struct tcp_hdr *tcph = find_tcp_hdr(msg);
  if (tcph == NULL) return;
  memcpy(&msg->ip6_hdr.ip6_dst, &sock->r_ep.sin6_addr, 16);

  sock->flags &= ~TCP_ACKPENDING;
  // sock->ackno = ntohl(tcph->ackno);

  printf("srcprt: %hu dstprt: %hu\n", ntohs(sock->l_ep.sin6_port), 
         ntohs(sock->r_ep.sin6_port));

  tcph->srcport = sock->l_ep.sin6_port;
  tcph->dstport = sock->r_ep.sin6_port;
  tcph->offset = sizeof(struct tcp_hdr) * 4;
  tcph->window = htons(sock->my_wind);
  tcph->chksum = 0;
  tcph->urgent = 0;

  tcplib_send_out(msg, tcph);
}

static void tcplib_send_ack(struct tcplib_sock *sock, int fin_seqno, uint8_t flags) {
  struct ip6_packet *msg = get_ipmsg(0);
  printf("sending ACK\n");
      
  if (msg != NULL) {
    struct tcp_hdr *tcp_rep = (struct tcp_hdr *)(msg + 1);
    tcp_rep->flags = flags;


    tcp_rep->seqno = htonl(sock->seqno);
    tcp_rep->ackno = htonl(sock->ackno +
                           (fin_seqno ? 1 : 0));
    printf("sending ACK seqno: %u ackno: %u\n", ntohl(tcp_rep->seqno), ntohl(tcp_rep->ackno));
    __tcplib_send(sock, msg);
    ip_free(msg);
  } else {
    printf("Could not send ack-- no memory!\n");
  }
}

static void tcplib_send_rst(struct ip6_hdr *iph, struct tcp_hdr *tcph) {
  struct ip6_packet *msg = get_ipmsg(0);
      
  if (msg != NULL) {
    struct tcp_hdr *tcp_rep = (struct tcp_hdr *)(msg + 1);

    memcpy(&msg->ip6_hdr.ip6_dst, &iph->ip6_src, 16);

    tcp_rep->flags = TCP_FLAG_RST | TCP_FLAG_ACK;

    tcp_rep->ackno = htonl(ntohl(tcph->seqno) + 1);
    tcp_rep->seqno = tcph->ackno;;

    tcp_rep->srcport = tcph->dstport;
    tcp_rep->dstport = tcph->srcport;
    tcp_rep->offset = sizeof(struct tcp_hdr) * 4;
    tcp_rep->window = 0;
    tcp_rep->chksum = 0;
    tcp_rep->urgent = 0;

    tcplib_send_out(msg, tcp_rep);

    ip_free(msg);
    
  }  
}

/* send all the data in the tx buffer, starting at sseqno */
static int tcplib_output(struct tcplib_sock *sock, uint32_t sseqno) {
  // the output size is the minimum of the advertised window and the
  // conjestion window.  of course, if we have less data we send even
  // less.
  int seg_size = min(sock->seqno - sseqno, sock->r_wind);
  printf("r_wind: %i\n", sock->r_wind);
  seg_size = min(seg_size, sock->cwnd);
  while (seg_size > 0 && sock->seqno > sseqno) {
    // printf("sending seg_size: %i\n", seg_size);
    struct ip6_packet *msg = get_ipmsg(seg_size);
    struct tcp_hdr *tcph;
    uint8_t *data;
    if (msg == NULL) return -1;
    tcph = (struct tcp_hdr *)(msg + 1);
    data = (uint8_t *)(tcph + 1);

    tcph->flags = TCP_FLAG_ACK;
    tcph->seqno = htonl(sseqno);
    tcph->ackno = htonl(sock->ackno);

    printf("tcplib_output: seqno: %u ackno: %u len: %i headno: %u\n",
           ntohl(tcph->seqno), ntohl(tcph->ackno), seg_size,
           circ_get_seqno(sock->tx_buf));

    if (seg_size != circ_buf_read(sock->tx_buf, sseqno, data, seg_size)) {
      printf("WARN: circ could not read!\n");
    }
    __tcplib_send(sock, msg);
    ip_free(msg);

    sseqno += seg_size;
    seg_size = min(sock->seqno - sseqno, sock->mss);
  }
  return 0;
}

int tcplib_init_sock(struct tcplib_sock *sock) {
  memset(sock, 0, sizeof(struct tcplib_sock) - sizeof(struct tcplib_sock *));
  sock->mss = 200;
  sock->my_wind = 200;
  sock->cwnd = ONE_SEGMENT(sock);
  sock->ssthresh = 0xffff;
  conn_add_once(sock);
  return 0;
}

/* called when a new segment arrives. */
/* deliver as much data to the app as possible, and update the ack
 * number of the socket to reflect how much was delivered 
 */
static int receive_data(struct tcplib_sock *sock, struct tcp_hdr *tcph, int len) {
  uint8_t *ptr;
  int payload_len;

  ptr = ((uint8_t *)tcph) + (tcph->offset / 4);
  payload_len = len - (tcph->offset / 4);
  sock->ackno = ntohl(tcph->seqno) + payload_len;

  if (payload_len > 0) {
    tcplib_extern_recv(sock, ptr, payload_len);
  }
  return payload_len;
}

static void reset_ssthresh(struct tcplib_sock *conn) {
  uint16_t new_ssthresh = min(conn->cwnd, conn->r_wind) / 2;
  if (new_ssthresh < 2 * ONE_SEGMENT(conn))
    new_ssthresh = 2 * ONE_SEGMENT(conn);
  conn->ssthresh = new_ssthresh;
}

int tcplib_process(struct ip6_hdr *iph, void *payload) {
  int rc = 0;
  struct tcp_hdr *tcph;
  struct tcplib_sock *this_conn;
  //   uint8_t *ptr;
  int len = ntohs(iph->ip6_plen) + sizeof(struct ip6_hdr);
  int payload_len;
  uint32_t hdr_seqno, hdr_ackno;
  int connect_done = 0;

  tcph = (struct tcp_hdr *)payload;
  payload_len = len - sizeof(struct ip6_hdr) - (tcph->offset / 4);

  /* if there's no local */
  this_conn = conn_lookup(iph, tcph);
  // printf("conn: %p\n", this_conn);
  if (this_conn != NULL) {
    hdr_seqno = ntohl(tcph->seqno);
    hdr_ackno = ntohl(tcph->ackno);

    if (tcph->flags & TCP_FLAG_RST) {
      /* Really hose this connection if we get a RST packet.
       * still TODO: RST generation for unbound ports */
      printf("connection reset by peer\n");
          
      tcplib_extern_closedone(this_conn);
      // tcplib_init_sock(this_conn);
      return 0;
    }
    // always get window updates from new segments
    // TODO : this should be after we detect out-of-sequence ACK
    // numbers!
    this_conn->r_wind = ntohs(tcph->window);
    printf("State: %i\n", this_conn->state);

    switch (this_conn->state) {
    case TCP_LAST_ACK:
      if (tcph->flags & TCP_FLAG_ACK && 
          hdr_ackno == this_conn->seqno + 1) {

        this_conn->state = TCP_CLOSED;
        tcplib_extern_closedone(this_conn);
        break;
      }
    case TCP_FIN_WAIT_1:
      printf("IN FIN_WAIT_1, %i\n", (tcph->flags & TCP_FLAG_FIN));
      if (tcph->flags & TCP_FLAG_ACK && 
          hdr_ackno == this_conn->seqno + 1) {
        if (tcph->flags & TCP_FLAG_FIN) {
          this_conn->seqno++;
          this_conn->state = TCP_TIME_WAIT;
          
          // the TIME_WAIT state is problematic, since it holds up the
          // resources while we're in it...
          this_conn->timer.retx = TCPLIB_TIMEWAIT_LEN;
        } else {
          this_conn->timer.retx = TCPLIB_2MSL;
          this_conn->state = TCP_FIN_WAIT_2;
        }
      }
      // this generate the ACK we need here
      goto ESTABLISHED;
    case TCP_FIN_WAIT_2:
      if (tcph->flags & TCP_FLAG_FIN) {
        this_conn->seqno++;
        this_conn->state = TCP_TIME_WAIT;
        
        this_conn->timer.retx = TCPLIB_TIMEWAIT_LEN;
        tcplib_send_ack(this_conn, 0, TCP_FLAG_ACK);
      }
      break;

    case TCP_SYN_SENT:
      if (tcph->flags & (TCP_FLAG_SYN | TCP_FLAG_ACK)) {
        // got a syn-ack
        // send the ACK this_conn
        this_conn->state = TCP_ESTABLISHED;
        this_conn->ackno = hdr_seqno + 1;
        connect_done = 1;
        // skip the LISTEN processing
        // this will also generate an ACK
        goto ESTABLISHED;
      } else if (tcph->flags & TCP_FLAG_SYN) {
        // otherwise the state machine says we're in a simultaneous open, so continue doen
        this_conn->state = TCP_SYN_RCVD;
        connect_done = 1;
      } else {
        printf("sending RST on bad data in state SYN_SENT\n");
        // we'll just let the timeout eventually close the socket, though
        tcplib_send_rst(iph, tcph);
        break;
      }
    case TCP_SYN_RCVD:
    case TCP_LISTEN:
      /* not connected. */
      if (tcph->flags & TCP_FLAG_SYN) {
        struct tcplib_sock *new_sock;

        if (this_conn->state == TCP_LISTEN) {
          memcpy(&this_conn->r_ep.sin6_addr, &iph->ip6_src, 16);
          this_conn->r_ep.sin6_port = tcph->srcport;
          new_sock = tcplib_accept(this_conn, &this_conn->r_ep);
          if (new_sock != this_conn) {
            memset(this_conn->r_ep.sin6_addr.s6_addr, 0, 16);
            this_conn->r_ep.sin6_port = 0;
            if (new_sock != NULL) {
              memcpy(&new_sock->r_ep.sin6_addr, &iph->ip6_src, 16);
              new_sock->r_ep.sin6_port = tcph->srcport;
              conn_add_once(new_sock);
            }
          }
          if (new_sock == NULL) {
            tcplib_send_rst(iph, tcph);
            break;
          }
          memcpy(&new_sock->l_ep.sin6_addr, &iph->ip6_dst, 16);
          new_sock->l_ep.sin6_port = tcph->dstport;

          new_sock->ackno = hdr_seqno + 1;
          circ_buf_init(new_sock->tx_buf, new_sock->tx_buf_len,
                        0xcafebabe + 1);
        } else {
          /* recieved a SYN retransmission. */
          new_sock = this_conn;
        }

        if (new_sock != NULL) {
          new_sock->seqno = 0xcafebabe + 1;
          new_sock->state = TCP_SYN_RCVD;
          tcplib_send_ack(new_sock, 0, TCP_FLAG_ACK | TCP_FLAG_SYN);
          new_sock->seqno++;
        } else {
          memset(&this_conn->r_ep, 0, sizeof(struct sockaddr_in6));
        }
      } else if (this_conn->state == TCP_LISTEN) {
        tcplib_send_rst(iph, tcph);
        break;
      }
      /* this is SYN_RECVd */
      if (tcph->flags & TCP_FLAG_ACK) {
        this_conn->state = TCP_ESTABLISHED;
      } 
      /* fall through to handle any data. */
      

    case TCP_CLOSE_WAIT:
    case TCP_ESTABLISHED:
    ESTABLISHED:

      /* ack any data in this packet */
      if (this_conn->state == TCP_ESTABLISHED || this_conn->state == TCP_FIN_WAIT_1) {
        if (payload_len > 0) {
          if ((this_conn->flags & TCP_ACKPENDING) == TCP_ACKPENDING) {
            // printf("Incr would overflow\n");
          }
          this_conn->flags ++;
        }


        // receive side sequence check and add data
        printf("seqno: %u ackno: %u\n", hdr_seqno, hdr_ackno);
        printf("conn seqno: %u ackno: %u\n", this_conn->seqno, this_conn->ackno);


        // send side recieve sequence check and congestion window updates.
        if (hdr_ackno > circ_get_seqno(this_conn->tx_buf)) {
          // new data is being ACKed
          // or we haven't sent anything new
          if (this_conn->cwnd <= this_conn->ssthresh) {
            // in slow start; increase the cwnd by one segment
            this_conn->cwnd += ONE_SEGMENT(this_conn);
            // printf("in slow start\n");
          } else {
            // in congestion avoidance
            this_conn->cwnd += (ONE_SEGMENT(this_conn) * ONE_SEGMENT(this_conn)) / this_conn->cwnd;
            // printf("in congestion avoidence\n");
          }
          // printf("ACK new data: cwnd: %i ssthresh: %i\n", this_conn->cwnd, this_conn->ssthresh);
          // reset the duplicate ack counter
          UNSET_ACK_COUNT(this_conn->flags);
          // truncates the ack buffer 
          circ_shorten_head(this_conn->tx_buf, hdr_ackno);
          // printf("ack_count: %i\n", GET_ACK_COUNT(this_conn->flags));

          if (this_conn->seqno == hdr_ackno) {
            tcplib_extern_acked(this_conn);
          }
        } else if (this_conn->seqno > circ_get_seqno(this_conn->tx_buf)) {
          // this is a duplicate ACK
          //  - increase the counter of the number of duplicate ACKs
          //  - if we get to three duplicate ACK's, start resending at
          //    the ACK number because this probably means we lost a segment

          INCR_ACK_COUNT(this_conn->flags);
          // printf("ack_count: %i\n", GET_ACK_COUNT(this_conn->flags));
          // printf("dup ack count: %i\n", GET_ACK_COUNT(this_conn->flags));
          // a "dup ack count" of 2 is really 3 total acks because we start with zero
          if (GET_ACK_COUNT(this_conn->flags) == 2) {
            UNSET_ACK_COUNT(this_conn->flags);
            printf("detected multiple duplicate ACKs-- doing fast retransmit [%u, %u]\n",
                   circ_get_seqno(this_conn->tx_buf),
                   this_conn->seqno);

            // this is our detection of a "duplicate ack" event.
            // we are going to reset ssthresh and retransmit the data.
            reset_ssthresh(this_conn);
            tcplib_output(this_conn, circ_get_seqno(this_conn->tx_buf));
            this_conn->timer.retx = 6;
            
          }
        }

        if (hdr_seqno != this_conn->ackno) {
          printf("==> received forward segment\n");
          if ((hdr_seqno > this_conn->ackno + this_conn->my_wind) ||
              (hdr_seqno < this_conn->ackno - this_conn->my_wind)) {
            // send a RST on really wild data 
            tcplib_send_rst(iph, tcph);
          } else {
            tcplib_send_ack(this_conn, 0, TCP_FLAG_ACK);
            this_conn->flags |= TCP_ACKSENT;
          }
        } else { // (hdr_seqno == this_conn->ackno) {
          printf("receive data [%li]\n", len - sizeof(struct ip6_hdr));

          if (receive_data(this_conn, tcph, len - sizeof(struct ip6_hdr)) > 0 &&
              this_conn->flags & TCP_ACKSENT) {
            this_conn->flags &= ~TCP_ACKSENT;
            tcplib_send_ack(this_conn, 0, TCP_FLAG_ACK);
          }
        }

        // reset the retransmission timer
        if (this_conn->timer.retx == 0)
          this_conn->timer.retx = 6;
      }

      if (connect_done && !(this_conn->flags & TCP_CONNECTDONE)) {
        this_conn->flags |= TCP_CONNECTDONE;
        tcplib_extern_connectdone(this_conn, 0);
      }

    case TCP_TIME_WAIT:
      if ((payload_len > 0 && (this_conn->flags & TCP_ACKPENDING) >= 1) 
          || tcph->flags & TCP_FLAG_FIN) {
        tcplib_send_ack(this_conn, (payload_len == 0 && (tcph->flags & TCP_FLAG_FIN)), TCP_FLAG_ACK);
        /* only close the connection if we've gotten all the data */
        if (this_conn->state == TCP_ESTABLISHED 
            && (tcph->flags & TCP_FLAG_FIN)
            && hdr_seqno  == this_conn->ackno) {
          this_conn->state = TCP_CLOSE_WAIT;
          tcplib_extern_closed(this_conn);
        }
      }
      break;
    case TCP_CLOSED:
    default:
      rc = -1;
      // printf("sending RST\n");
      // tcplib_send_ack(this_conn, 0, TCP_FLAG_ACK | TCP_FLAG_RST);
    }
  } else {
    /* this_conn was NULL */
    /* interestingly, TCP sends a RST on this condition, not an ICMP error.  go figure. */
    printf("sending rst on missing connection\n");
    tcplib_send_rst(iph, tcph);

  }
  return rc;
}


/* bind the socket to a local address */
int tcplib_bind(struct tcplib_sock *sock,
                struct sockaddr_in6 *addr) {
  /* not using an already-bound port */
  /* TODO : SDH : check local address */
  if (conn_checkport(addr->sin6_port))
    return -1;
  
  memcpy(&sock->l_ep, addr, sizeof(struct sockaddr_in6));
  /* passive open */
  sock->state = TCP_LISTEN;
  return 0;
}

/* connect the socket to a remote endpoint */
int tcplib_connect(struct tcplib_sock *sock,
                   struct sockaddr_in6 *serv_addr) {
  if (sock->tx_buf == NULL)
    return -1;

  switch (sock->state) {
  case TCP_CLOSED:
    // passive open; need to set up the local endpoint.
    memset(&sock->l_ep, 0, sizeof(struct sockaddr_in6));
    sock->l_ep.sin6_port = htons(alloc_local_port());
    break;
  case TCP_LISTEN:
    // we got here by calling bind, so we're cool.
    break;
  default:
    return -1;
  }
  circ_buf_init(sock->tx_buf, sock->tx_buf_len,
                0xcafebabe + 1);

  sock->ackno = 0;
  sock->seqno = 0xcafebabe;
  memcpy(&sock->r_ep, serv_addr, sizeof(struct sockaddr_in6));
  tcplib_send_ack(sock, 0, TCP_FLAG_SYN);
  sock->state = TCP_SYN_SENT;
  sock->seqno++;
  sock->timer.retx = 6;

  return 0;
}


int tcplib_send(struct tcplib_sock *sock, void *data, int len) {
  /* have enough tx buffer left? */
  if (sock->state != TCP_ESTABLISHED)
    return -1;
  if (sock->seqno - circ_get_seqno(sock->tx_buf) + len > sock->tx_buf_len) // circ_get_window(sock->tx_buf))
    return -1;
  if (circ_buf_write(sock->tx_buf, sock->seqno, data, len) < 0)
    return -1;

  sock->seqno += len;
  // printf("tcplib_output from send\n");
  // tcplib_output(sock, sock->seqno - len);

  // this will let multiple calls to send() get combined into a single packet
  // the data will be sent out next time the timer fires
  sock->timer.retx = 1;
  
  // 3 seconds
  //if (sock->timer.retx == 0)
  //sock->timer.retx = 6;

  return 0;
}

void tcplib_retx_expire(struct tcplib_sock *sock) {
  // printf("retransmission timer expired!\n");
  sock->retxcnt++;
  switch (sock->state) {
  case TCP_ESTABLISHED:
    if (circ_get_seqno(sock->tx_buf) != sock->seqno) {
      printf("retransmitting [%u, %u]\n", circ_get_seqno(sock->tx_buf),
             sock->seqno);
      reset_ssthresh(sock);
      // restart slow start
      sock->cwnd = ONE_SEGMENT(sock);
      // printf("tcplib_output from timer\n");
      tcplib_output(sock, circ_get_seqno(sock->tx_buf));
      sock->timer.retx = 6;
    } else {
      sock->retxcnt--;
    }
    break;
  case TCP_SYN_SENT:
    tcplib_send_ack(sock, 0, TCP_FLAG_SYN);
    sock->timer.retx = 6;
    break;
  case TCP_LAST_ACK:
  case TCP_FIN_WAIT_1:
    tcplib_send_ack(sock, 1, TCP_FLAG_ACK | TCP_FLAG_FIN);
    sock->timer.retx = TCPLIB_2MSL;
    break;
  case TCP_FIN_WAIT_2:
  case TCP_TIME_WAIT:
    sock->state = TCP_CLOSED;
    // exit TIME_WAIT
    tcplib_extern_closedone(sock);
    break;
  default:
    break;
  }

  /* if we've hit this timer a lot, give up
   *
   * do this by going into
   * TIME_WAIT, which will generate a FIN if anyone sends to us but
   * otherwise just do nothing.
   *
   * we don't do something like try to close it here, since we might
   * have gotten here from doing that.
   */
  if (sock->retxcnt > TCPLIB_GIVEUP) {
    sock->state = TCP_TIME_WAIT;
    sock->timer.retx = TCPLIB_TIMEWAIT_LEN;
   }
}

int tcplib_abort(struct tcplib_sock *sock) {
  switch (sock->state) {
    // nothing to abort
  case TCP_CLOSED:
  case TCP_LISTEN:
    break;
  default:
    tcplib_send_ack(sock, 0, TCP_FLAG_RST);
    memset(&sock->l_ep, 0, sizeof(struct sockaddr_in6));
    memset(&sock->r_ep, 0, sizeof(struct sockaddr_in6));
    sock->state = TCP_CLOSED;
  }
  return 0;
}

int tcplib_close(struct tcplib_sock *sock) {
  int rc = 0;

  switch (sock->state) {
    /* passive close */
  case TCP_CLOSE_WAIT:
    tcplib_send_ack(sock, 1, TCP_FLAG_ACK | TCP_FLAG_FIN);
    sock->timer.retx = 6;
    sock->state = TCP_LAST_ACK;
    break;
    /* active close */
  case TCP_ESTABLISHED:
    // kick off the close
    tcplib_send_ack(sock, 0, TCP_FLAG_ACK | TCP_FLAG_FIN);
    sock->timer.retx = TCPLIB_2MSL;
    sock->state = TCP_FIN_WAIT_1;
    break;
  case TCP_SYN_SENT:
    sock->state = TCP_CLOSED;
    break;
  default:
    /* this is meaningless in other states */
    rc = -1;
  }
  return rc;
}

int tcplib_timer_process() {
  struct tcplib_sock *iter;
  for (iter = conns; iter != NULL; iter = iter->next) {
    if (iter->timer.retx > 0 && (--iter->timer.retx) == 0)
      tcplib_retx_expire(iter);
    if ((iter->flags & TCP_ACKPENDING) >= 2) {
      tcplib_send_ack(iter, 0, TCP_FLAG_ACK);
    }
  }
  return 0;
}
