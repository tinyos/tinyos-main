/*
 * Copyright (c) 2011 Lulea University of Technology
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

/**
 * Implementation of the time capture on RF230 interrupt and
 * a initialization routine for the RF230 pins.
 *
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 */

module HplRF230P
{
  provides
  {
    interface GpioCapture as IRQ;
    interface Init as PlatformInit;
  }

  uses
  {
    interface GeneralIO as PortIRQ;
    interface GeneralIO as PortVCC;
    interface GeneralIO as MOSI;
    interface GeneralIO as MISO;
    interface GeneralIO as SCLK;
    interface GpioInterrupt as GIRQ;
    interface Alarm<TRadio, uint16_t> as Alarm;
  }
}
implementation
{
  command error_t PlatformInit.init()
  {
    call MISO.makeInput();
    call MOSI.makeOutput();
    call MOSI.clr();
    call SCLK.makeOutput();
    call SCLK.clr();
    call PortIRQ.makeInput(); 
    call PortIRQ.clr();
    call GIRQ.disable();
    call PortVCC.makeOutput(); 
    call PortVCC.set(); 

    return SUCCESS;
  }

  async event void GIRQ.fired()
  {
    signal IRQ.captured(call Alarm.getNow());
  }
  async event void Alarm.fired() {}

  default async event void IRQ.captured(uint16_t time) {}

  async command error_t IRQ.captureRisingEdge()
  {
    call GIRQ.enableRisingEdge();
    return SUCCESS;
  }

  async command error_t IRQ.captureFallingEdge()
  {
    // falling edge comes when the IRQ_STATUS register of the RF230 is read
    return FAIL;
  }

  async command void IRQ.disable()
  {
    call GIRQ.disable();
  }
}
