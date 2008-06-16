#include "Timer62500hz.h"
configuration LocalTime62500hzC
{
  provides interface LocalTime<T62500hz>;
}
implementation
{
  // should be done properly one day (not wasting an alarm slot)
  components new Alarm62500hz32VirtualizedC(), LocalTime62500hzP;
  LocalTime = LocalTime62500hzP;
  LocalTime62500hzP.Alarm -> Alarm62500hz32VirtualizedC.Alarm;
}

