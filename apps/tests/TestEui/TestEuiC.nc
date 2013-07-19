// $Id: TestEuiC.nc,v 1.2 2010-06-29 22:07:23 scipio Exp $
/*
 * Copyright (c) 2007, Vanderbilt University
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
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
 *
 * Author: Janos Sallai
 */

/**
 * This application reads the 64-bit EUI of the device at initialization time
 * and then periodically, and prints it out using printf.
 *
 */
module TestEuiC
{
  uses interface Boot;
  uses interface Timer<TMilli>;
  uses interface Leds;
  uses interface LocalIeeeEui64;
}
implementation
{
  void print() {
  }

  event void Boot.booted()  {
    call Timer.startPeriodic(1000);
  }

  event void Timer.fired() {
    int i;
    ieee_eui64_t id;

    call Leds.led0Toggle();

    id = call LocalIeeeEui64.getId();

    printf("IEEE 64-bit UID: ");
    for(i=0;i<8;i++) {
      printf("%02x", id.data[i]);
      if (i < 7) {
        printf(":");
      }
    }
    printf("\n");
  	printfflush();

  }
}

