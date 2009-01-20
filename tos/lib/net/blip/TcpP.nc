
#include <table.h>
#include <ip.h>

module TcpP {
  provides interface Tcp[uint8_t client];
  provides interface Init;
  uses {
    interface Boot;

    interface IP;    
    interface Timer<TMilli>;
    interface IPAddress;
  }
} implementation {

  enum {
    N_CLIENTS = uniqueCount("TCP_CLIENT"),
  };

#include <tcplib.h>
  struct tcplib_sock socks[N_CLIENTS];

  int find_client(struct tcplib_sock *conn) {
    int i;
    for (i = 0; i < N_CLIENTS; i++)
      if (&socks[i] == conn) break;

    return i;
  }

  void conn_d(struct tcplib_sock *sock, int error) {
    int cid = find_client(sock);
    if (cid < N_CLIENTS)
      signal Tcp.connectDone[cid](error == 0);
  }

  void rx(struct tcplib_sock *sock, void *data, int len) {
    int cid = find_client(sock);
    if (cid < N_CLIENTS)
      signal Tcp.recv[cid](data, len);
  }

  void cl(struct tcplib_sock *sock) {
    tcplib_close(sock);
  }

  void cd(struct tcplib_sock *sock) {
    int cid = find_client(sock);
    tcplib_init_sock(sock);
    if (cid < N_CLIENTS)
      signal Tcp.closed[cid](0);
  }

  void init_ops(struct tcplib_sock *sock) {
    sock->ops.connect_done = conn_d;
    sock->ops.recvfrom = rx;
    sock->ops.closed = cl;
    sock->ops.close_done = cd;
  }



  void setSrcAddr(struct split_ip_msg *msg) {
    if (msg->hdr.ip6_dst.s6_addr16[0] == htons(0xff02) ||
        msg->hdr.ip6_dst.s6_addr16[0] == htons(0xfe80)) {
//         (msg->hdr.dst_addr[0] == 0xff && (msg->hdr.dst_addr[1] & 0xf) == 0x2) ||
//         (msg->hdr.dst_addr[0] == 0xfe && msg->hdr.dst_addr[2] == 0x80)) {
      call IPAddress.getLLAddr(&msg->hdr.ip6_src);
    } else {
      call IPAddress.getIPAddr(&msg->hdr.ip6_src);
    }
  }

  struct tcplib_sock socks[uniqueCount("TCP_CLIENT")];

  struct tcplib_sock *tcplib_accept(struct tcplib_sock *conn,
                                    struct sockaddr_in6 *from) {
    void *rx_buf = NULL, *tx_buf = NULL;
    int rx_buf_len, tx_buf_len;
    int cid = find_client(conn);

    printfUART("tcplib_accept: cid: %i\n", cid);

    if (cid == N_CLIENTS) return NULL;
    if (signal Tcp.accept[cid](from, &rx_buf, &rx_buf_len,
                               &tx_buf, &tx_buf_len)) {
      if (rx_buf == NULL || tx_buf == NULL) return NULL;
      conn->rx_buf = rx_buf;
      conn->rx_buf_len = rx_buf_len;
      conn->tx_buf = tx_buf;
      conn->tx_buf_len = tx_buf_len;
      init_ops(conn);
      return conn;
    }
    return NULL;
  }

  void tcplib_send_out(struct split_ip_msg *msg, struct tcp_hdr *tcph) {
    printfUART("tcp output\n");
    setSrcAddr(msg);
    tcph->chksum = htons(msg_cksum(msg, IANA_TCP));
    call IP.send(msg);
  }

#include "circ.c"
#include "tcplib.c"

  command error_t Init.init() {
    int i;
    for (i = 0; i < uniqueCount("TCP_CLIENT"); i++) {
      tcplib_init_sock(&socks[i]);
    }
    return SUCCESS;
  }

  event void Boot.booted() {
    call Timer.startPeriodic(512);
  }

  event void Timer.fired() {
    tcplib_timer_process();
  }

  event void IP.recv(struct ip6_hdr *iph, 
                     void *payload, 
                     struct ip_metadata *meta) {
    
    printfUART("tcp packet received\n");
    tcplib_process(iph, payload);
  }


  command error_t Tcp.bind[uint8_t client](uint16_t port) {
    struct sockaddr_in6 addr;
    ip_memclr(addr.sin6_addr.s6_addr, 16);
    addr.sin6_port = htons(port);
    tcplib_bind(&socks[client], &addr);
    return SUCCESS;
  }

  command error_t Tcp.connect[uint8_t client](struct sockaddr_in6 *dest,
                                              void *rx_buf, int rx_buf_len,
                                              void *tx_buf, int tx_buf_len) {
    socks[client].rx_buf;
    socks[client].rx_buf_len = rx_buf_len;
    socks[client].tx_buf = tx_buf;
    socks[client].tx_buf_len = tx_buf_len;
    tcplib_connect(&socks[client], dest);
  }

  command error_t Tcp.send[uint8_t client](void *payload, uint16_t len) {
    tcplib_send(&socks[client], payload, len);
    return SUCCESS;
  }
  
  command error_t Tcp.close[uint8_t client]() {
    if (!tcplib_close(&socks[client]))
      return SUCCESS;
    return FAIL;
  }

  default event bool Tcp.accept[uint8_t cid](struct sockaddr_in6 *from, 
                                             void **rx_buf, int *rx_buf_len,
                                             void **tx_buf, int *tx_buf_len) {
    return FALSE;
  }

 default event void Tcp.connectDone[uint8_t cid](error_t e) {}
 default event void Tcp.recv[uint8_t cid](void *payload, uint16_t len) {  }
 default event void Tcp.closed[uint8_t cid](error_t e) { }
 



  
}
