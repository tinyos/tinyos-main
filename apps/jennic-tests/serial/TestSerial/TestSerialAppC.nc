#include "TestSerial.h"

configuration TestSerialAppC {}
implementation {
	components TestSerialC as App, LedsC, MainC;
	components SerialActiveMessageC as AM;
	components new TimerMilliC();

	App.Boot -> MainC.Boot;
	App.Control -> AM;
	App.AMSend -> AM.AMSend[AM_TEST_SERIAL_MSG];
	App.Leds -> LedsC;
	App.MilliTimer -> TimerMilliC;
	App.Packet -> AM;
}


