/**
 * Copyright (c) 2007 Arch Rock Corporation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Arch Rock Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * ARCHED ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

/**
 * Generic layer to translate a GIO into a toggle switch
 *
 * @author Gilman Tolle <gtolle@archrock.com>
 * @version $Revision: 1.1 $
 *
 * @author Mike Healy
 * @date May 9, 2009 - modified for use with SHIMMER2
 */

#include <UserButton.h>

generic module SwitchToggleC() {
  provides interface Get<bool>;
  provides interface Notify<bool>;

  uses interface GeneralIO;
  uses interface GpioInterrupt;
}

implementation {
  norace bool m_pinHigh;

  task void sendEvent();

  command bool Get.get() { return call GeneralIO.get(); }

  command error_t Notify.enable() {
    call GeneralIO.makeInput();

    if ( call GeneralIO.get() ) {
      m_pinHigh = TRUE;
      return call GpioInterrupt.enableFallingEdge();
    } 
    else {
      m_pinHigh = FALSE;
      return call GpioInterrupt.enableRisingEdge();
    }
  }

  command error_t Notify.disable() {
    return call GpioInterrupt.disable();
  }

  async event void GpioInterrupt.fired() {
    call GpioInterrupt.disable();

    m_pinHigh = !m_pinHigh;

    post sendEvent();
  }

  task void sendEvent() {
    bool pinHigh;
    pinHigh = m_pinHigh;
    
    signal Notify.notify( pinHigh );
    
    if ( pinHigh ) {
      call GpioInterrupt.enableFallingEdge();
    } 
    else {
      call GpioInterrupt.enableRisingEdge();
    }
  }
}
