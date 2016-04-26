#include <avr/io.h>
#include <util/delay.h>

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
		uint16_t i;
		for (i = 0; i < 10; ++i) {
			_delay_ms(200);
		}
	    return SUCCESS;
	}

	default command error_t LedsInit.init() {
        return SUCCESS; 
	}
}

