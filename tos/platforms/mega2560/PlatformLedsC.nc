#include "hardware.h"

configuration PlatformLedsC {
	provides {
		interface GeneralIO as Led0;
		interface GeneralIO as Led1;
		interface GeneralIO as Led2;
	}
	uses interface Init;
}

implementation {
	// Declare the external components we use
	components HplAtm128GeneralIOC as IO, new NoPinC(), PlatformP;

	Init = PlatformP.LedsInit;

	Led0 = IO.PortB7;
	Led1 = NoPinC;
	Led2 = NoPinC;
}

