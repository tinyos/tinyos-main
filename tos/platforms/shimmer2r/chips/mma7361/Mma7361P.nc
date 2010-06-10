/*
 * Copyright (c) 2010, Shimmer Research, Ltd.
 * All rights reserved
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:

 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer in the documentation and/or other materials provided
 *       with the distribution.
 *     * Neither the name of Shimmer Research, Ltd. nor the names of its
 *       contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.

 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * @author  Steve Ayer
 * @date    April, 2010
 */

#include "Mma_Accel.h"

module Mma7361P {
  provides {
    interface Init;
    interface Mma_Accel as Accel;
  }
}

implementation {
#warning "This accelerometer chipset supports only 1.5 and 6.0g; other settings will default to 1.5g"

  command error_t Init.init(){
    // control pins are already iofunc/input

    TOSH_SEL_ADC_ACCELZ_MODFUNC();
    TOSH_SEL_ADC_ACCELY_MODFUNC();
    TOSH_SEL_ADC_ACCELX_MODFUNC();

    call Accel.wake(1);

    return SUCCESS;
  }

  command void Accel.wake (bool wakeup) {
    if(wakeup)
      TOSH_SET_ACCEL_SLEEP_N_PIN();    // wakes up accel board
    else
      TOSH_CLR_ACCEL_SLEEP_N_PIN();    // puts accel board to sleep
  }

  command void Accel.setSensitivity (uint8_t sensitivity) {
    switch(sensitivity) {
    case RANGE_1_5G:
      TOSH_CLR_ACCEL_SEL0_PIN();
      break;
    case RANGE_6_0G:
      TOSH_SET_ACCEL_SEL0_PIN();
      break;
    default:                     // in case someone feeds it a non-7361 range
      TOSH_CLR_ACCEL_SEL0_PIN();
      break;
    }
  }
}





