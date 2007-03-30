#include "antitheft.h"

configuration AntiTheftAppC { }
implementation
{
  components AntiTheftC, new TimerMilliC() as MyTimer, MainC, LedsC,
    new PhotoC(), new AccelXStreamC(), SounderC,
    ActiveMessageC, CollectionC, CC1000CsmaRadioC,
    new DisseminatorC(settings_t, DIS_SETTINGS),
    new CollectionSenderC(COL_ALERTS) as AlertSender,
    new AMSenderC(AM_THEFT) as SendTheft, 
    new AMReceiverC(AM_THEFT) as ReceiveTheft;

  AntiTheftC.Boot -> MainC.Boot;
  AntiTheftC.Check -> MyTimer;
  AntiTheftC.Read -> PhotoC;
  AntiTheftC.ReadStream -> AccelXStreamC;
  AntiTheftC.Leds -> LedsC;
  AntiTheftC.Mts300Sounder -> SounderC;
  AntiTheftC.SettingsValue -> DisseminatorC;
  AntiTheftC.AlertRoot -> AlertSender;
  AntiTheftC.CollectionControl -> CollectionC;
  AntiTheftC.RadioControl -> ActiveMessageC;
  AntiTheftC.LowPowerListening -> CC1000CsmaRadioC;
  AntiTheftC.TheftSend -> SendTheft;
  AntiTheftC.TheftReceive -> ReceiveTheft;
}
