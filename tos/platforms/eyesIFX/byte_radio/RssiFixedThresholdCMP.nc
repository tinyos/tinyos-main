/* -*- mode:c++; indent-tabs-mode: nil -*-
 * Copyright (c) 2004-2006, Technische Universitaet Berlin
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
 *
 * - Revision -------------------------------------------------------------
 * $Revision: 1.3 $
 * $Date: 2006-11-07 19:31:22 $
 * @author: Kevin Klues (klues@tkn.tu-berlin.de)
 * @author: Philipp Huppertz (huppertz@tkn.tu-berlin.de)
 * @author: Andreas Koepke (koepke@tkn.tu-berlin.de)
 * ========================================================================
 */

includes shellsort;
module RssiFixedThresholdCMP {
    provides {
      interface Init;
      interface StdControl;
      interface ChannelMonitor;
      interface ChannelMonitorControl;
      interface ChannelMonitorData;
      interface BatteryLevel;
    }
    uses {
        interface ReadNow<uint16_t> as Rssi;
        interface Read<uint16_t> as Voltage;
        interface Timer<TMilli> as Timer;
        // interface Resource as RssiAdcResource;
        // interface GeneralIO as Led3;
        // interface GeneralIO as Led2;
    }
}
implementation
{    
//#define CM_DEBUG                    // debug...
    /* Measure internal voltage every 20s */
#define VOLTAGE_SAMPLE_INTERVALL 20000

    /* 
     * Number of samples for noisefloor estimation
     * Actually the size of the array for the median
     */
#define NSAMPLES 5
        
    /*
     * If the channel is seen more then DEADLOCK times 
     * in a row busy, update noisefloor nonetheless.
     */
#define DEADLOCK 10
        
    /* 
     * Initital noisefloor from data sheet ca. 350mV 
     * Seems to depend on many things, usually values around
     * 250 mV are observed for the eyesIFXv2 node, but 450 has also 
     * been measured as noise floor. It is also not stable, depending
     * on the placement of the node (USB cable shielding!) 
     */
#define NOISE_FLOOR 480 // raw value compared to 3V

    // mu + 3*sigma -> rare event, outlier? 
#define THREE_SIGMA          145

    // 92 mV measured against 3V Vcc 
#define INITIAL_BUSY_DELTA   120
    
    // 3000/2 mV measured against 2.5V Ref
#define INITIAL_BATTERY_LEVEL 2457 

    /*** calibration stuff *************************/
#define UPDATE_NF_RUNS   10
#define MINIMUM_POSITION 0
#define RSSI_SAMPLE_INTERVALL   20 // it makes no sense to check the channel too often

    /*** variable type definitions ******************/
    typedef enum {
        VOID,
        CALIBRATE, // update noisefloor
        IDLE,      // noisefloor up to date, nothing is currently attempted
        CCA,       // in clear channel assessment
        SNR        // measureing SNR
    } state_t;
    
    /****************  Variables  *******************/
    state_t state;       // what we try to do
    int16_t gradient;    // how to convert mV to dB in mV/dB

    uint16_t noisefloor;       // [raw value against Vcc]
    uint16_t batteryLevel;     // [raw value against 2.5V ref]
    
    /* if the rssi value exceeds noisefloor + busyDelta
     * the channel is busy
     */
    uint16_t busyDelta;    // [raw value against Vcc]
    
    // noise floor estimation
    uint16_t rssisamples[NSAMPLES];
    uint8_t rssiindex;

    // deadlock protection counter
    uint8_t deadlockCounter;

    // last rssi reading
    uint16_t rssi;           // rssi in [mV]
    
    /****************  Tasks  *******************/
    task void UpdateNoiseFloorTask();
    // task void GetChannelStateTask();
    task void SnrReadyTask();
    task void CalibrateNoiseFloorTask();
    // task void GetSnrTask();
    task void CalibrateTask();
    task void GetVoltageTask();

    /***************** Helper function *************/
#ifdef CM_DEBUG
    void signalFailure() {
      atomic {
        for(;;) {
          ;
        }
      }
    }
#else
    inline void signalFailure() {
    };
#endif

    int16_t computeSNR(uint16_t r) {
        uint32_t delta;
        uint16_t snr;
        if(r > noisefloor) {
             delta = r - noisefloor;
             // speedily cacluate
             // (2*batteryLevel*2500mV*delta)/(4095*4095*gradient)
             snr = ((((uint32_t)batteryLevel*39)>>5)*delta>>12)/gradient;
        } else {
            snr = 0;
        }
        return snr;
    }
    /**************** Init *******************/
    command error_t Init.init() {
        atomic {
            noisefloor = NOISE_FLOOR;
            rssiindex = 0;
            batteryLevel = INITIAL_BATTERY_LEVEL;
            busyDelta = INITIAL_BUSY_DELTA;
            state = VOID;
            gradient = 14; // gradient of TDA5250
            /* call Led3.makeOutput(); 
               call Led3.clr(); */
        }
        return SUCCESS;
    }
    
    /**************** StdControl *******************/   
    command error_t StdControl.start() { 
        return post GetVoltageTask();
    }
   
    command error_t StdControl.stop() {
        call Timer.stop();
        return SUCCESS;
    }
     
    /**************** RSSI *******************/

    inline void addSample(uint16_t data)  {
        if(rssiindex < NSAMPLES) rssisamples[rssiindex++] = data;
        deadlockCounter = 0;
        if(rssiindex >= NSAMPLES) post UpdateNoiseFloorTask();
    }

    error_t rssiRead() {
        error_t res = call Rssi.read();
        if(res != SUCCESS) signalFailure();
        return res;
    }
    
    async event void Rssi.readDone(error_t result, uint16_t data) {
        switch(state) {
            case CCA:
                state = IDLE;
                if(data < noisefloor + busyDelta) {
                    signal ChannelMonitor.channelIdle();
                    addSample(data);
                }
                else {
                    signal ChannelMonitor.channelBusy();
                    if(++deadlockCounter >= DEADLOCK) addSample(data);
                }
                break;
            case SNR:
                rssi = data;
                post SnrReadyTask();    
                break;
            case CALIBRATE:
                rssi = data;
                post CalibrateNoiseFloorTask();    
                break;
            default:
                break;
        }
    }
    

    /**************** Voltage *******************/
    void readVoltage() {
        if(call Voltage.read() != SUCCESS) post GetVoltageTask();
    }
    
    task void GetVoltageTask() {
        readVoltage();
    }
    
    event void Voltage.readDone(error_t result, uint16_t data) {
        uint16_t nbl;
        int16_t d;
        uint16_t nbD;
        uint16_t bD;
        if(result == SUCCESS) {
            nbl = (data + batteryLevel)>>1;
            atomic bD = busyDelta;
            d = batteryLevel - nbl;
            if(d > 75 || d < -75) {
                // recalculate busyDelta,
                // noisefloor already adapted by floating
                nbD = ((uint32_t)batteryLevel*(uint32_t)busyDelta)/(uint32_t)nbl;
                atomic busyDelta = nbD;
                batteryLevel = nbl;
            }
        } else {
            post GetVoltageTask();
        }
    }
    
    /**************** ChannelMonitor *******************/  
    async command error_t ChannelMonitor.start() {
        error_t res = FAIL;
        atomic {
            if(state == IDLE) {
                res = rssiRead();
                if(res == SUCCESS) state = CCA;
            }
            else if(state == CCA) {
                res = SUCCESS;
            }
        }
        return res;
    }

    async command void ChannelMonitor.rxSuccess() {
        atomic {
            if((deadlockCounter > 0) && (deadlockCounter < DEADLOCK)) {
                --deadlockCounter;
            }
        }
    }
    
/*    task void GetChannelStateTask() {
        atomic {
            if((state != IDLE) && (state != CCA)) {
                post GetChannelStateTask();
            } else {
              state = CCA;
              rssiRead();
              //if(call RssiAdcResource.request() != SUCCESS) signalFailure();
            }
        }
    }
*/    
    task void UpdateNoiseFloorTask() {
        shellsort(rssisamples,NSAMPLES);
        atomic { 
            noisefloor = (5*noisefloor + rssisamples[NSAMPLES/2])/6;
            rssiindex = 0; 
        }
    }

    /**************** ChannelMonitorControl ************/ 

    command async error_t ChannelMonitorControl.updateNoiseFloor() {
        return post CalibrateTask();
    }

    task void CalibrateTask() {
        atomic {
            if((state != IDLE) && (state != VOID)) {
                post CalibrateTask();
            } else {
                state = CALIBRATE;
                deadlockCounter = 0;
                call Timer.stop();
                call Timer.startPeriodic(RSSI_SAMPLE_INTERVALL);
            }
        }
    }

    task void CalibrateNoiseFloorTask() {
        atomic {
            if(rssiindex < NSAMPLES) {
                rssisamples[rssiindex++] = rssi;
            } else { 
                shellsort(rssisamples,NSAMPLES);
                if(rssisamples[MINIMUM_POSITION] < noisefloor + THREE_SIGMA)  {
                    noisefloor = (7*noisefloor + rssisamples[NSAMPLES/2])/8;
                    ++deadlockCounter;
                }
                else {
                    noisefloor += THREE_SIGMA/8;
                }
                rssiindex = 0; 
            }
            if(deadlockCounter > UPDATE_NF_RUNS) {
                state = IDLE;
                deadlockCounter = 0;
                call Timer.stop();
                call Timer.startPeriodic(VOLTAGE_SAMPLE_INTERVALL);
                signal ChannelMonitorControl.updateNoiseFloorDone();
            }
        }
    }

    event void Timer.fired() {
        state_t s;
        atomic s = state;
        if(s != CALIBRATE) {
            readVoltage();
        } else {
            rssiRead();
            // call RssiAdcResource.request();
        }
    }
    
    /**************** ChannelMonitorData ************/  
    async command void ChannelMonitorData.setGradient(int16_t grad) {
        // needed to convert RSSI into dB
        atomic gradient = grad;
    }
    
    async command int16_t ChannelMonitorData.getGradient() {
        int16_t v;
        atomic v = gradient;
        return v;
    }
    
    async command uint16_t ChannelMonitorData.getNoiseFloor() {
        uint16_t v;
        atomic v = noisefloor;
        return v;
    }

    /** get SNR in dB **/
    /* task void GetSnrTask() {
        state_t s;
        atomic s = state;
        if(s == SNR) {
            if(call RssiAdcResource.immediateRequest() == SUCCESS) {
                rssiRead();
            } else {
                atomic if(state == SNR) state = IDLE;
            }
        }
        }
    */
    
    async command error_t ChannelMonitorData.getSnr() {
        error_t res = FAIL;
        atomic {
            if(state == IDLE) {
                res = rssiRead();
                if(res == SUCCESS) state = SNR;
            }
            else if(state == SNR) {
                res = SUCCESS;
            }
        }
        return res;
    }

    task void SnrReadyTask() {
        int16_t snr;
        state_t s;
        uint16_t r;
        atomic {
            r = rssi;
            s = state;
            if(state == SNR) state = IDLE;
        }
        if(s == SNR) {
            snr = computeSNR(r);
            signal ChannelMonitorData.getSnrDone(snr);
        }
    }

    async command uint16_t ChannelMonitorData.readSnr() {
        uint16_t rval;
        if(rssi > noisefloor) {
            rval = (rssi-noisefloor)>>4;
        } else {
            rval = 3;
        }
        return rval;
    }
    
    default async event void ChannelMonitorData.getSnrDone(int16_t snr) {
    }

    /***** BatteryLevel ***************/
    // get the batterylevel in mV
    async command uint16_t BatteryLevel.getLevel() {
        uint16_t l;
        atomic l = batteryLevel;
        return (uint32_t)l*39>>5;
    }
}
