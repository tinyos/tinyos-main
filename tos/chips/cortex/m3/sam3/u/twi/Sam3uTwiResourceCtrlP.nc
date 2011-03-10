/*
 * Copyright (c) 2009 Johns Hopkins University.
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
 * - Neither the name of the copyright holders nor the names of its
 *   contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
 * AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 * WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * @author JeongGil Ko
 */

#include "sam3utwihardware.h"
module Sam3uTwiResourceCtrlP{
  provides interface Resource[ uint8_t id ];
  uses interface Resource as TwiResource[ uint8_t id ];
  uses interface Leds;
}
implementation{

  async command error_t Resource.immediateRequest[ uint8_t id ]() {
    return call TwiResource.immediateRequest[ id ]();
  }

  async command error_t Resource.request[ uint8_t id ]() {
    return call TwiResource.request[ id ]();
  }

  async command bool Resource.isOwner[ uint8_t id ]() {
    return call TwiResource.isOwner[ id ]();
  }

  async command error_t Resource.release[ uint8_t id ]() {
    return call TwiResource.release[ id ]();
  }

  event void TwiResource.granted[ uint8_t id ]() {
    signal Resource.granted[ id ]();
  }

  default async command error_t TwiResource.request[ uint8_t id ]() { return FAIL; }
  default async command error_t TwiResource.immediateRequest[ uint8_t id ]() { return FAIL; }
  default async command error_t TwiResource.release[ uint8_t id ]() {return FAIL;}
  default event void Resource.granted[ uint8_t id ]() {}
}
