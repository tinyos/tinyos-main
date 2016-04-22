#include "hardware.h"

module PlatformP @safe() {
	provides interface Init;
    uses {
        interface GeneralIO as OrangeLedPin;
        interface Init as LedsInit;
    }
}

implementation {
	command error_t Init.init() {
        return call LedsInit.init();
	}

	default command error_t LedsInit.init() {
        call OrangeLedPin.makeOutput(); 
        call OrangeLedPin.clr();
        return SUCCESS; 
	}
}

