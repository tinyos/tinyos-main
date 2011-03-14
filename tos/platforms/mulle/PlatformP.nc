/*
 * Copyright (c) 2009 Communication Group and Eislab at
 * Lulea University of Technology
 *
 * Contact: Laurynas Riliskis, LTU
 * Mail: laurynas.riliskis@ltu.se
 * All rights reserved.
 *
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of Communication Group at Lulea University of Technology
 *   nor the names of its contributors may be used to endorse or promote
 *    products derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL STANFORD
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * Mulle platform initialization code.
 *
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 */

#include "hardware.h"
#include "rv8564.h"

module PlatformP
{
  provides interface Init;
  uses interface Init as SubInit;
  uses interface M16c60Control;
  uses interface StopModeControl;
#ifdef ENABLE_STOP_MODE
  provides interface Init as StopModeInit;

  uses interface HplRV8564 as RTC;
  uses interface HplDS2782;
  uses interface StdControl as DS2782Control;
#endif
}

implementation
{
  command error_t Init.init()
  {
    error_t ok = SUCCESS;

    ok = call M16c60Control.init();

    call StopModeControl.allowStopMode(false);

    // Init the M16c/60 to run at 10MHz.
    ok = ecombine (ok, call M16c60Control.defaultSystemClock(MCU_SPEED_10MHz));

    // Sub components initialization.
    ok = ecombine(ok, call SubInit.init());

    return SUCCESS;
  }


#ifdef ENABLE_STOP_MODE
  task void enableStopMode();

  command error_t StopModeInit.init()
  {
    // The task is needed so we can be sure that all underlying components 
    // have been initialized, for example the I2C resource.
    post enableStopMode();
  }

  task void enableStopMode()
  {
    call StopModeControl.allowStopMode(true);
    // Allow the DS2782 to enter sleep
    call DS2782Control.start();
    call HplDS2782.allowSleep(true);
    // Activate the RTC and set it to output 1024 tics on the CLKOUT pin
    call RTC.enableCLKOUT();
    call RTC.writeRegister(RV8564_CLKF, 0x81);  
  }

  task void stopDS2782()
  {
    call DS2782Control.stop();
  }

  async event void RTC.fired() {}
  async event void RTC.readRegisterDone(error_t error, uint8_t val, uint8_t reg) {}
  async event void RTC.writeRegisterDone(error_t error, uint8_t reg) {}

  async event void HplDS2782.setConfigDone(error_t error) {return; }
  async event void HplDS2782.allowSleepDone( error_t error ) { post stopDS2782(); }
  async event void HplDS2782.measureTemperatureDone( error_t error, uint16_t val ){ return; }
  async event void HplDS2782.measureVoltageDone( error_t error, uint16_t val ){ return; }
  async event void HplDS2782.measureCurrentDone( error_t error, uint16_t val ){ return; }
  async event void HplDS2782.measureAccCurrentDone( error_t error, uint16_t val ){ return; }
  async event void HplDS2782.setOffsetBiasDone( error_t error ){ return; }
  async event void HplDS2782.setAccOffsetBiasDone(error_t error){ return; }
#endif
}
