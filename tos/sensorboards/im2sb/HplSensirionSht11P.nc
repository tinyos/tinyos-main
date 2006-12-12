/*
 * Copyright (c) 2005-2006 Arch Rock Corporation
 * All rights reserved.
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
 * - Neither the name of the Arch Rock Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * ARCHED ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

#include "Timer.h"

/**
 * HplSensirionSht11P is a low-level component that controls power for
 * the Sensirion SHT11 sensor on the telosb platform.
 *
 * @author Phil Buonadonna <pbuonadonna@archrock.com>
 * @version $Revision: 1.4 $ $Date: 2006-12-12 18:23:45 $
 */

module HplSensirionSht11P {
  provides interface SplitControl;
  uses interface Timer<TMilli>;
  uses interface HplPXA27xGPIOPin as DATA;
  uses interface HplPXA27xGPIOPin as SCK;
}
implementation {
  task void stopTask();

  command error_t SplitControl.start() {
    call DATA.setGAFRpin(0);
    call SCK.setGAFRpin(0);
    call Timer.startOneShot( 11 );
    return SUCCESS;
  }
  
  event void Timer.fired() {
    signal SplitControl.startDone( SUCCESS );
  }

  command error_t SplitControl.stop() {
    call SCK.setGPDRbit(FALSE);
    call SCK.setGPCRbit();
    call DATA.setGPDRbit(FALSE);
    call DATA.setGPCRbit();
    post stopTask();
    return SUCCESS;
  }

  task void stopTask() {
    signal SplitControl.stopDone( SUCCESS );
  }

  async event void DATA.interruptGPIOPin() { return; }
  async event void SCK.interruptGPIOPin() { return; }
}

