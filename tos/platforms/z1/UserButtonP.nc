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
 * Implementation of the user button for the telosb platform
 *
 * @author Gilman Tolle <gtolle@archrock.com>
 * @version $Revision: 1.2 $
 */

#include <UserButton.h>

module UserButtonP {
  provides interface Get<button_state_t>;
  provides interface Notify<button_state_t>;

  uses interface Get<bool> as GetLower;
  uses interface Notify<bool> as NotifyLower;
}
implementation {
  
  command button_state_t Get.get() { 
    // telosb user button pin is high when released - invert state
    if ( call GetLower.get() ) {
      return BUTTON_RELEASED;
    } else {
      return BUTTON_PRESSED;
    }
  }

  command error_t Notify.enable() {
    return call NotifyLower.enable();
  }

  command error_t Notify.disable() {
    return call NotifyLower.disable();
  }

  event void NotifyLower.notify( bool val ) {
    // telosb user button pin is high when released - invert state
    if ( val ) {
      signal Notify.notify( BUTTON_RELEASED );
    } else {
      signal Notify.notify( BUTTON_PRESSED );
    }
  }
  
  default event void Notify.notify( button_state_t val ) { }
}
