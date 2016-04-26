#include "hardware.h"

module PlatformP @safe() {
	provides interface Init;
    uses {
        interface GeneralIO as OrangeLedPin;
        interface Init as LedsInit;
        interface Init as McuInit;
    }
}

implementation {
	command error_t Init.init() {
	    error_t ok;
	    
        ok = call McuInit.init();
        ok = ecombine(ok, call LedsInit.init());
        return ok;
	}

	default command error_t McuInit.init() {
	    return SUCCESS;
	}

	default command error_t LedsInit.init() {
        return SUCCESS; 
	}
}

