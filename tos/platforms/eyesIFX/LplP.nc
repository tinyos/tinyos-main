/* -*- mode:c++; indent-tabs-mode:nil -*- 
 * Copyright (c) 2008, Technische Universitaet Berlin
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
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, 
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY 
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE 
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

module LplP {
    provides {  
        interface LowPowerListening;
    }
    uses {
        interface Sleeptime;
        interface Alarm<T32khz, uint16_t> as Timer;
        interface Random;
    }
}
implementation  {
#ifdef MAC_REDMAC
    #define ON_TIME 15
#elif  defined(MAC_SPECKMACD)   
    #define ON_TIME 5
#else
    #define ON_TIME 1
#endif
    
    #define MIN_SLEEP 2048
    norace uint16_t localsleep;

    async event void Timer.fired() {
        call Sleeptime.setLocalSleeptime(localsleep);
    }
    
    command void LowPowerListening.setLocalSleepInterval(uint16_t sleepIntervalMs) {
        if(sleepIntervalMs < 0x7FF) {
            localsleep = (sleepIntervalMs * 32);
        }
        else {
            localsleep = 0xffff;
        }
        if(localsleep < MIN_SLEEP) localsleep = MIN_SLEEP;
        call Timer.start(call Random.rand16());
    };
    
    command uint16_t LowPowerListening.getLocalSleepInterval() {
        return call Sleeptime.getLocalSleeptime() / 32;
    };
    command void LowPowerListening.setLocalDutyCycle(uint16_t dutyCycle) {
        call LowPowerListening.setLocalSleepInterval(dutyCycle * ON_TIME);
    };
    command uint16_t LowPowerListening.getLocalDutyCycle() {
        return call LowPowerListening.getLocalSleepInterval() / ON_TIME;
    };
    command void LowPowerListening.setRxSleepInterval(message_t *msg, uint16_t sleepIntervalMs) {
        uint16_t rsleep;
        if(sleepIntervalMs < 0x7FF) {
            rsleep = (sleepIntervalMs * 32);
        }
        else {
            rsleep = 0xffffU;
        }
        if(rsleep < MIN_SLEEP) rsleep = MIN_SLEEP;        
        call Sleeptime.setNetworkSleeptime(rsleep);
    };
    command uint16_t LowPowerListening.getRxSleepInterval(message_t *msg) {
        return call Sleeptime.getNetworkSleeptime() / 32;
    }
    command void LowPowerListening.setRxDutyCycle(message_t *msg, uint16_t dutyCycle) {
        call LowPowerListening.setRxSleepInterval(msg, dutyCycle * ON_TIME);        
    }
    command uint16_t LowPowerListening.getRxDutyCycle(message_t *msg) {
        return call LowPowerListening.getRxSleepInterval(msg) / ON_TIME;
    }
    command uint16_t LowPowerListening.dutyCycleToSleepInterval(uint16_t dutyCycle) {
        return dutyCycle * ON_TIME;
    }
    command uint16_t LowPowerListening.sleepIntervalToDutyCycle(uint16_t sleepInterval) {
        return sleepInterval / ON_TIME;
    }
}

