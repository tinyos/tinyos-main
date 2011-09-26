/*
 * Copyright (c) 2011 ZOLERTIA LABS
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 *
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 *
 * - Neither the name of the copyright holders nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/*
 * Simple driver for the ZIG-LIGHT Ziglet, based on the TAOS TSL2563 
 * digital light sensor, features only a read light command.
 *
 * @author: Antonio Linan <alinan@zolertia.com>
 */
 
#include "PrintfUART.h"

configuration TSLC {
  provides {
    interface Read<uint16_t> as Light;
  }
}
  
implementation {
 
  components TSLP;
  Light = TSLP;
  
  components new Msp430I2C1C() as I2C;
  TSLP.Resource -> I2C;
  TSLP.ResourceRequested -> I2C;
  TSLP.I2CBasicAddr -> I2C; 

  components new TimerMilliC() as TimeoutTimer;
  TSLP.TimeoutTimer -> TimeoutTimer;

  components new TimerMilliC() as TimerUp;
  TSLP.TimerUp -> TimerUp;

}


