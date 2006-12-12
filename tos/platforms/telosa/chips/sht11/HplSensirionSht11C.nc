/*
 * Copyright (c) 2005-2006 Arch Rock Corporation
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
 * HplSensirionSht11C is a low-level component, intended to provide
 * the physical resources used by the Sensirion SHT11 sensor on the
 * telosb platform so that the chip driver can make use of them. You
 * really shouldn't be wiring to this, unless you're writing a new
 * Sensirion SHT11 driver.
 *
 * @author Gilman Tolle <gtolle@archrock.com>
 * @version $Revision: 1.4 $ $Date: 2006-12-12 18:23:45 $
 */

configuration HplSensirionSht11C {
  provides interface Resource[ uint8_t id ];
  provides interface GeneralIO as DATA;
  provides interface GeneralIO as SCK;
  provides interface GpioInterrupt as InterruptDATA;
}
implementation {
  components HplMsp430GeneralIOC;
  
  components new Msp430GpioC() as DATAM;
  components new Msp430GpioC() as SCKM;
  components new Msp430GpioC() as PWRM;

  DATAM -> HplMsp430GeneralIOC.Port15;
  SCKM -> HplMsp430GeneralIOC.Port16;
  PWRM -> HplMsp430GeneralIOC.Port17;

  DATA = DATAM;
  SCK = SCKM;

  components HplSensirionSht11P;
  HplSensirionSht11P.PWR -> PWRM;
  HplSensirionSht11P.DATA -> DATAM;
  HplSensirionSht11P.SCK -> SCKM;

  components new TimerMilliC();
  HplSensirionSht11P.Timer -> TimerMilliC;

  components HplMsp430InterruptC;
  components new Msp430InterruptC() as InterruptDATAC;
  InterruptDATAC.HplInterrupt -> HplMsp430InterruptC.Port15;
  InterruptDATA = InterruptDATAC.Interrupt;

  components new FcfsArbiterC( "Sht11.Resource" ) as Arbiter;
  Resource = Arbiter;
  
  components new SplitControlPowerManagerC();
  SplitControlPowerManagerC.SplitControl -> HplSensirionSht11P;
  SplitControlPowerManagerC.ArbiterInit -> Arbiter.Init;
  SplitControlPowerManagerC.ArbiterInfo -> Arbiter.ArbiterInfo;
  SplitControlPowerManagerC.ResourceController -> Arbiter.ResourceController;
}
