/* Copyright (c) 2000-2003 The Regents of the University of California.  
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
 * - Neither the name of the copyright holder nor the names of
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

/**
 * Andew's timer debouce logic used from the CountInput application.
 *
 * @author Cory Sharp <cssharp@eecs.berkeley.edu>
 * @author Andrew Redfern <aredfern@kingkong.me.berkeley.edu>
 */

module UserButtonP
{
  provides {
    interface Init;
    interface UserButton;
  }
  uses {
    interface HplMsp430GeneralIO;
    interface HplMsp430Interrupt;
    interface Timer<TMilli>;
  }
}
implementation
{
  command error_t Init.init()
  {
    atomic {
      call HplMsp430Interrupt.disable();
      call HplMsp430GeneralIO.makeInput();
      call HplMsp430GeneralIO.selectIOFunc();
      call HplMsp430Interrupt.edge(TRUE);
      call HplMsp430Interrupt.clear();
      call HplMsp430Interrupt.enable();
    }
    return SUCCESS;
  }

  event void Timer.fired()
  {
    atomic {
      call HplMsp430Interrupt.clear();
      call HplMsp430Interrupt.enable();
    }
  }

  task void debounce()
  {
    call Timer.startOneShot(100);
    signal UserButton.fired();
  }

  async event void HplMsp430Interrupt.fired()
  {
    atomic {
      call HplMsp430Interrupt.disable();
      post debounce();
    }
  }
}

