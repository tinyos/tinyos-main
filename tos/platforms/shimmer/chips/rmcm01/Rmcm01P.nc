/*
 * Copyright (c) 2011, Shimmer Research, Ltd.
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
 * @author Steve Ayer
 * @date   January, 2011
 *
 * this is a Notify wrapper for pulling heart rate from a Polar RMCM01 
 * module, which provides a positive digital pulse on the line connected 
 * to GPIO_EXTERNAL on the anex board.
 */

module Rmcm01P {
  provides{
    interface Init;
    interface DigitalHeartRate;
  }
  uses{
    interface HplMsp430Interrupt as BeatInterrupt;
    interface HplMsp430GeneralIO as Msp430GeneralIO;
    interface LocalTime<T32khz>;
    interface Timer<TMilli> as connectionTimer;
  }
}

implementation {
  enum {
    MAX_SAMPLES = 256
  };

  bool connected,  beat_received;
  uint8_t calculate_rate, number_of_samples, current_beat;
  uint16_t beat_count;
  uint32_t beat_times[MAX_SAMPLES], now;

  command error_t Init.init() {
    TOSH_MAKE_ADC_0_INPUT();
    TOSH_MAKE_ADC_7_INPUT();

    // power hard-wired (at this writing)
    atomic {
      call Msp430GeneralIO.makeInput();
      call Msp430GeneralIO.selectIOFunc();

      call BeatInterrupt.disable();
      call BeatInterrupt.edge(TRUE);

      call BeatInterrupt.clear();
      call BeatInterrupt.enable();
    }

    calculate_rate = FALSE;
    number_of_samples = 15;
    beat_count = 0;
    current_beat = 0;

    /*
     * assume that we're not connected until we see a beat
     * we'll check for a beat every three seconds
     */
    connected = beat_received = FALSE;
    call connectionTimer.startPeriodic(3000);

    return SUCCESS;
  }
  
  command void DigitalHeartRate.enableRate(uint8_t num_samples) {
    atomic {
      number_of_samples = num_samples;
      calculate_rate = TRUE;
      beat_count = 0;
    }
  }

  command void DigitalHeartRate.disableRate() {
    atomic calculate_rate = FALSE;

    memset(beat_times, 0, MAX_SAMPLES * sizeof(uint32_t));
    beat_count = 0;
  }

  command error_t DigitalHeartRate.getRate(uint8_t * rate){
    uint32_t total, interval;
    register int16_t i, j;
    float f_rate;

    if(beat_count < number_of_samples)
      return FAIL;

    total = 0;

    j = current_beat - 1;
    for(i = 0; i < number_of_samples; i++, j--){
      if(j < 0)
	j += MAX_SAMPLES;

      // ack; this just wraps the j - 1 counter
      interval = *(beat_times + j) - *(beat_times + (((j - 1) < 0) ? (j + MAX_SAMPLES - 1) : (j - 1)));
      total += interval;
    }

    // total is in seconds / 32768
    total >>= 15;   // there, that's better!

    f_rate = (float)((float)number_of_samples / (float)total * 60.0);

    *rate = (uint8_t)(f_rate + 0.5);

    return SUCCESS;
  }

  task void store_beat() {
    *(beat_times + current_beat) = now;

    if(current_beat == 255)
      current_beat = 0;
    else
      current_beat++;

    // we only need to to ensure we have enough beats for sample-size request
    if(beat_count < MAX_SAMPLES) 
      beat_count++;
  }

  event void connectionTimer.fired() {
    if(beat_received)
      beat_received = FALSE;
    else if(connected){
      call connectionTimer.stop();
      connected = FALSE;
      signal DigitalHeartRate.newConnectionState(FALSE);
    }
  }

  async event void BeatInterrupt.fired() {
    now = call LocalTime.get();

    signal DigitalHeartRate.beat(now);
    
    call BeatInterrupt.clear();

    if(!connected){
      connected = TRUE;
      call connectionTimer.startPeriodic(3000);
      signal DigitalHeartRate.newConnectionState(TRUE);
    }
    else
      beat_received = TRUE;

    if(calculate_rate)
      post store_beat();
  }
}
