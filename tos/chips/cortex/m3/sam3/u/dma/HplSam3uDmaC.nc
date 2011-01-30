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

configuration HplSam3uDmaC {
  provides interface HplSam3uDmaControl as Control;
  provides interface HplSam3uDmaChannel as Channel0;
  provides interface HplSam3uDmaChannel as Channel1;
  provides interface HplSam3uDmaChannel as Channel2;
  provides interface HplSam3uDmaChannel as Channel3;
  provides interface HplSam3uDmaInterrupt as Interrupt;
}

implementation {

  components HplSam3uDmaP;
  components new HplSam3uDmaXP(0) as Dma0;
  components new HplSam3uDmaXP(1) as Dma1;
  components new HplSam3uDmaXP(2) as Dma2;
  components new HplSam3uDmaXP(3) as Dma3;
  components HplNVICC;
  components HplSam3uClockC;
  components LedsC;

  Control = HplSam3uDmaP;
  Channel0 = Dma0;
  Channel1 = Dma1;
  Channel2 = Dma2;
  Channel3 = Dma3;
  Interrupt = HplSam3uDmaP;

  Dma0.Interrupt -> HplSam3uDmaP;
  Dma1.Interrupt -> HplSam3uDmaP;
  Dma2.Interrupt -> HplSam3uDmaP;
  Dma3.Interrupt -> HplSam3uDmaP;
  Dma0.Leds -> LedsC;
  Dma1.Leds -> LedsC;
  Dma2.Leds -> LedsC;
  Dma3.Leds -> LedsC;

  HplSam3uDmaP.HDMAInterrupt -> HplNVICC.HDMAInterrupt;
  HplSam3uDmaP.HDMAClockControl -> HplSam3uClockC.HDMAPPCntl;
  HplSam3uDmaP.Leds -> LedsC;

  components McuSleepC;
  HplSam3uDmaP.DmacInterruptWrapper -> McuSleepC;
}

