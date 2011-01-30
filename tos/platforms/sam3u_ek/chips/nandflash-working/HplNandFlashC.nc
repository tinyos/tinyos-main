/*
 * Copyright (c) 2010 Johns Hopkins University
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

configuration HplNandFlashC{
  provides interface HplNandFlash;

}
implementation{
  components HplNandFlashP;
  HplNandFlash = HplNandFlashP;

  components HplSam3uClockC;
  HplNandFlashP.HSMC4ClockControl -> HplSam3uClockC.HSMC4PPCntl;

  components HplSam3uGeneralIOC as IO;
  HplNandFlashP.NandFlash_CE -> IO.PioC12;
  HplNandFlashP.NandFlash_RB -> IO.PioB24;

  HplNandFlashP.NandFlash_OE -> IO.HplPioB17;
  HplNandFlashP.NandFlash_WE -> IO.HplPioB18;
  HplNandFlashP.NandFlash_CLE -> IO.HplPioB22;
  HplNandFlashP.NandFlash_ALE -> IO.HplPioB21;
  
  HplNandFlashP.NandFlash_Data00 -> IO.HplPioB9;
  HplNandFlashP.NandFlash_Data01 -> IO.HplPioB10;
  HplNandFlashP.NandFlash_Data02 -> IO.HplPioB11;
  HplNandFlashP.NandFlash_Data03 -> IO.HplPioB12;
  HplNandFlashP.NandFlash_Data04 -> IO.HplPioB13;
  HplNandFlashP.NandFlash_Data05 -> IO.HplPioB14;
  HplNandFlashP.NandFlash_Data06 -> IO.HplPioB15;
  HplNandFlashP.NandFlash_Data07 -> IO.HplPioB16;

  HplNandFlashP.NandFlash_Data08 -> IO.HplPioB25;
  HplNandFlashP.NandFlash_Data09 -> IO.HplPioB26;
  HplNandFlashP.NandFlash_Data10 -> IO.HplPioB27;
  HplNandFlashP.NandFlash_Data11 -> IO.HplPioB28;
  HplNandFlashP.NandFlash_Data12 -> IO.HplPioB29;
  HplNandFlashP.NandFlash_Data13 -> IO.HplPioB30;
  HplNandFlashP.NandFlash_Data14 -> IO.HplPioB31;
  HplNandFlashP.NandFlash_Data15 -> IO.HplPioB6;

  components LedsC, LcdC;
  HplNandFlashP.Leds -> LedsC;
  HplNandFlashP.Draw -> LcdC;

  components new TimerMilliC() as TimerC;
  HplNandFlashP.ReadBlockTimer -> TimerC;
}
