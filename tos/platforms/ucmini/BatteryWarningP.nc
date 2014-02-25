#include "BatterySwitch.h"
#ifndef MAXIMUM_NOT_RECHARGABLE_VOLTAGE
#define MAXIMUM_NOT_RECHARGABLE_VOLTAGE 3200
#endif
#ifndef MINIMUM_RECHARGABLE_VOLTAGE
#define MINIMUM_RECHARGABLE_VOLTAGE 3600
#endif
module BatteryWarningP{
	uses interface Read<uint8_t> as Switch;
	uses interface Read<uint16_t> as Voltage;
	uses interface Leds;
	uses interface BusyWait<TMicro, uint16_t>;
	uses interface GeneralIO;
	provides interface Init;
}
implementation{
	uint8_t switchState;
	uint8_t errorCount=0;
	command error_t Init.init(){
		return call Switch.read();
	}
	
	event void Switch.readDone(error_t err, uint8_t newSwitchState){
		if( err == SUCCESS ){
			switchState = newSwitchState;
			if( !(switchState == BATTERY_SWITCH_RECHARGABLE && call GeneralIO.get()) ){ //if we're not powered on USB
				call Voltage.read();
			}
		}
	}
	
	
	inline static void blinkLeds(uint8_t count, bool inner){
		uint8_t i;
		call Leds.set(0);
		if(inner)
			call Leds.led1On();
		else
			call Leds.led0On();
		call BusyWait.wait(50000U);
		for(i=0; i<=count; count==0?i=0:i++){
			if(inner){
				call Leds.led1Toggle();
				call Leds.led2Toggle();
			}else{
				call Leds.led0Toggle();
				call Leds.led3Toggle();
			}
			call BusyWait.wait(50000U);
		}
		call Leds.set(0);
	}
	
	event void Voltage.readDone(error_t err, uint16_t voltage){
		if( err == SUCCESS ){
			if( switchState == BATTERY_SWITCH_RECHARGABLE && voltage < MINIMUM_RECHARGABLE_VOLTAGE ){
				if( ++errorCount == 3){
					blinkLeds(3, TRUE);//FIXME this should be in the atomic block, but there's something wrong with busywait in atomic
					atomic{
						PRR0 = 0xff; PRR1 = 0xff; PRR2 = 0xff;//shut down everything
						SET_BIT(SMCR, SE);
						asm volatile ("sleep" : : : "memory");
						CLR_BIT(SMCR, SE);
					}
				}
			} else if( switchState == BATTERY_SWITCH_NOT_RECHARGABLE && voltage > MAXIMUM_NOT_RECHARGABLE_VOLTAGE ){
				if( ++errorCount == 3){
					blinkLeds(0, FALSE);//FIXME this should be in an atomic block, but there's something wrong with busywait in atomic
				}
			} else
				errorCount = 0;
			if( errorCount > 0  )
				call Voltage.read();
		} else
			call Voltage.read();
	}
}