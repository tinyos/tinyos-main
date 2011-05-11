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
 */

interface Gsr 
{
   /**
    * Adjusts the GSR's range by selecting the which internal resistor is used
    *
    * @param range: select the resistor to use
    *               0:  40 kohm
    *               1: 287 kohm
    *               2: 1.0 Mohm
    *               3: 3.3 Mohm 
    */
   command void setRange(uint8_t range);

   /**
    * Calculates resistance from a raw ADC value
    *
    * @param ADC_val: the ADC value to be used in the calculation
    * @param active_resistor: the currently active resistor on the GSR board 
    * @return the calculated resistance
    */
   command uint32_t calcResistance(uint16_t ADC_val, uint8_t active_resistor);

   /**
    * Determines whether to change the currently active internal resistor based 
    * on the ADC value, and if necessary change the internal resistor to a new
    * value
    *
    * @param ADC_val: the ADC value to be used in the calculation
    * @param active_resistor: the currently active resistor on the GSR board 
    * @return the active internal resistor 
    */
   command uint8_t controlRange(uint16_t ADC_val, uint8_t active_resistor);

   /**
    * Initializes the smoothing state 
    *
    * @param active_resistor: the currently active resistor on the GSR board 
    */
   command void initSmoothing(uint8_t active_resistor);

   /**
    * Smooths the GSR values
    *
    * @param resistance: the current resistance value to smoothed 
    * @param active_resistor: the currently active resistor on the GSR board 
    * @return the smoothed resistance. Returns 0xFFFFFFFF if transient sample
    */
   command uint32_t smoothSample(uint32_t resistance, uint8_t active_resistor);
}
