/* -*- mode:c++; indent-tabs-mode: nil -*-
 * Copyright (c) 2007, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES {} LOSS OF USE, DATA,
 * OR PROFITS {} OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * Implementation of coulomb counter board interface for eyesIFXv2.1
 * @author: Andreas Koepke (koepke@tkn.tu-berlin.de)
 */

#include "Timer.h"

module CoulombCounterP {
    provides {
        interface CoulombCounter;
        interface Init;
    }
    uses {
        interface Timer<TMilli> as Timer;
        interface GpioInterrupt as EnergyInterrupt;
        interface GeneralIO as EnergyPin;
        interface GeneralIO as UsbBatSwitch;
        interface GeneralIO as ResetBoard;
        interface GeneralIO as UsbMonitor;
    }
}
implementation {
#define MIN_DELAY 30
    
    uint16_t timerHighBits = 0;
    uint32_t dur = 0;

    void resetBoard() {
        call ResetBoard.set();
        __asm__("NOP");
        call ResetBoard.clr();        
    }

    void startMeasure() {
        unsigned i;
        for(i = 0; i < 7; i++) {
            call UsbBatSwitch.set();
            call UsbBatSwitch.clr();
        }
    }

    void stopMeasure() {
        call UsbBatSwitch.set();
        call UsbBatSwitch.clr();
        // if your board allows it: delay until supply via USB stable
        resetBoard();
    }
    
    command error_t Init.init() {
        call EnergyPin.makeInput();
        call EnergyInterrupt.disable();
        
        call UsbBatSwitch.makeOutput();
        call UsbBatSwitch.clr();
        
        call ResetBoard.makeOutput();
        call ResetBoard.clr();
        
        call UsbMonitor.makeInput();
        if(!call CoulombCounter.isMeasureing()) {
            resetBoard();
        }
        return SUCCESS;
    }

    async command bool CoulombCounter.isMeasureing() {
        return call UsbMonitor.get(); // high --> disconnected --> measuremode
    }

    void startLongTimer() {
        if(timerHighBits) {
            timerHighBits--;
            call Timer.startOneShot(-1);
        }
        else {
            call Timer.startOneShot(dur);
        }
    }
    
    command error_t CoulombCounter.startMeasurement(uint32_t delay, uint32_t duration) {
        error_t result = SUCCESS;
        
        timerHighBits = duration >> 22;
        dur = duration * (uint32_t)1024;
        
        if(call CoulombCounter.isMeasureing()) {
            startLongTimer();
            call EnergyInterrupt.enableFallingEdge();
        }
        else {
            if((delay < MIN_DELAY) || (delay > ((uint32_t)1<<21))) {
                result = FAIL;
            }
            else {
                call Timer.startOneShot(delay * (uint32_t)1024);
            }
        }
        return result;
    }

    /** Stop a measurement, returns FAIL if there is no ongoing measurement */
    command error_t CoulombCounter.stopMeasurement() {
        error_t result = FAIL;
        call Timer.stop();
        timerHighBits = 0;
        dur = 0;
        call EnergyInterrupt.disable();
        if(call CoulombCounter.isMeasureing()) {
            stopMeasure();
            result = SUCCESS;
        }
        return result;
    }

    async event void EnergyInterrupt.fired() {
        signal CoulombCounter.portionConsumed();
    }
    
    event void Timer.fired() {
        if(call CoulombCounter.isMeasureing()) {
            if(timerHighBits) {
                startLongTimer();
            }
            else {
                // measurement finished
                call CoulombCounter.stopMeasurement();
            }
        }
        else {
            // finished waiting for delay
            resetBoard();
            startLongTimer();
            call EnergyInterrupt.enableFallingEdge();
            startMeasure();
        }
    }
}
