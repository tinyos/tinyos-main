/*
 * Copyright (c) 2006, Intel Corporation
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 * Redistributions of source code must retain the above copyright notice, 
 * this list of conditions and the following disclaimer. 
 *
 * Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution. 
 *
 * Neither the name of the Intel Corporation nor the names of its contributors
 * may be used to endorse or promote products derived from this software 
 * without specific prior written permission. 
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
 * POSSIBILITY OF SUCH DAMAGE.
 *
 * @author Steve Ayer
 * @date August 2006
 * @author Konrad Lorincz
 * ported to TOS 2
 */

#include "Mma7260.h"

module Mma7260P 
{
    provides interface Init;
    provides interface Mma7260;
}
implementation 
{
    command error_t Init.init()
    {
        // configure pins
        TOSH_MAKE_ACCEL_SLEEP_N_OUTPUT();         // sleep for accel
        TOSH_SEL_ACCEL_SLEEP_N_IOFUNC();
        
        TOSH_MAKE_ADC_ACCELZ_INPUT();         
        TOSH_SEL_ADC_ACCELZ_MODFUNC();

        TOSH_MAKE_ADC_ACCELY_INPUT();         
        TOSH_SEL_ADC_ACCELY_MODFUNC();

        TOSH_MAKE_ADC_ACCELX_INPUT();         
        TOSH_SEL_ADC_ACCELX_MODFUNC();

        // by default wake up accelerometer
        call Mma7260.wake(TRUE);

        return SUCCESS;
    }

    
    command void Mma7260.wake(bool wakeup) 
    {
        if(wakeup)
            TOSH_SET_ACCEL_SLEEP_N_PIN();    // wakes up accel board
        else
            TOSH_CLR_ACCEL_SLEEP_N_PIN();    // puts accel board to sleep
    }

    command void Mma7260.setSensitivity(enum MMA7260_RANGE sensitivity) 
    {
        switch(sensitivity) {
        case RANGE_1_5G:
            TOSH_CLR_ACCEL_SEL0_PIN();
            TOSH_CLR_ACCEL_SEL1_PIN();
            break;
        case RANGE_2_0G:
            TOSH_SET_ACCEL_SEL0_PIN();
            TOSH_CLR_ACCEL_SEL1_PIN();
            break;
        case RANGE_4_0G:
            TOSH_CLR_ACCEL_SEL0_PIN();
            TOSH_SET_ACCEL_SEL1_PIN();
            break;
        case RANGE_6_0G:
            TOSH_SET_ACCEL_SEL0_PIN();
            TOSH_SET_ACCEL_SEL1_PIN();
            break;
        }
    }
}




