#include "BatterySwitch.h"
module BatterySwitchP{
	provides interface Read<uint8_t>;
	uses interface GeneralIO;
	uses interface Timer<TMilli>;
}
implementation{
	#if defined(UCMINI_REV) && UCMINI_REV<110
	#error Measuring voltage is only supported on UCMini v1.1 and newer
	#endif
	command error_t Read.read(){
		call GeneralIO.clr();
		call GeneralIO.makeOutput();//discharge the cpacitance of the wire
		call Timer.startOneShot(1);
		return SUCCESS;
	}
	
	event void Timer.fired(){
		if( call GeneralIO.isOutput() ){
			call GeneralIO.makeInput();//let the wire capacitance to recharge
			call Timer.startOneShot(1);
		} else {
			if( call GeneralIO.get() )
				signal Read.readDone(SUCCESS, BATTERY_SWITCH_NOT_RECHARGABLE);
			else
				signal Read.readDone(SUCCESS, BATTERY_SWITCH_RECHARGABLE);
		}
	}
}