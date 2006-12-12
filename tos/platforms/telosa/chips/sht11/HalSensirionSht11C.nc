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
 * HalSensirionSht11C is an advanced access component for the
 * Sensirion SHT11 model humidity and temperature sensor, available on
 * the telosb platform. This component provides the SensirionSht11
 * interface, which offers full control over the device. Please
 * acquire the Resource before using it.
 *
 * @author Gilman Tolle <gtolle@archrock.com>
 * @version $Revision: 1.4 $ $Date: 2006-12-12 18:23:45 $
 */

configuration HalSensirionSht11C {
  provides interface Resource[ uint8_t client ];
  provides interface SensirionSht11[ uint8_t client ];
}
implementation {
  components new SensirionSht11LogicP();
  SensirionSht11 = SensirionSht11LogicP;

  components HplSensirionSht11C;
  Resource = HplSensirionSht11C.Resource;
  SensirionSht11LogicP.DATA -> HplSensirionSht11C.DATA;
  SensirionSht11LogicP.CLOCK -> HplSensirionSht11C.SCK;
  SensirionSht11LogicP.InterruptDATA -> HplSensirionSht11C.InterruptDATA;
  
  components new TimerMilliC();
  SensirionSht11LogicP.Timer -> TimerMilliC;

  components LedsC;
  SensirionSht11LogicP.Leds -> LedsC;
}
