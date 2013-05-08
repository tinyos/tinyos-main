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
 * @author Mike Healy
 * @date   April, 2011
 * 
 * Driver for the shimmer GSR board
 * Based heavily on Adrian Burn's GSR code from tinyos-1.x/contrib/handhelds/apps/BioMOBIUS/GSR
 */

#include "Gsr.h"

module GsrP 
{
   provides interface Init;
   provides interface Gsr;
}
implementation 
{

#define HW_RES_40K_MIN_ADC_VAL    1120 //10k to 56k..1159->1140 // nom: changed to 1120 for linear conversion
#define HW_RES_287K_MAX_ADC_VAL   3960 //56k to 220k was 4000 but was 3948 on shimer so changed to 3800 // nom: changed to 3960 for linear conversion
#define HW_RES_287K_MIN_ADC_VAL   1490 //56k to 220k..1510->1490
#define HW_RES_1M_MAX_ADC_VAL     3700 //220k to 680k
#define HW_RES_1M_MIN_ADC_VAL     1630 //220k to 680k..1650->1630
#define HW_RES_3M3_MAX_ADC_VAL    3930 //680k to 4M7
#define HW_RES_3M3_MIN_ADC_VAL    1125 //680k to 4M7

// These constants were calculated by measuring against precision resistors
// and then using a linear fit to give CONDUCTANCE values 
#define HW_RES_40K_CONSTANT_A      0.0373
#define HW_RES_40K_CONSTANT_B      (-24.9915)

#define HW_RES_287K_CONSTANT_A     0.0054
#define HW_RES_287K_CONSTANT_B     (-3.5194)

#define HW_RES_1M_CONSTANT_A       0.0015
#define HW_RES_1M_CONSTANT_B       (-1.0163)

#define HW_RES_3M3_CONSTANT_A      0.00045580
#define HW_RES_3M3_CONSTANT_B      (-0.3014)


/* when we switch resistors with the ADG658 it takes a few samples for the 
   ADC to start to see the new sampled voltage correctly, the catch below is 
   to eliminate any glitches in the data */
#define ONE_HUNDRED_OHM_STEP 100
#define MAX_RESISTANCE_STEP 5000
/* instead of having a large step when resistors change - have a smoother step */
#define NUM_SMOOTHING_SAMPLES 64
/* ignore these samples after a resistor switch - instead send special code */
#define NUM_SAMPLES_TO_IGNORE 6
#define STARTING_RESISTANCE 10000000
/* Settling time for a hardware resistor change (80 ms)*/
#define SETTLING_TIME 80

   uint8_t last_active_resistor, transient_active_resistor, got_first_sample;
   uint16_t transient_sample, transient_smoothing_samples, max_resistance_step;
   uint32_t last_resistance;

   command error_t Init.init() {
      // configure pins
      TOSH_MAKE_PROG_OUT_OUTPUT(); //A0
      TOSH_SEL_PROG_OUT_IOFUNC();

      TOSH_MAKE_SER0_CTS_OUTPUT(); //A1
      TOSH_SEL_SER0_CTS_IOFUNC();


      // by default set to use 40kohm resistor 
      call Gsr.setRange(HW_RES_40K);
      last_active_resistor = HW_RES_40K;

      call Gsr.initSmoothing(HW_RES_40K);

      return SUCCESS;
   }

    
   command void Gsr.setRange(uint8_t range) {
      switch(range) {
         case HW_RES_40K:
            TOSH_CLR_PROG_OUT_PIN();
            TOSH_CLR_SER0_CTS_PIN();
            break;
         case HW_RES_287K:
            TOSH_SET_PROG_OUT_PIN();
            TOSH_CLR_SER0_CTS_PIN();
            break;
         case HW_RES_1M:
            TOSH_CLR_PROG_OUT_PIN();
            TOSH_SET_SER0_CTS_PIN();
            break;
         case HW_RES_3M3:
            TOSH_SET_PROG_OUT_PIN();
            TOSH_SET_SER0_CTS_PIN();
            break;
      }
   }


   uint64_t multiply(uint64_t no1, uint64_t no2){
      if (no1 == 0 || no2 == 0) return 0;
      if (no1 == 1) return no2;
      if (no2 == 1) return no1;
      return no1*no2;
   }

   command uint32_t Gsr.calcResistance(uint16_t ADC_val, uint8_t active_resistor) {
      float conductance=0;

      // Conductance measured in uS
      switch ( active_resistor ) {
      case HW_RES_40K:
         conductance = ( ( (HW_RES_40K_CONSTANT_A)* ADC_val) + (HW_RES_40K_CONSTANT_B) );
         break;
      case HW_RES_287K:
         conductance = ( ( (HW_RES_287K_CONSTANT_A)* ADC_val) + (HW_RES_287K_CONSTANT_B) );
         break;
      case HW_RES_1M:
         conductance = ( ( (HW_RES_1M_CONSTANT_A)* ADC_val) + (HW_RES_1M_CONSTANT_B) );
         break;
      case HW_RES_3M3:
         conductance = ( ( (HW_RES_3M3_CONSTANT_A)* ADC_val) + (HW_RES_3M3_CONSTANT_B) );
      default:
      }
      // Resistance = 1e6/Conductance (in ohms)
      return (uint32_t)(1000000.0/conductance);
   }


   command uint8_t Gsr.controlRange(uint16_t ADC_val, uint8_t active_resistor) {
      uint8_t ret = active_resistor;
      switch ( active_resistor ) {
      case HW_RES_40K:
         if (ADC_val < HW_RES_40K_MIN_ADC_VAL){
            call Gsr.setRange(HW_RES_287K);
            ret = HW_RES_287K;
         }
         break;
      case HW_RES_287K:
         if( (ADC_val <= HW_RES_287K_MAX_ADC_VAL) && (ADC_val >= HW_RES_287K_MIN_ADC_VAL) ) {
            ;//stay here
         } else if (ADC_val < HW_RES_287K_MIN_ADC_VAL) {
            call Gsr.setRange(HW_RES_1M);
            ret = HW_RES_1M;
         } else {
            call Gsr.setRange(HW_RES_40K);
            ret = HW_RES_40K;
         }
         break;
      case HW_RES_1M:
         if( (ADC_val <= HW_RES_1M_MAX_ADC_VAL) && (ADC_val >= HW_RES_1M_MIN_ADC_VAL) ) {
            ;//stay here
         } else if (ADC_val < HW_RES_1M_MIN_ADC_VAL) {
            call Gsr.setRange(HW_RES_3M3); 
            ret = HW_RES_3M3;
         } else {
            call Gsr.setRange(HW_RES_287K);
            ret = HW_RES_287K;
         }
         break;
      case HW_RES_3M3:
         if( (ADC_val <= HW_RES_3M3_MAX_ADC_VAL) && (ADC_val >= HW_RES_3M3_MIN_ADC_VAL) ) {
            ;//stay here
         } else if (ADC_val > HW_RES_3M3_MAX_ADC_VAL) {
            call Gsr.setRange(HW_RES_1M);
            ret = HW_RES_1M;
         } else {
            /* MIN so cant go any higher*/
         }
         break;
      default:
      }
      return ret;
   }


   command void Gsr.initSmoothing(uint8_t active_resistor) {
      last_active_resistor = active_resistor;
      got_first_sample = FALSE;
      transient_sample = NUM_SAMPLES_TO_IGNORE;
      transient_smoothing_samples = 0;
      max_resistance_step = MAX_RESISTANCE_STEP;
      last_resistance = STARTING_RESISTANCE;
   }

   /* Smooth the transition without converting ADC value to resistance: 
      Repeat the last 'valid' ADC value for each sample during the settling period,
      then step to the next valid ADC value after settling. This will not be seen 
      by most GSR applications as the settling time (approx 40 ms) is smaller than 
      typical GSR 'event' frequencies. If sampling at a high rate (e.g. due to other
      active sensors, this function will prevent large spikes in the GSR due to settling. */
   command bool Gsr.smoothTransition(uint8_t *dummy_active_resistor, uint32_t sampling_period){
       // Number of 'transient' samples proportional to sampling rate.
       if(*dummy_active_resistor != last_active_resistor) {
           transient_sample = ceil(SETTLING_TIME/sampling_period);
           transient_active_resistor = last_active_resistor;
       }
       last_active_resistor = *dummy_active_resistor;
       if(transient_sample) {
           transient_sample --;
           // keep the previous active resistor in the buffer during transition settling time
           *dummy_active_resistor = transient_active_resistor;
           return TRUE;
       }
       return FALSE;
   }

   command uint32_t Gsr.smoothSample(uint32_t resistance, uint8_t active_resistor) {
      if(active_resistor != last_active_resistor) {
         transient_sample = NUM_SAMPLES_TO_IGNORE;
         max_resistance_step = ONE_HUNDRED_OHM_STEP;
         transient_smoothing_samples = NUM_SMOOTHING_SAMPLES;
         last_active_resistor = active_resistor;
      }
      // if we are after a transition then max_resistance_step will be small to ensure smooth transition
      if (transient_smoothing_samples) {
         transient_smoothing_samples--;
         // if we are finished smoothing then go back to a larger resistance step
         if (!transient_smoothing_samples)
            max_resistance_step = MAX_RESISTANCE_STEP;
      }
      // only prevent a large step from last resistance if we actually have a last resistance
      if ((got_first_sample) && (last_resistance > max_resistance_step)) {
         if( resistance > (last_resistance+max_resistance_step) )
            resistance = (last_resistance+max_resistance_step);
         else if ( resistance < (last_resistance-max_resistance_step) )
            resistance = (last_resistance-max_resistance_step);
         else
            ;
      } else {
         // get the first sample in this run of sampling
         got_first_sample = TRUE;
      }

      last_resistance = resistance;
    
      // if this sample is near a resistor transition then send a special code for data analysis
      if(transient_sample) {
         transient_sample--;
         resistance = 0xFFFFFFFF;
      }

      return resistance;
   }
}
