#include "Timer62500hz.h"
configuration Alarm32khz32VirtualizedP
{
  provides interface Alarm<T32khz,uint32_t> as Alarm[ uint8_t num ];
}
implementation
{
  components new Alarm32khz32C(), MainC;
  components new VirtualizeAlarmC(T32khz, uint32_t, uniqueCount(UQ_ALARM_32KHZ32));

#ifndef PLATFORM_MICAZ
  // On msp430-based (e.g. TelosB) platforms Alarm32khz32C provides
  // the Init interface, on the atmega-based (e.g. micaz) platforms
  // it does not. If you use this file as a template for a new 
  // platform you might need to adapt this ... 
  MainC -> Alarm32khz32C.Init;
#endif
  Alarm = VirtualizeAlarmC;
  MainC -> VirtualizeAlarmC.Init;
  VirtualizeAlarmC.AlarmFrom -> Alarm32khz32C;
}
