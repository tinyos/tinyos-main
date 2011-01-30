interface Sam3uUsart{
  command void start();
  event void startDone(error_t err);
  command error_t stop();
  event void stopDone(error_t err);

  command void send(uint8_t data);
  command void sendStream(void* msg, uint8_t length);
  command void listen(void* msg, uint8_t length);

  event void sendDone(error_t error);
  event void receive(error_t error, uint8_t data);
}