interface MHControl {

  event void msgReceived(message_t * msg);

  event void sendFailed(message_t * msg, uint8_t why);

}
