module PseudoSerialP {
  provides {
    interface StdControl;
    interface HdlcUart;
    interface PseudoSerial;
  }
} implementation {

#ifndef PSEUDOSERIAL_MAX_TX_BUFFER
#define PSEUDOSERIAL_MAX_TX_BUFFER 512
#endif /* PSEUDOSERIAL_MAX_TX_BUFFER */

  bool inhibit_rx;
  uint8_t* rx_buffer;
  uint16_t rx_buffer_idx;
  uint16_t rx_buffer_length;

  command error_t StdControl.start ()
  {
    inhibit_rx = FALSE;
    return SUCCESS;
  }
  command error_t StdControl.stop ()
  {
    inhibit_rx = TRUE;
    return SUCCESS;
  }

  command error_t HdlcUart.send (uint8_t* buf, uint16_t len) { return FAIL; }
  // async event void HdlcUart.sendDone (error_t err) { }

  // async event void UartStream.receiveDone (uint8_t* buf, uint16_t len, error_t err) { }
  
  command error_t PseudoSerial.feedUartByte (uint8_t byte)
  {
    signal HdlcUart.receivedByte(byte);
    return SUCCESS;
  }


  command error_t PseudoSerial.feedUartStream (const uint8_t* data,
                                               unsigned int len)
  {
    const uint8_t* dp = data; 
    const uint8_t* dpe = dp + len;
    while (dp < dpe) {
      call PseudoSerial.feedUartByte(*dp++);
    }
    return SUCCESS;
  }

  command unsigned int PseudoSerial.consumeUartStream (uint8_t* data,
                                                       unsigned int max_len)
  {
    return FAIL;
  }
  
}
