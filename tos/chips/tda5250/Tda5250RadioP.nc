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
 * $Revision: 1.6 $
 * $Date: 2007-04-05 06:38:45 $
 * @author: Kevin Klues (klues@tkn.tu-berlin.de)
 * ========================================================================
 */

#include "tda5250Const.h"


/*
 * Controlling the Tda5250
 *
 * Switch modes and initialize.
 *
 * @author Kevin Klues
 * @author Philipp Huppertz
 * @author Andreas Koepke
 */
#include "Timer.h"

module Tda5250RadioP {
    provides {
        interface Init;
        interface SplitControl;
        interface Tda5250Control;
        interface RadioByteComm;
        interface ResourceRequested;
        interface ClkDiv;
    }
    uses {
        interface HplTda5250Config;
        interface HplTda5250Data;
        interface HplTda5250DataControl;
        interface Resource as ConfigResource;
        interface Resource as DataResource;
        interface ResourceRequested as DataResourceRequested;
        interface Alarm<T32khz, uint16_t> as DelayTimer;
    }
}

implementation {
  
    typedef enum {
        TRANSMITTER_DELAY,
        RECEIVER_DELAY,
        RSSISTABLE_DELAY
    } delayTimer_t;
  
    delayTimer_t delayTimer;  // current Mode of the Timer (RssiStable, TxSetupTime, RxSetupTime)
    radioMode_t radioMode;    // Current Mode of the Radio
    float onTime, offTime;

    /**************** Radio Init *****************/
    command error_t Init.init() {
        radioMode = RADIO_MODE_OFF;
        return SUCCESS;
    }

    /**************** Radio Start  *****************/
    task void startDoneTask() {
        signal ClkDiv.startDone();
        signal SplitControl.startDone(SUCCESS);
    }
      
    command error_t SplitControl.start() {
        radioMode_t mode;
        atomic mode = radioMode;
        if(mode == RADIO_MODE_OFF) {
            atomic radioMode = RADIO_MODE_ON_TRANSITION;
            return call ConfigResource.request();
        }
        return FAIL;
    }

    /**************** Radio Stop  *****************/
    task void stopDoneTask() {
        signal SplitControl.stopDone(SUCCESS); 
    }
      
    command error_t SplitControl.stop(){
        atomic radioMode = RADIO_MODE_OFF_TRANSITION;
        return call ConfigResource.request();
    }

    /* radioBusy
     * This function checks whether the radio is busy
     * so as to decide whether it can perform some operation or not.
     */
    bool radioBusy() {
        switch(radioMode) {
            case RADIO_MODE_OFF:
            case RADIO_MODE_ON_TRANSITION:
            case RADIO_MODE_OFF_TRANSITION:
            case RADIO_MODE_TX_TRANSITION:
            case RADIO_MODE_RX_TRANSITION:
            case RADIO_MODE_TIMER_TRANSITION:
            case RADIO_MODE_SELF_POLLING_TRANSITION:
            case RADIO_MODE_SLEEP_TRANSITION:
                return TRUE;
            default:
                return FALSE;
        }
    }

    void switchConfigResource() {
        radioMode_t mode;
        atomic mode = radioMode;
        switch(mode) {
            case RADIO_MODE_ON_TRANSITION:
                call HplTda5250Config.reset();
                call HplTda5250Config.SetRFPower(INITIAL_RF_POWER);
                // call HplTda5250Config.SetClockOnDuringPowerDown();
                call ConfigResource.release();
                atomic radioMode = RADIO_MODE_ON;
                post startDoneTask();
                break;
            case RADIO_MODE_OFF_TRANSITION:
                signal ClkDiv.stopping();
                call HplTda5250Config.SetSleepMode();
                call ConfigResource.release();
                atomic radioMode = RADIO_MODE_OFF;
                post stopDoneTask();
                break;
            case RADIO_MODE_SLEEP_TRANSITION:
                signal ClkDiv.stopping();
                call HplTda5250Config.SetSlaveMode();
                call HplTda5250Config.SetSleepMode();
                atomic radioMode = RADIO_MODE_SLEEP;
                signal Tda5250Control.SleepModeDone();
                break;
            case RADIO_MODE_TX_TRANSITION:
                call HplTda5250Config.SetSlaveMode();
                call HplTda5250Config.SetTxMode();
                if (!(call HplTda5250Config.IsTxRxPinControlled()))
                    call ConfigResource.release();
                atomic delayTimer = TRANSMITTER_DELAY;
                call DelayTimer.start(TDA5250_TRANSMITTER_SETUP_TIME);
                break;
            case RADIO_MODE_RX_TRANSITION:
                call HplTda5250Config.SetSlaveMode();
                call HplTda5250Config.SetRxMode();
                if (!(call HplTda5250Config.IsTxRxPinControlled()))
                    call ConfigResource.release();
                atomic delayTimer = RECEIVER_DELAY;
                call DelayTimer.start(TDA5250_RECEIVER_SETUP_TIME);
                break;
            case RADIO_MODE_TIMER_TRANSITION:
                call HplTda5250Config.SetTimerMode(onTime, offTime);
                call ConfigResource.release();
                atomic radioMode = RADIO_MODE_TIMER;
                signal Tda5250Control.TimerModeDone();
                break;
            case RADIO_MODE_SELF_POLLING_TRANSITION:
                call HplTda5250Config.SetSelfPollingMode(onTime, offTime);
                call ConfigResource.release();
                atomic radioMode = RADIO_MODE_SELF_POLLING;
                signal Tda5250Control.SelfPollingModeDone();
                break;
            default:
                break;
        }
    }

    event void ConfigResource.granted() {
        switchConfigResource();
    }

    void switchDataResource() {
        radioMode_t mode;
        atomic mode = radioMode;
        switch(mode) {
          case RADIO_MODE_TX_TRANSITION:
            atomic radioMode = RADIO_MODE_TX;
            signal Tda5250Control.TxModeDone();
            break;
          case RADIO_MODE_RX_TRANSITION:
            atomic radioMode = RADIO_MODE_RX;
            signal Tda5250Control.RxModeDone();
            break;
          default:
            break;
        }
    }
      
    event void DataResource.granted() {
        switchDataResource();
    }
      
    // information for higher layers that the DataResource has been requested
    async event void DataResourceRequested.requested() {
        signal ResourceRequested.requested();
    }

    async event void DataResourceRequested.immediateRequested() {
        signal ResourceRequested.immediateRequested();
    }

    /**
       Set the mode of the radio
       The choices are TIMER_MODE, SELF_POLLING_MODE
    */
    async command error_t Tda5250Control.TimerMode(float on_time, float off_time) {
        radioMode_t mode;
        atomic {
            if(radioBusy() == FALSE) {
                radioMode = RADIO_MODE_TIMER_TRANSITION;
                onTime = on_time;
                offTime = off_time;
            }
            mode = radioMode;
        }
        if(radioMode == RADIO_MODE_TIMER_TRANSITION) {
            call DataResource.release();
            if (call ConfigResource.immediateRequest() == SUCCESS) {
                switchConfigResource();
            } else {
                call ConfigResource.request();
            }
            return SUCCESS;
        }
        return FAIL;
    }

    async command error_t Tda5250Control.ResetTimerMode() {
        radioMode_t mode;
        atomic {
            if(radioBusy() == FALSE) {
                radioMode = RADIO_MODE_TIMER_TRANSITION;
            }
            mode = radioMode;
        }
        if(radioMode == RADIO_MODE_TIMER_TRANSITION) {
            call DataResource.release();
            if (call ConfigResource.immediateRequest() == SUCCESS) {
                switchConfigResource();
            } else {
                call ConfigResource.request();
            }
            return SUCCESS;
        }
        return FAIL;
    }

    async command error_t Tda5250Control.SelfPollingMode(float on_time, float off_time) {
        radioMode_t mode;
        atomic {
            if(radioBusy() == FALSE) {
                radioMode = RADIO_MODE_SELF_POLLING_TRANSITION;
                onTime = on_time;
                offTime = off_time;
            }
            mode = radioMode;
        }
        if(radioMode == RADIO_MODE_SELF_POLLING_TRANSITION) {
            call DataResource.release();
            if (call ConfigResource.immediateRequest() == SUCCESS) {
                switchConfigResource();
            } else {
                call ConfigResource.request();
            }
            return SUCCESS;
        }
        return FAIL;
    }

    async command error_t Tda5250Control.ResetSelfPollingMode() {
        radioMode_t mode;
        atomic {
            if(radioBusy() == FALSE) {
                radioMode = RADIO_MODE_SELF_POLLING_TRANSITION;
            }
            mode = radioMode;
        }
        if(radioMode == RADIO_MODE_SELF_POLLING_TRANSITION) {
            call DataResource.release();
            if (call ConfigResource.immediateRequest() == SUCCESS) {
                switchConfigResource();
            } else {
                call ConfigResource.request();
            }
            return SUCCESS;
        }
        return FAIL;
    }

    async command error_t Tda5250Control.SleepMode() {
        radioMode_t mode;
        atomic{
            if(radioBusy() == FALSE) {
                radioMode = RADIO_MODE_SLEEP_TRANSITION;
            }
            mode = radioMode;
        }
        if(mode == RADIO_MODE_SLEEP_TRANSITION) {
            call DataResource.release();
            switchConfigResource();
            return SUCCESS;
        }
        return FAIL;
    }
    
    async command error_t Tda5250Control.TxMode() {
        radioMode_t mode;
        atomic {
            if(radioBusy() == FALSE) {
                radioMode = RADIO_MODE_TX_TRANSITION;
            }
            mode = radioMode;
        }
        if(mode == RADIO_MODE_TX_TRANSITION) {
          call DataResource.release();
          call HplTda5250DataControl.setToTx();
          if (call HplTda5250Config.IsTxRxPinControlled()) {
            switchConfigResource();
          } else {
            if (call ConfigResource.immediateRequest() == SUCCESS) {
              switchConfigResource();
            } else {
              call ConfigResource.request();
            }
          }
          return SUCCESS;
        }
        return FAIL;
    }

    async command error_t Tda5250Control.RxMode() {
        radioMode_t mode;
        atomic {
            if(radioBusy() == FALSE) {
                radioMode = RADIO_MODE_RX_TRANSITION;
            }
            mode = radioMode;
        }
        if(mode == RADIO_MODE_RX_TRANSITION) {
          call DataResource.release();
          call HplTda5250DataControl.setToRx();
          if (call HplTda5250Config.IsTxRxPinControlled()) {
            switchConfigResource();
          } else {
              if (call ConfigResource.immediateRequest() == SUCCESS) {
                  switchConfigResource();
              } else {
                  call ConfigResource.request();
              }
          }
          return SUCCESS;
        }
        return FAIL;
    }

    async event void HplTda5250Data.txReady() {
        signal RadioByteComm.txByteReady(SUCCESS);
    }
    async event void HplTda5250Data.rxDone(uint8_t data) {
        signal RadioByteComm.rxByteReady(data);
    }

    async event void HplTda5250Config.PWDDDInterrupt() {
        signal Tda5250Control.PWDDDInterrupt();
    }

    async command void RadioByteComm.txByte(uint8_t data) {
        error_t error = call HplTda5250Data.tx(data);
        if(error != SUCCESS) {
            signal RadioByteComm.txByteReady(error);
        }
    }

    async command bool RadioByteComm.isTxDone() {
        //return call HplTda5250Data.isTxDone();
        return TRUE;
    }
      
/* Generate events (these are no interrupts */
    async event void DelayTimer.fired() {
        delayTimer_t delay;
        atomic { delay = delayTimer; }
        switch (delay) {
          case RSSISTABLE_DELAY :
            signal Tda5250Control.RssiStable();
            break;
          case RECEIVER_DELAY :
              signal ClkDiv.startDone();
            delayTimer = RSSISTABLE_DELAY;
            call DelayTimer.start(TDA5250_RSSI_STABLE_TIME-TDA5250_RECEIVER_SETUP_TIME);
            if (call DataResource.immediateRequest() == SUCCESS) {
              switchDataResource();
            } else {
              call DataResource.request();
            }
            break;
          case TRANSMITTER_DELAY :
              signal ClkDiv.startDone();
            if (call DataResource.immediateRequest() == SUCCESS) {
              switchDataResource();
            } else {
              call DataResource.request();
            }
            break;
        }
      }

      default async event void ResourceRequested.requested() {
      }
      default async event void ResourceRequested.immediateRequested() {
      }
      default async event void Tda5250Control.TimerModeDone(){
      }
      default async event void Tda5250Control.SelfPollingModeDone(){
      }
      default async event void Tda5250Control.RxModeDone(){
      }
      default async event void Tda5250Control.TxModeDone(){
      }
      default async event void Tda5250Control.SleepModeDone(){
      }
      default async event void Tda5250Control.PWDDDInterrupt() {
      }
      default async event void RadioByteComm.rxByteReady(uint8_t data) {
      }
      default async event void RadioByteComm.txByteReady(error_t error) {
      }
      default async event void ClkDiv.startDone() {
      }
      default async event void ClkDiv.stopping() {
      }
}
