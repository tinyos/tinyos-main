/*
 * Copyright (c) 2010 Johns Hopkins University.
 * Copyright (c) 2010 CSIRO Australia
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
 * High Speed Multimedia Card Interface HPL Configurations.
 *
 * @author JeongGil Ko
 * @author Kevin Klues
 */

#include <sam3uhsmcihardware.h>

configuration HplSam3uHsmciC {
  provides {
    interface AsyncStdControl;
    interface HplSam3uHsmci;
  }
}
implementation {
  components HplSam3uHsmciP,
    HplNVICC, HplSam3uClockC, HplSam3uGeneralIOC;

  HplSam3uHsmci = HplSam3uHsmciP;
  AsyncStdControl = HplSam3uHsmciP;

  HplSam3uHsmciP.HSMCIInterrupt -> HplNVICC.MCI0Interrupt;
  HplSam3uHsmciP.HSMCIPinMCCDA -> HplSam3uGeneralIOC.HplPioA4;
  HplSam3uHsmciP.HSMCIPinMCCK -> HplSam3uGeneralIOC.HplPioA3;
  HplSam3uHsmciP.HSMCIPinMCDA0 -> HplSam3uGeneralIOC.HplPioA5;
  HplSam3uHsmciP.HSMCIPinMCDA1 -> HplSam3uGeneralIOC.HplPioA6;
  HplSam3uHsmciP.HSMCIPinMCDA2 -> HplSam3uGeneralIOC.HplPioA7;
  HplSam3uHsmciP.HSMCIPinMCDA3 -> HplSam3uGeneralIOC.HplPioA8;
  HplSam3uHsmciP.HSMCIPinMCDA4 -> HplSam3uGeneralIOC.HplPioC28;
  HplSam3uHsmciP.HSMCIPinMCDA5 -> HplSam3uGeneralIOC.HplPioC29;
  HplSam3uHsmciP.HSMCIPinMCDA6 -> HplSam3uGeneralIOC.HplPioC30;
  HplSam3uHsmciP.HSMCIPinMCDA7 -> HplSam3uGeneralIOC.HplPioC31;
  HplSam3uHsmciP.HSMCIClockControl -> HplSam3uClockC.MCI0PPCntl;

  components McuSleepC;
  HplSam3uHsmciP.HsmciInterruptWrapper -> McuSleepC;

  components PlatformHsmciConfigC;
  HplSam3uHsmciP.PlatformHsmciConfig -> PlatformHsmciConfigC;

  components BusyWaitMicroC;
  HplSam3uHsmciP.BusyWait -> BusyWaitMicroC;

  components LedsC;
  HplSam3uHsmciP.Leds -> LedsC;
}
