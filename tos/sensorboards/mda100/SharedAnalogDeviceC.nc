/*
 * Copyright (c) 2007 Stanford University.
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
 * - Neither the name of the Stanford University nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL STANFORD
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * @author Kevin Klues <klueska@cs.stanford.edu>
 * @date August 20th, 2007
 */

generic configuration SharedAnalogDeviceC(char resourceName[], uint32_t startup_delay) {
  provides {
    interface Resource[uint8_t];
    interface Read<uint16_t>[uint8_t];
  }
  uses {
    interface Atm128AdcConfig as AdcConfig;
    interface GeneralIO as EnablePin;
  } 
}
implementation {
  components new RoundRobinArbiterC(resourceName) as Arbiter;
  components new SplitControlPowerManagerC() as PowerManager;
  components new SharedAnalogDeviceP(startup_delay) as AnalogDevice;
  components new AdcReadNowClientC() as Adc;
  components new TimerMilliC();
  Resource = Arbiter;
  Read = AnalogDevice;

  PowerManager.ArbiterInfo -> Arbiter;
  PowerManager.SplitControl -> AnalogDevice;
  PowerManager.ResourceDefaultOwner -> Arbiter;
  AnalogDevice.ActualRead -> Adc;
  AnalogDevice.Timer -> TimerMilliC;
  AnalogDevice.AnalogDeviceResource -> Adc;

  Adc.Atm128AdcConfig = AdcConfig;
  AnalogDevice.EnablePin = EnablePin;
}
