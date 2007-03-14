
#include "XMTS300.h"
#include "mts300.h"

configuration TestMts300C
{
}
implementation
{
  components MainC, TestMts300P, LedsC, NoLedsC;
  components new TimerMilliC() as MTS300Timer;

  components ActiveMessageC as Radio;
  components SerialActiveMessageC as Serial;

// sensorboard devices
  components new SensorMts300C();

  TestMts300P -> MainC.Boot;

  TestMts300P.MTS300Timer -> MTS300Timer;
  TestMts300P.Leds -> LedsC;

  // communication
  TestMts300P.RadioControl -> Radio;
  TestMts300P.RadioSend -> Radio.AMSend[AM_MTS300MSG];
  TestMts300P.RadioPacket -> Radio;

  TestMts300P.UartControl -> Serial;
  TestMts300P.UartSend -> Serial.AMSend[AM_MTS300MSG];
  TestMts300P.UartPacket -> Serial;

  // sensor components
  TestMts300P.Vref -> SensorMts300C.Vref;
  TestMts300P.Sounder -> SensorMts300C.Sounder;
  
  TestMts300P.Light -> SensorMts300C.Light;
  TestMts300P.Temp -> SensorMts300C.Temp;
  TestMts300P.Microphone -> SensorMts300C.Microphone;
  TestMts300P.AccelX -> SensorMts300C.AccelX;
  TestMts300P.AccelY -> SensorMts300C.AccelY;
  TestMts300P.MagX -> SensorMts300C.MagX;
  TestMts300P.MagY -> SensorMts300C.MagY;
}
