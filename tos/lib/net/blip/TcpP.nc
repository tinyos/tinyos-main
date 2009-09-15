
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

  void tcplib_extern_connectdone(struct tcplib_sock *sock, int error) {
    int cid = find_client(sock);
    if (cid < N_CLIENTS)
      signal Tcp.connectDone[cid](error == 0);
  }

  void tcplib_extern_recv(struct tcplib_sock *sock, void *data, int len) {
    int cid = find_client(sock);
    if (cid < N_CLIENTS)
      signal Tcp.recv[cid](data, len);
  }

  void tcplib_extern_closed(struct tcplib_sock *sock) {
    tcplib_close(sock);
  }

  void tcplib_extern_closedone(struct tcplib_sock *sock) {
    int cid = find_client(sock);
    tcplib_init_sock(sock);
    if (cid < N_CLIENTS)
      signal Tcp.closed[cid](0);
  }

  void tcplib_extern_acked(struct tcplib_sock *sock) {
    int cid = find_client(sock);
    if (cid < N_CLIENTS)
      signal Tcp.acked[cid]();
  }
#include "circ.c"
#include "tcplib.c"

  struct tcplib_sock socks[uniqueCount("TCP_CLIENT")];

  struct tcplib_sock *tcplib_accept(struct tcplib_sock *conn,
                                    struct sockaddr_in6 *from) {
    int cid = find_client(conn);

    printfUART("tcplib_accept: cid: %i\n", cid);

    if (cid == N_CLIENTS) return NULL;
    if (signal Tcp.accept[cid](from, &conn->tx_buf, &conn->tx_buf_len)) {
      if (conn->tx_buf == NULL) return NULL;
      return conn;
    }
    return NULL;
  }

  void tcplib_send_out(struct split_ip_msg *msg, struct tcp_hdr *tcph) {
    printfUART("tcp output\n");
    call IPAddress.setSource(&msg->hdr);
    tcph->chksum = htons(msg_cksum(msg, IANA_TCP));
    call IP.send(msg);
  }

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
                                              void *tx_buf, int tx_buf_len) {
    socks[client].tx_buf = tx_buf;
    socks[client].tx_buf_len = tx_buf_len;
    tcplib_connect(&socks[client], dest);
  }

  command error_t Tcp.send[uint8_t client](void *payload, uint16_t len) {
    if (tcplib_send(&socks[client], payload, len) < 0) return FAIL;
    return SUCCESS;
  }
  
  command error_t Tcp.close[uint8_t client]() {
    if (!tcplib_close(&socks[client]))
      return SUCCESS;
    return FAIL;
  }

  command error_t Tcp.abort[uint8_t client]() {
    if (tcplib_abort(&socks[client]) < 0) return FAIL;
    return SUCCESS;
  }

  default event bool Tcp.accept[uint8_t cid](struct sockaddr_in6 *from, 
                                             void **tx_buf, int *tx_buf_len) {
    return FALSE;
  }

 default event void Tcp.connectDone[uint8_t cid](error_t e) {}
 default event void Tcp.recv[uint8_t cid](void *payload, uint16_t len) {  }
 default event void Tcp.closed[uint8_t cid](error_t e) { }
 default event void Tcp.acked[uint8_t cid]() { }
 
}
