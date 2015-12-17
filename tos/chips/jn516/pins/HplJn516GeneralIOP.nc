/**
 * Copyright (c) 2015, Technische Universitaet Berlin
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
 * - Neither the name of the Technische Universitaet Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * @author Tim Bormann <code@tkn.tu-berlin.de>
 * @author Sanjeet Raj Pandey <code@tkn.tu-berlin.de>
 * @author Moksha Birk <code@tkn.tu-berlin.de>
 */

#include <AppHardwareApi.h>

generic module HplJn516GeneralIOP(uint8_t pin)
{
  provides interface HplJn516GeneralIO as IO;
}
implementation
{
  bool output;

  async command void IO.set() {
    vAHI_DioSetOutput(1 << pin, 0);
  }

  async command void IO.clr() {
    vAHI_DioSetOutput(0, 1 << pin);
  }

  async command void IO.toggle() {
    atomic {
      if (output) {
        if (call IO.get())
          call IO.clr();
        else
          call IO.set();
      }
    }
  }

  async command bool IO.get() {
    uint32_t dio = u32AHI_DioReadInput();
    if ((1 << pin) & dio)
      return TRUE;
    else
      return FALSE;
  }

  async command void IO.makeInput() {
    output = FALSE;
    vAHI_DioSetDirection(1 << pin, 0);
  }

  async command bool IO.isInput() { atomic return !output; }

  async command void IO.makeOutput() {
    atomic output = TRUE;
    vAHI_DioSetDirection(0, 1 << pin);
  }

  async command bool IO.isOutput() { atomic return output; }
}
