/* -*- mode:c++; indent-tabs-mode: nil -*- */
/**
 * Go around standard tinyos pin implementation, speed optimization
 */
/*
 * @author Andreas Koepke
*/
#include <msp430/iostructures.h>

module PlatformOneWireLowLevelP {
    provides {
        interface GeneralIO as OneWirePin;
    }
}
implementation{
#warning "Please ignore the non-atomic access warnings for shared variables port2"
    // OneWire: port 2.4
    async command void OneWirePin.set() {
        port2.out.pin4 = 1;
    }
    
    async command void OneWirePin.clr() {
        port2.out.pin4 = 0;
    }
    
    async command void OneWirePin.toggle() {
        if(port2.out.pin4) {
            port2.out.pin4 = 0;
        }
        else {
            port2.out.pin4 = 1;
        }
    }
    
    async command bool OneWirePin.get() {
        return port2.in.pin4;
    }
    
    async command void OneWirePin.makeInput() {
        port2.dir.pin4 = 0;
    }
    
    async command bool OneWirePin.isInput() {
        return !(port2.dir.pin4);
    }
    
    async command void OneWirePin.makeOutput() {
        port2.dir.pin4 = 1;
    }
    
    async command bool OneWirePin.isOutput() {
        return port2.dir.pin4;
    }
}
