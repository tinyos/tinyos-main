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
 * @author Moksha Birk <birk@tkn.tu-berlin.de>
 */

/**
 * TODO Module description
 */
module TknTschDebugHelperP
{
  provides {
    interface TknTschDebugHelperTssm as TssmHelper;
  }
  uses {
    interface Leds;
    interface GeneralIO as GpioSlotStart;
    interface GeneralIO as GpioSlotZero;
    interface GeneralIO as GpioPktPrepare;
    interface GeneralIO as GpioAlarmIrq;
    interface GeneralIO as GpioPhyIrq;
  }
}
implementation
{
  async command void TssmHelper.init()
  {
    call GpioSlotStart.makeOutput();
    call GpioSlotStart.clr();
    call GpioSlotZero.makeOutput();
    call GpioSlotZero.clr();
    call GpioPktPrepare.makeOutput();
    call GpioPktPrepare.clr();
    call GpioAlarmIrq.makeOutput();
    call GpioAlarmIrq.clr();
    call GpioPhyIrq.makeOutput();
    call GpioPhyIrq.clr();
  }

  async command void TssmHelper.setActiveSlotIndicator()
  {
    call Leds.led0On();
  }

  async command void TssmHelper.clearActiveSlotIndicator()
  {
    call Leds.led0Off();
  }

  async command void TssmHelper.setErrorIndicator()
  {
    call Leds.led1On();
  }

  async command void TssmHelper.startOfSlotStart()
  {
    call GpioSlotStart.set();
  }

  async command void TssmHelper.endOfSlotStart()
  {
    call GpioSlotStart.clr();
  }

  async command void TssmHelper.startOfSlotZero()
  {
    call GpioSlotZero.set();
  }

  async command void TssmHelper.endOfSlotZero()
  {
    call GpioSlotZero.clr();
  }

  async command void TssmHelper.startOfPacketPrepare()
  {
    call GpioPktPrepare.set();
  }

  async command void TssmHelper.endOfPacketPrepare()
  {
    call GpioPktPrepare.clr();
  }

  async command void TssmHelper.startOfPhyIrq()
  {
    call GpioPhyIrq.set();
  }

  async command void TssmHelper.endOfPhyIrq()
  {
    call GpioPhyIrq.clr();
  }

  async command void TssmHelper.startOfAlarmIrq()
  {
    call GpioAlarmIrq.set();
  }

  async command void TssmHelper.endOfAlarmIrq()
  {
    call GpioAlarmIrq.clr();
  }

}
