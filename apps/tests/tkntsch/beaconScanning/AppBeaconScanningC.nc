/**
 * AppTestTssm is a basic application to implement and test the TimeSlot State 
 * Machine for IEEE 802.15.4e TSCH.
 *
 * @author Moksha Birk <birk@tkn.tu-berlin.de>
 **/

#include "printf.h"

configuration AppBeaconScanningC
{
}
implementation
{
  components MainC, BeaconScanningC as App, LedsC;
  //components PrintfC;
  //components SerialStartC;
  components SerialPrintfC;
  App -> MainC.Boot;
  App.Leds -> LedsC;

  components TknTschC;
  App.TknTschInformationElement -> TknTschC;
  App.TknTschFrames -> TknTschC;
  components Plain154FrameC;

  App.PhyTx -> TknTschC;

  components Plain154MetadataC;
  App.Metadata -> Plain154MetadataC;

  components Plain154PacketC;
  App.PacketPayload -> Plain154PacketC;

  App.TknTschMlmeGet -> TknTschC;
  App.TknTschMlmeSet -> TknTschC;
  App.TknTschMlmeScan -> TknTschC;
  App.Plain154PlmeSet -> TknTschC;
  App.TknTschMlmeBeaconNotify -> TknTschC;
  App.TknTschInit -> TknTschC;
  App.Frame -> Plain154FrameC;

  components HplJn516GeneralIOC as GeneralIOC
        , new Jn516GpioC() as GpioSlotStart
        , new Jn516GpioC() as GpioSlotZero
        , new Jn516GpioC() as GpioPktPrepare
        , new Jn516GpioC() as GpioAlarmIrq
        , new Jn516GpioC() as GpioPhyIrq
      ;

  components new MuxAlarm32khz32C() as Alarm;
  App.Alarm -> Alarm;

  GpioSlotStart -> GeneralIOC.Port0; // expansion header pin 1
  GpioSlotZero -> GeneralIOC.Port1; // expansion header pin 2
  GpioPktPrepare -> GeneralIOC.Port12; // expansion header pin 13
  GpioAlarmIrq -> GeneralIOC.Port13; // expansion header pin 14
  GpioPhyIrq -> GeneralIOC.Port14; // expansion header pin 15

}

