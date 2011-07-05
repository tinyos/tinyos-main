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

#define HW_RES_40K_MIN_ADC_VAL    1140 //10k to 56k..1159->1140
#define HW_RES_287K_MAX_ADC_VAL   3800 //56k to 220k was 4000 but was 3948 on shimer so changed to 3800
#define HW_RES_287K_MIN_ADC_VAL   1490 //56k to 220k..1510->1490
#define HW_RES_1M_MAX_ADC_VAL     3700 //220k to 680k
#define HW_RES_1M_MIN_ADC_VAL     1630 //220k to 680k..1650->1630
#define HW_RES_3M3_MAX_ADC_VAL    3930 //680k to 4M7
#define HW_RES_3M3_MIN_ADC_VAL    1125 //680k to 4M7

// These constants were calculated by measuring against precision resistors
// and then using polynomial curve fitting 
#define HW_RES_40K_CONSTANT_1      0.0000000065995
#define HW_RES_40K_CONSTANT_2      (-0.000068950)
#define HW_RES_40K_CONSTANT_3      0.2699
#define HW_RES_40K_CONSTANT_4      (-476.9835)
#define HW_RES_40K_CONSTANT_5      340351.3341

#define HW_RES_287K_CONSTANT_1     0.000000013569627
#define HW_RES_287K_CONSTANT_2     (-0.0001650399)
#define HW_RES_287K_CONSTANT_3     0.7541990
#define HW_RES_287K_CONSTANT_4     (-1572.6287856)
#define HW_RES_287K_CONSTANT_5     1367507.9270

#define HW_RES_1M_CONSTANT_1       0.00000002550036498
#define HW_RES_1M_CONSTANT_2       (-0.00033136)
#define HW_RES_1M_CONSTANT_3       1.6509426597
#define HW_RES_1M_CONSTANT_4       (-3833.348044)
#define HW_RES_1M_CONSTANT_5       3806317.6947

#define HW_RES_3M3_CONSTANT_1      0.00000037153627
#define HW_RES_3M3_CONSTANT_2      (-0.004239437)
#define HW_RES_3M3_CONSTANT_3      17.905709
#define HW_RES_3M3_CONSTANT_4      (-33723.8657)
#define HW_RES_3M3_CONSTANT_5      25368044.6279


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


   uint8_t last_active_resistor, got_first_sample;
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
      uint32_t resistance=0;
      uint64_t adc_pow1, adc_pow2, adc_pow3, adc_pow4;

      adc_pow1 = ADC_val;
      adc_pow2 = multiply(adc_pow1, ADC_val);
      adc_pow3 = multiply(adc_pow2, ADC_val);
      adc_pow4 = multiply(adc_pow3, ADC_val);

      switch ( active_resistor ) {
      case HW_RES_40K:
         resistance = (
               ( (HW_RES_40K_CONSTANT_1)* adc_pow4) + //(powf(ADC_val,4)) ) + 
               ( (HW_RES_40K_CONSTANT_2)* adc_pow3) + //(powf(ADC_val,3)) ) + 
               ( (HW_RES_40K_CONSTANT_3)* adc_pow2) + //(powf(ADC_val,2)) ) + 
               ( (HW_RES_40K_CONSTANT_4)* adc_pow1) + //(powf(ADC_val,1)) ) + 
               (HW_RES_40K_CONSTANT_5) );
         break;
      case HW_RES_287K:
         resistance = (
               ( (HW_RES_287K_CONSTANT_1)* adc_pow4) + //(powf(ADC_val,4)) ) + 
               ( (HW_RES_287K_CONSTANT_2)* adc_pow3) + //(powf(ADC_val,3)) ) + 
               ( (HW_RES_287K_CONSTANT_3)* adc_pow2) + //(powf(ADC_val,2)) ) + 
               ( (HW_RES_287K_CONSTANT_4)* adc_pow1) + //(powf(ADC_val,1)) ) + 
               (HW_RES_287K_CONSTANT_5) );
         break;
      case HW_RES_1M:
         resistance = (
               ( (HW_RES_1M_CONSTANT_1)* adc_pow4) + //(powf(ADC_val,4)) ) + 
               ( (HW_RES_1M_CONSTANT_2)* adc_pow3) + //(powf(ADC_val,3)) ) + 
               ( (HW_RES_1M_CONSTANT_3)* adc_pow2) + //(powf(ADC_val,2)) ) + 
               ( (HW_RES_1M_CONSTANT_4)* adc_pow1) + //(powf(ADC_val,1)) ) + 
               (HW_RES_1M_CONSTANT_5) );
         break;
      case HW_RES_3M3:
         resistance = (
               ( (HW_RES_3M3_CONSTANT_1)* adc_pow4) + //(powf(ADC_val,4)) ) + 
               ( (HW_RES_3M3_CONSTANT_2)* adc_pow3) + //(powf(ADC_val,3)) ) + 
               ( (HW_RES_3M3_CONSTANT_3)* adc_pow2) + //(powf(ADC_val,2)) ) + 
               ( (HW_RES_3M3_CONSTANT_4)* adc_pow1) + //(powf(ADC_val,1)) ) + 
               (HW_RES_3M3_CONSTANT_5) );
      default:
      }
      return resistance;
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
