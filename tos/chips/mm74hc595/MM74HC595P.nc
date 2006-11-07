/* 
 * Copyright (c) 2006, Ecole Polytechnique Federale de Lausanne (EPFL),
 * Switzerland.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Ecole Polytechnique Federale de Lausanne (EPFL) 
 *   nor the names of its contributors may be used to 
 *   endorse or promote products derived from this software without 
 *   specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, Data,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * ========================================================================
 */

/*
 * @author Henri Dubois-Ferriere
 *
 * This is an internal module of the mm74hc595 Serial-In Parallel-Out (SIPO) driver.
 * Do not wire to this -- use MM74HC595C instead.
 *
 */
generic module MM74HC595P(uint8_t outaddr) 
{
  provides interface GeneralIO;
  uses async command void set(uint8_t pin);
  uses async command bool get(uint8_t pin);
  uses async command void clr(uint8_t pin);
  uses async command void toggle(uint8_t pin);

}

implementation
{
  async command void GeneralIO.set() {
    call set(outaddr);
  }
  async command bool GeneralIO.get() {
    return call get(outaddr);
  }
  async command void GeneralIO.clr() {
    call clr(outaddr);
  }
  async command void GeneralIO.toggle() {
    call toggle(outaddr);
  }
  async command void GeneralIO.makeInput() {
  }
  async command void GeneralIO.makeOutput() {
  }

  async command bool GeneralIO.isInput() {
  }
  async command bool GeneralIO.isOutput() {
  }

}  
