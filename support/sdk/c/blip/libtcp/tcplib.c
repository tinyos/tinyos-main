
/* A nonblocking library-based implementation of TCP
 *
 * There are some things like timers which need to be handled
 * externally with callbacks.
 *
 */

#include <stdio.h>
#include <string.h>
#include "ip_malloc.h"
#include "in_cksum.h"
#include "6lowpan.h"
#include "ip.h"
#include "tcplib.h"
#include "circ.h"

static struct tcplib_sock *conns = NULL;

#define ONE_SEGMENT(X)  ((X)->mss)

uint16_t alloc_local_port() {
  return 32012;
}

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

static struct tcplib_sock *conn_lookup(struct ip6_hdr *iph, 
                                       struct tcp_hdr *tcph) {
  struct tcplib_sock *iter;
  printfUART("looking up conns...\n");
  for (iter = conns; iter != NULL; iter = iter->next) {
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

struct tcp_hdr *find_tcp_hdr(struct split_ip_msg *msg) {
  if (msg->hdr.nxt_hdr == IANA_TCP) {
    return (struct tcp_hdr *)((msg->headers == NULL) ? msg->data :
                              msg->headers->hdr.data);
  }
}

static struct split_ip_msg *get_ipmsg(int plen) {
  struct split_ip_msg *msg = 
    (struct split_ip_msg *)ip_malloc(sizeof(struct split_ip_msg) + sizeof(struct tcp_hdr) + plen);
  if (msg == NULL) return NULL;
  memset(msg, 0, sizeof(struct split_ip_msg) + sizeof(struct tcp_hdr));
  msg->hdr.nxt_hdr = IANA_TCP;
  msg->hdr.plen = htons(sizeof(struct tcp_hdr) + plen);

  msg->headers = NULL;
  msg->data = (void *)(msg + 1);
  msg->data_len = sizeof(struct tcp_hdr) + plen;

  return msg;
}

static void __tcplib_send(struct tcplib_sock *sock,
                          struct split_ip_msg *msg) {
  struct tcp_hdr *tcph = find_tcp_hdr(msg);
  memcpy(&msg->hdr.ip6_dst, &sock->r_ep.sin6_addr, 16);

  sock->flags &= ~TCP_ACKPENDING;

  // sock->ackno = ntohl(tcph->ackno);

  tcph->srcport = sock->l_ep.sin6_port;
  tcph->dstport = sock->r_ep.sin6_port;
  tcph->offset = sizeof(struct tcp_hdr) * 4;
  tcph->window = htons(circ_get_window(sock->rx_buf));
  tcph->chksum = 0;
  tcph->urgent = 0;

  tcplib_send_out(msg, tcph);
}

static void tcplib_send_ack(struct tcplib_sock *sock, int fin_seqno, uint8_t flags) {
  struct split_ip_msg *msg = get_ipmsg(0);
      
  if (msg != NULL) {
    struct tcp_hdr *tcp_rep = (struct tcp_hdr *)(msg + 1);
    tcp_rep->flags = flags;

    tcp_rep->seqno = htonl(sock->seqno);
    tcp_rep->ackno = htonl(circ_get_seqno(sock->rx_buf) + 
                           (fin_seqno ? 1 : 0));
    __tcplib_send(sock, msg);
    ip_free(msg);
  }
}

static void tcplib_send_rst(struct ip6_hdr *iph, struct tcp_hdr *tcph) {
  struct split_ip_msg *msg = get_ipmsg(0);
      
  if (msg != NULL) {
    struct tcp_hdr *tcp_rep = (struct tcp_hdr *)(msg + 1);

    memcpy(&msg->hdr.ip6_dst, &iph->ip6_src, 16);

    tcp_rep->flags = TCP_FLAG_RST;

    tcp_rep->ackno = tcph->seqno + 1;
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
  seg_size = min(seg_size, sock->cwnd);
  while (seg_size > 0 && sock->seqno > sseqno) {
    // printf("sending seg_size: %i\n", seg_size);
    struct split_ip_msg *msg = get_ipmsg(seg_size);
    struct tcp_hdr *tcph;
    uint8_t *data;
    if (msg == NULL) return -1;
    tcph = (struct tcp_hdr *)(msg + 1);
    data = (uint8_t *)(tcph + 1);

    tcph->flags = TCP_FLAG_ACK;
    tcph->seqno = htonl(sseqno);
    tcph->ackno = htonl(circ_get_seqno(sock->rx_buf));

    circ_buf_read(sock->tx_buf, sseqno, data, seg_size);
    __tcplib_send(sock, msg);
    ip_free(msg);

    sseqno += seg_size;
    seg_size = min(sock->seqno - sseqno, sock->mss);
  }
  return 0;
}

int tcplib_init_sock(struct tcplib_sock *sock) {
  memset(sock, 0, sizeof(struct tcplib_sock) - sizeof(struct tcplib_sock *));
  sock->mss = 100;
  sock->cwnd = ONE_SEGMENT(sock);
  sock->ssthresh = 0xffff;
  conn_add_once(sock);
  return 0;
}

/* called when a new segment arrives. */
/* deliver as much data to the app as possible, and update the ack
 * number of the socket to reflect how much was delivered 
 */
static void add_data(struct tcplib_sock *sock, struct tcp_hdr *tcph, int len) {
  char *ptr;
  int payload_len;
  ptr = ((uint8_t *)tcph) + (tcph->offset / 4);
  payload_len = len - (tcph->offset / 4);
  // TODO : SDH : optimize out the extra copy for in-sequence data
  circ_buf_write(sock->rx_buf, ntohl(tcph->seqno),
                 ptr, payload_len);
  // now try to deliver any data ahead of the ack pointer that's in
  // the buffer

  /* if we wrapped around the buffer, we'll actually recieve twice.  */
  while ((payload_len = circ_buf_read_head(sock->rx_buf, &ptr)) > 0) {
    sock->ops.recvfrom(sock, ptr, payload_len);
  }
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
  int payload_len;
  int len = ntohs(iph->plen) + sizeof(struct ip6_hdr);;
  tcph = (struct tcp_hdr *)payload;

  // printf("tcplib_process\n");

  /* malformed ip packet?  could happen I supppose... */
/*   if (len < sizeof(struct ip6_hdr) || */
/*       len != ntohs(iph->plen) + sizeof(struct ip6_hdr)) { */
/*     fprintf(stderr, "tcplib_process: warn: length mismatch\n"); */
/*     return -1; */
/*   } */

  /* if there's no local */
  this_conn = conn_lookup(iph, tcph);
  if (this_conn != NULL) {
    if (tcph->flags & TCP_FLAG_RST) {
      /* Really hose this connection if we get a RST packet.
       * still TODO: RST generation for unbound ports */
      printf("connection reset by peer\n");
          
      if (this_conn->ops.closed)
        this_conn->ops.close_done(this_conn);
      tcplib_init_sock(this_conn);
      return 0;
    }
    // always get window updates from new segments
    // TODO : this should be after we detect out-of-sequence ACK
    // numbers!
    this_conn->r_wind = ntohs(tcph->window);

    switch (this_conn->state) {
    case TCP_LAST_ACK:
      if (tcph->flags & TCP_FLAG_ACK && 
          ntohl(tcph->ackno) == this_conn->seqno + 1) {
        // printf("closing connection\n");
        this_conn->state = TCP_CLOSED;
        this_conn->ops.close_done(this_conn);
        break;
      }

    case TCP_SYN_SENT:
      if (tcph->flags & (TCP_FLAG_SYN | TCP_FLAG_ACK)) {
        // got a syn-ack
        // send the ACK 
        this_conn->state = TCP_ESTABLISHED;
        circ_set_seqno(this_conn->rx_buf, ntohl(tcph->seqno) + 1);
        // skip the LISTEN processing
        // this will also generate an ACK
        goto ESTABLISHED;
      } else if (this_conn->flags & TCP_FLAG_SYN) {
      // otherwise the state machine says we're in a simultaneous open, so continue doen
        this_conn->state = TCP_SYN_RCVD;
      } else {
        printf("sending RST on bad data in state SYN_SENT\n");
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

          circ_buf_init(new_sock->rx_buf, new_sock->rx_buf_len, 
                        ntohl(tcph->seqno) + 1, 1);
          circ_buf_init(new_sock->tx_buf, new_sock->tx_buf_len,
                        0xcafebabe + 1, 0);
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
        printf("sending RST on out-of-sequence data\n");
        tcplib_send_rst(iph, tcph);
        break;
      }
      /* this is SYN_RECVd */
      if (tcph->flags & TCP_FLAG_ACK) {
        // printf("recv ack, in state TCP_SYN_RCVD\n");
        this_conn->state = TCP_ESTABLISHED;
      } 
      /* fall through to handle any data. */
      
    case TCP_CLOSE_WAIT:
    case TCP_ESTABLISHED:
    ESTABLISHED:
      // ptr = ((uint8_t *)(iph + 1)) + (tcph->offset / 4);
      payload_len = len - sizeof(struct ip6_hdr) - (tcph->offset / 4);
      // printf("recv data len: %i\n", payload_len);

      /* ack any data in this packet */
      if (this_conn->state == TCP_ESTABLISHED) {
        if (payload_len > 0)
          this_conn->flags ++;


        // receive side sequence check and add data
        // printf("seqno: %i ackno: %i\n", ntohl(tcph->seqno), ntohl(tcph->ackno));


        // send side recieve sequence check and congestion window updates.
        if (ntohl(tcph->ackno) > circ_get_seqno(this_conn->tx_buf)) {
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
          circ_shorten_head(this_conn->tx_buf, ntohl(tcph->ackno));
          // printf("ack_count: %i\n", GET_ACK_COUNT(this_conn->flags));
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
        } else if (ntohl(tcph->seqno) != circ_get_seqno(this_conn->rx_buf)) {
          printf("==> received out-of-sequence data!\n");
          tcplib_send_ack(this_conn, 0, TCP_FLAG_ACK);
        }
        add_data(this_conn, tcph, len - sizeof(struct ip6_hdr));


        // printf("tx seqno: %i ackno: %i\n", circ_get_seqno(this_conn->tx_buf),
        // ntohl(tcph->ackno));


        // reset the retransmission timer
        if (this_conn->timer.retx == 0)
          this_conn->timer.retx = 6;
      }
      if ((payload_len > 0 && (this_conn->flags & TCP_ACKPENDING) >= 2) 
          || tcph->flags & TCP_FLAG_FIN) {
        ///|| ntohl(tcph->seqno) != circ_get_seqno(this_conn->rx_buf)) {
        tcplib_send_ack(this_conn, (payload_len == 0 && tcph->flags & TCP_FLAG_FIN), TCP_FLAG_ACK);
        /* only close the connection if we've gotten all the data */
        if (this_conn->state == TCP_ESTABLISHED 
            && tcph->flags & TCP_FLAG_FIN
            && ntohl(tcph->seqno)  == circ_get_seqno(this_conn->rx_buf)) {
          this_conn->state = TCP_CLOSE_WAIT;
          this_conn->ops.closed(this_conn);
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
    /* TODO : SDH : send ICMP error */
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
}

/* connect the socket to a remote endpoint */
int tcplib_connect(struct tcplib_sock *sock,
                   struct sockaddr_in6 *serv_addr) {
  if (sock->rx_buf == NULL || sock->tx_buf == NULL)
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
  circ_buf_init(sock->rx_buf, sock->rx_buf_len, 
                0, 1);
  circ_buf_init(sock->tx_buf, sock->tx_buf_len,
                0xcafebabe + 1, 0);

  sock->seqno = 0xcafebabe;
  memcpy(&sock->r_ep, serv_addr, sizeof(struct sockaddr_in6));
  tcplib_send_ack(sock, 0, TCP_FLAG_SYN);
  sock->state = TCP_SYN_SENT;
  sock->seqno++;
  return 0;
}


int tcplib_send(struct tcplib_sock *sock, void *data, int len) {
  /* have enough tx buffer left? */
  if (sock->state != TCP_ESTABLISHED)
    return -1;
  if (sock->seqno - circ_get_seqno(sock->tx_buf) + len > circ_get_window(sock->tx_buf))
    return -1;

  circ_buf_write(sock->tx_buf, sock->seqno, data, len);

  sock->seqno += len;
  // printf("tcplib_output from send\n");
  tcplib_output(sock, sock->seqno - len);
  
  // 3 seconds
  if (sock->timer.retx == 0)
    sock->timer.retx = 6;

  return 0;
}

void tcplib_retx_expire(struct tcplib_sock *sock) {
  // printf("retransmission timer expired!\n");
  if (sock->state == TCP_ESTABLISHED &&
      circ_get_seqno(sock->tx_buf) != sock->seqno) {
    printf("retransmitting [%u, %u]\n", circ_get_seqno(sock->tx_buf),
           sock->seqno);
    reset_ssthresh(sock);
    // restart slow start
    sock->cwnd = ONE_SEGMENT(sock);
    // printf("tcplib_output from timer\n");
    tcplib_output(sock, circ_get_seqno(sock->tx_buf));
    sock->timer.retx = 6;
  } else if (sock->state == TCP_LAST_ACK) {
    //     printf("resending FIN\n");
    tcplib_send_ack(sock, 1, TCP_FLAG_ACK | TCP_FLAG_FIN);
    sock->timer.retx = 6;
  }
}

int tcplib_close(struct tcplib_sock *sock) {
  int rc = -1;

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
    if (iter->flags & TCP_ACKPENDING) {
      // printf("sending delayed ACK\n");
      tcplib_send_ack(iter, 0, TCP_FLAG_ACK);
    }
  }
  return 0;
}
