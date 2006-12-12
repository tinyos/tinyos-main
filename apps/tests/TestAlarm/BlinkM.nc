// $Id: BlinkM.nc,v 1.4 2006-12-12 18:22:49 vlahan Exp $

#include "Timer.h"

module BlinkM
{
  uses interface Boot;
  uses interface Leds;
  uses interface Alarm<TMilli,uint32_t> as Alarm;
}
implementation
{
  enum { DELAY_MILLI = 512 };

  event void Boot.booted()
  {
    atomic
    {
      call Leds.led1On();
      call Alarm.start( DELAY_MILLI );
    }
  }

  async event void Alarm.fired()
  {
    atomic
    {
      // this usage produces a periodic alarm with no frequency skew
      call Alarm.startAt( call Alarm.getAlarm(), DELAY_MILLI );
      call Leds.led0Toggle();
    }
  }
}

