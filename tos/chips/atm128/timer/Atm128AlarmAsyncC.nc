generic configuration Atm128AlarmAsyncC(typedef precision, int divider) {
  provides {
    interface Init @atleastonce();
    interface Alarm<precision, uint32_t>;
    interface Counter<precision, uint32_t>;
  }
}
implementation
{
  components new Atm128AlarmAsyncP(precision, divider),
    HplAtm128Timer0AsyncC;

  Init = Atm128AlarmAsyncP;
  Init = HplAtm128Timer0AsyncC;
  Alarm = Atm128AlarmAsyncP;
  Counter = Atm128AlarmAsyncP;

  Atm128AlarmAsyncP.Timer -> HplAtm128Timer0AsyncC;
  Atm128AlarmAsyncP.TimerCtrl -> HplAtm128Timer0AsyncC;
  Atm128AlarmAsyncP.Compare -> HplAtm128Timer0AsyncC;
}
