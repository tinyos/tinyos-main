interface SystemLowPowerListening
{
  command void setDefaultRemoteWakeupInterval(uint16_t intervalMs);
  command void setDelayAfterReceive(uint16_t intervalMs);

  command uint16_t getDefaultRemoteWakeupInterval();
  command uint16_t getDelayAfterReceive();
}
