#include "Timer62500hz.h"
configuration Alarm32khz32VirtualizedP
{
  provides interface Alarm<T32khz,uint32_t> as Alarm[ uint8_t num ];
}
implementation
{
  components new Alarm32khz32C(), MainC;
  components new VirtualizeAlarmC(T32khz, uint32_t, uniqueCount(UQ_ALARM_32KHZ32));

  Alarm = VirtualizeAlarmC;
  MainC -> VirtualizeAlarmC.Init;
  VirtualizeAlarmC.AlarmFrom -> Alarm32khz32C;
}
