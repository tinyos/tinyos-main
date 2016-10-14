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
 * @author Moksha Birk <code@tkn.tu-berlin.de>
 */

/**
 * Mapping the special NXP JN516x USB Dongle LED behaviour to
 * normal GPIO behaviour
 *
 * NOTE set and clr seem to get switched somewhere !!!
 */
module PlatformLedsP {
  provides {
    interface GeneralIO as Led0;
    interface GeneralIO as Led1;
  }
  uses {
    interface Init;
    interface GeneralIO as Pin16;
    interface GeneralIO as Pin17;
  }
} implementation {
  bool d0 = FALSE;
  bool d1 = FALSE;

#define LED_0 call Pin16.set(); call Pin17.clr();
#define LED_1 call Pin16.clr(); call Pin17.set();
#define LED_OFF call Pin16.clr(); call Pin17.clr();

  async command void Led0.clr() {
    atomic d0 = TRUE;
    LED_0;
  }

  async command void Led0.set() {
    bool tmp;
    atomic {
      d0 = FALSE;
      tmp = d1;
    }
    if (tmp) {
      LED_1;
    }
    else {
      LED_OFF;
    }
  }

  async command void Led0.toggle() {
    bool tmp0, tmp1;
    atomic {
      d0 = !d0;
      tmp0 = d0;
      tmp1 = d1;
    }
    if (tmp0) {
      LED_0;
    }
    else if (tmp1) {
      LED_1;
    }
    else {
      LED_OFF;
    }
  }
  async command bool Led0.get() {
    return d0;
  }

  async command void Led1.clr() {
    atomic d1 = TRUE;
    LED_1;
  }

  async command void Led1.set() {
    bool tmp;
    atomic {
      d1 = FALSE;
      tmp = d0;
    }
    if (tmp) {
      LED_0;
    }
    else {
      LED_OFF;
    }
  }

  async command void Led1.toggle() {
    bool tmp0, tmp1;
    atomic {
      d1 = !d1;
      tmp0 = d0;
      tmp1 = d1;
    }
    if (tmp1) {
      LED_1;
    }
    else if (tmp0) {
      LED_0;
    }
    else {
      LED_OFF;
    }
  }
  async command bool Led1.get() {
    return d1;
  }

  async command void Led0.makeInput() {}
  async command bool Led0.isInput() { return FALSE; }
  async command void Led0.makeOutput() { call Pin16.makeOutput(); call Pin17.makeOutput(); };
  async command bool Led0.isOutput() { return TRUE; }

  async command void Led1.makeInput() {}
  async command bool Led1.isInput() { return FALSE; }
  async command void Led1.makeOutput() { call Pin16.makeOutput(); call Pin17.makeOutput(); };
  async command bool Led1.isOutput() { return TRUE; }
}
