

interface Tcp { 

  /*
   * Bind the socket to a local address
   * 
   */
  command error_t bind(uint16_t port);

  /*
   * Accept an incomming connection.
   *
   * the app should return FALSE to reject the connection attempt
   */
  event bool accept(struct sockaddr_in6 *from, 
                    void **tx_buf, int *tx_buf_len);

  /*
   * Split-phase connect: connect to a remote endpoint.
   *
   * The socket should not be used until connectDone is signaled.
   */
  command error_t connect(struct sockaddr_in6 *dest,
                          void *tx_buf, int tx_buf_len);
  event void connectDone(error_t e);

  /*
   * Send and receive data on a socket.  The socket must be CONNECTed
   * for these to succeed.
   */
  command error_t send(void *payload, uint16_t len);

  event void recv(void *payload, uint16_t len);

  /*
   * terminate a connection.
   */
  command error_t close();
  command error_t abort();

  /*
   * notify the app that the socket connection has been closed or
   * reset by the other end, or else a timeout has occured and the
   * local side has given up.
   */
  event void closed(error_t e);

  /* 
   * returns TRUE if all previously sent data has been ACKed
   */
  event void acked();


}
