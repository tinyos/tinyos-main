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
 * @author Steve Ayer
 * @date March, 2010
 *
 * this interface is really just for cleaning up apps.
 * wire the app's softwareinit.init to the component's 
 * then call *in sequence* the add<Device>Inputs you want to sample: 
 * that will be the order of the samples.
 *
 * REMEMBER:  only eight channels, only one internal daughter card at a time, but 
 * notice that the anex is provided.
 */

interface shimmerAnalogSetup {

  // three channels
  command void addAccelInputs();   

  // three channels
  command void addGyroInputs();

  // two channels
  command void addECGInputs();

  // three channels
  command void addUVInputs();

  // one channels
  command void addGSRInput();
  
  // one channels
  command void addEMGInput();
  
  // either of two channels
  command void addAnExInput(uint8_t channel);

  // identical to ecg
  command void addStrainGaugeInputs();

  // sets number of channels back to zero
  command void reset();

  /*
   * call this after adding devices.
   * pass in a buffer to hold the sampling results
   * switching buffers can be done in the transferDone event
   */
  command void finishADCSetup(uint16_t * buffer);
  
  command void triggerConversion();
  
  command void stopConversion();

  command uint8_t getNumberOfChannels();
}

