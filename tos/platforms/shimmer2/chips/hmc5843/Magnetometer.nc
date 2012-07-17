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
 * @author  Steve Ayer
 * @date    February, 2011
 *
 * broken out from original gyromagboard* interface/implementation
 */

interface Magnetometer {
  // i2c bus, that is
  command void enableBus();

  command void disableBus();

  // 0.5, 1, 2, 5, 10 (default), 20, 50hz.  20 and 50 up power burn dramatically
  command error_t setOutputRate(uint8_t rate);

  // +-0.7, 1.0 (default), 1.5, 2.0, 3.2, 3.8, 4.5Ga
  command error_t setGain(uint8_t gain);

  command error_t setIdle();
  command error_t goToSleep();

  command error_t runSingleConversion();

  command error_t runContinuousConversion();

  // call to clock out data; collect it from the "done" event
  command error_t readData();

  // convert raw data to heading
  command uint16_t readHeading(uint8_t * readBuf);

  // read result after readdone event
  command void selfTest();

  // call this to see three-axis magnetometer values
  command void convertRegistersToData(uint8_t * readBuf, int16_t * data);

  // this is where the app will find its mag readings
  async event void readDone(uint8_t * data, error_t success);
  
  async event void writeDone(error_t success);
}




