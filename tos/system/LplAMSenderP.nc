generic module LplAMSenderP()
{
  provides interface AMSend;
  uses {
    interface AMSend as SubAMSend;
    interface LowPowerListening as Lpl;
    interface SystemLowPowerListening;
  }
}

implementation
{
  command error_t AMSend.send(am_addr_t addr, message_t* msg, uint8_t len)
  {
    call Lpl.setRemoteWakeupInterval(msg, call SystemLowPowerListening.getDefaultRemoteWakeupInterval());
    return call SubAMSend.send(addr, msg, len);
  }

  event void SubAMSend.sendDone(message_t* msg, error_t error) { signal AMSend.sendDone(msg, error); }
  command error_t AMSend.cancel(message_t* msg) { return call SubAMSend.cancel(msg); }
  command uint8_t AMSend.maxPayloadLength() { return call SubAMSend.maxPayloadLength(); }
  command void* AMSend.getPayload(message_t* msg, uint8_t len) { return call SubAMSend.getPayload(msg, len); }
}
