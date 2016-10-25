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

#include "sam3uadc12bhardware.h"
 
configuration Sam3uAdc12bP 
{ 
  provides {
    interface Resource[uint8_t id]; 
    interface Sam3uGetAdc12b[uint8_t id]; 
  }
} 

implementation {
  components Sam3uAdc12bImplP as Adc12bImpl;
  components MainC;
  components HplNVICC, HplSam3uClockC, HplSam3uGeneralIOC;
  //components new Resource[uint8_t id];
  components new SimpleRoundRobinArbiterC(SAM3UADC12_RESOURCE) as Arbiter;

  Adc12bImpl.ADC12BInterrupt -> HplNVICC.ADC12BInterrupt;

  Adc12bImpl.Adc12bPin -> HplSam3uGeneralIOC.HplPioA2;
  Adc12bImpl.Adc12bClockControl -> HplSam3uClockC.ADC12BPPCntl;
  Resource = Arbiter; // set this!?!
  Sam3uGetAdc12b = Adc12bImpl.Sam3uAdc12b;

  MainC.SoftwareInit -> Adc12bImpl.Init;
  components LedsC, NoLedsC;
  Adc12bImpl.Leds -> NoLedsC;

  components McuSleepC;
  Adc12bImpl.McuSleep -> McuSleepC;

#ifdef SAM3U_ADC12B_PDC
  components HplSam3uPdcC;
  Adc12bImpl.HplPdc -> HplSam3uPdcC.Adc12bPdcControl;
#endif

}
