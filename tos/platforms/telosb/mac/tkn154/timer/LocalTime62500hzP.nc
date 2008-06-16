#include "Timer62500hz.h"
module LocalTime62500hzP
{
  provides interface LocalTime<T62500hz>;
  uses interface Alarm<T62500hz,uint32_t>;
}
implementation
{
  async command uint32_t LocalTime.get()
  {
    return call Alarm.getNow();
  }
  async event void Alarm.fired(){}
}

