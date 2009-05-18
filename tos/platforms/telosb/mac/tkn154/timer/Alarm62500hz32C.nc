#include "Timer62500hz.h"
generic configuration Alarm62500hz32C()
{
  provides interface Alarm<T62500hz,uint32_t> as Alarm;
}
implementation
{
  components new Alarm32khz32C(), MainC;
  components new Alarm62500hz32P();

  Alarm = Alarm62500hz32P;

#if defined(PLATFORM_TELOSB)
  MainC -> Alarm32khz32C.Init;
#endif
  Alarm62500hz32P.AlarmFrom -> Alarm32khz32C;
}
