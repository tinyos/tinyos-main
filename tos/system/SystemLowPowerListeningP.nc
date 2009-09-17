#include "Lpl.h"

module SystemLowPowerListeningP
{
  provides interface SystemLowPowerListening;
}

implementation
{
  uint16_t remoteWakeup = LPL_DEF_REMOTE_WAKEUP;
  uint16_t delayAfterReceive = DELAY_AFTER_RECEIVE;

  command void SystemLowPowerListening.setDefaultRemoteWakeupInterval(uint16_t intervalMs) { remoteWakeup = intervalMs; }
  command void SystemLowPowerListening.setDelayAfterReceive(uint16_t intervalMs) { delayAfterReceive = intervalMs; }

  command uint16_t SystemLowPowerListening.getDefaultRemoteWakeupInterval() { return remoteWakeup; }
  command uint16_t SystemLowPowerListening.getDelayAfterReceive() { return delayAfterReceive; }
}
