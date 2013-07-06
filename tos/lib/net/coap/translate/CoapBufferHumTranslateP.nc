/*
 * Copyright (c) 2011 University of Bremen, TZI
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
 */

generic module CoapBufferHumTranslateP() {
  provides interface Read<uint16_t> as ReadHum;
  uses interface Read<uint16_t>;
} implementation {

  command error_t ReadHum.read() {
    call Read.read();
    return SUCCESS;
  }

  event void Read.readDone(error_t result, uint16_t val) {
    /*
      The calculation of the relative humidity for TelosB nodes is done according to the datasheet SHT1x (www.sensirion.com/en/pdf/product_information/Datasheet-humidity-sensor-SHT1x.pdf).
      RH = c1 + c2 * val + c3 * val^2
      To avoid floating point calculations and to achieve a precision of 0.01 %, the values c1 and c2 are multiplied with 100 to get fixed point values and value c3 is transformed by 1/x. */
    val =  (-204 + val*4 -((uint32_t)val*(uint32_t)val)*100/628931);
    printf("CoapRead.readDone: %hu\n", val);
    signal ReadHum.readDone(result, val);
  }
}
