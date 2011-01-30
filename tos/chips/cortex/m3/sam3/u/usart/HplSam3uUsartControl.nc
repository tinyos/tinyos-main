interface HplSam3uUsartControl{
  command void init();
  command void configure(uint32_t mode, uint32_t baudrate);
  command void enableTx();
  command void disableTx();
  command void enableTxInterrupt();
  command void enableRx();
  command void enableRxInterrupt();
  command void disableRx();
  command error_t write(uint8_t sync, uint16_t data, uint32_t timeout);
  command error_t read(uint16_t *data, uint32_t timeout);
  command bool isDataAvailable();
  command void setIrdaFilter(uint32_t filter);
  command error_t putChar(uint8_t sync, uint16_t data);
  command bool isRxReady();
  command error_t getChar(uint16_t *data);
  event void writeDone();
  event void readDone(uint8_t data);
}