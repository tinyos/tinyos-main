#include "../AntiTheft/antitheft.h"

configuration AntiTheftRootAppC { }
implementation
{
  components AntiTheftRootC, MainC, LedsC, CollectionC,
    new DisseminatorC(settings_t, DIS_SETTINGS),
    ActiveMessageC, SerialActiveMessageC, CC1000CsmaRadioC,
    new SerialAMReceiverC(AM_SETTINGS) as SettingsReceiver, 
    new SerialAMSenderC(AM_ALERTS) as AlertsForwarder;

  AntiTheftRootC.Boot -> MainC;
  AntiTheftRootC.SerialControl -> SerialActiveMessageC;
  AntiTheftRootC.RadioControl -> ActiveMessageC;
  AntiTheftRootC.LowPowerListening -> CC1000CsmaRadioC;
  AntiTheftRootC.CollectionControl -> CollectionC;

  AntiTheftRootC.SettingsReceive -> SettingsReceiver;
  AntiTheftRootC.SettingsUpdate -> DisseminatorC;

  AntiTheftRootC.RootControl -> CollectionC;
  AntiTheftRootC.AlertsReceive -> CollectionC.Receive[COL_ALERTS];
  AntiTheftRootC.AlertsForward -> AlertsForwarder;

  AntiTheftRootC.Leds -> LedsC;
}
