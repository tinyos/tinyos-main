interface PseudoSerial {
  /** Feed data into the UartStream interface.
   *
   * @param data the octets to be produced by UartStream
   * @param len the number of octets in the production
   */
  command error_t feedUartStream (const uint8_t* data,
                                  unsigned int len);

  command error_t feedUartByte (uint8_t byte);
  
  command unsigned int consumeUartStream (uint8_t* data,
                                          unsigned int max_len);
}
