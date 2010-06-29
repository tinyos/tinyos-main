/// $Id: TempP.nc,v 1.5 2010-06-29 22:07:54 scipio Exp $

/*
 * Copyright (c) 2004-2005 Crossbow Technology, Inc.  All rights reserved.
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
 * - Neither the name of Crossbow Technology nor the names of
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
 * Internal component for temp sensor reading.
 *
 * @author Hu Siquan <husq@xbow.com>
 * @author David Gay
 */

module TempP {
  provides {
    interface ResourceConfigure;
    interface Atm128AdcConfig as TempConfig;
  }
  uses {
    interface GeneralIO as BatMon;
    interface GeneralIO as BatMonRef;
  }
}
implementation {
  async command uint8_t TempConfig.getChannel() {
    return CHANNEL_BATTERY_THERMISTOR;
  }

  async command uint8_t TempConfig.getRefVoltage() {
    return ATM128_ADC_VREF_OFF;
  }

  async command uint8_t TempConfig.getPrescaler() {
    return ATM128_ADC_PRESCALE;
  }

  async command void ResourceConfigure.configure() {
    call BatMonRef.makeOutput();
    call BatMonRef.set();
    call BatMon.makeOutput();
    call BatMon.clr();
  }

  async command void ResourceConfigure.unconfigure() {
    call BatMon.makeInput();
    call BatMonRef.makeInput();
  }
}
