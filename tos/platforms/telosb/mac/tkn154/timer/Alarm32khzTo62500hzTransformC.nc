// here we introduce an error
generic module Alarm32khzTo62500hzTransformC()
{
  provides interface Alarm<T62500hz,uint32_t> as Alarm;
  uses interface Alarm<T32khz,uint32_t> as AlarmFrom;
}
implementation
{
  async command void Alarm.start(uint32_t dt){ call AlarmFrom.start(dt >> 1);}
  async command void Alarm.stop(){ call AlarmFrom.stop();}
  async event void AlarmFrom.fired(){ signal Alarm.fired();}
  async command bool Alarm.isRunning(){ return call AlarmFrom.isRunning();}
  async command void Alarm.startAt(uint32_t t0, uint32_t dt){ call AlarmFrom.startAt(t0 >> 1, dt >> 1);}
  async command uint32_t Alarm.getNow(){ return call AlarmFrom.getNow() << 1;}
  async command uint32_t Alarm.getAlarm(){ return call AlarmFrom.getAlarm() << 1;}
  default async event void Alarm.fired(){}
}
