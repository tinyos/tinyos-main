/*
* Copyright (c) 2009 Johns Hopkins University.
* Copyright (c) 2010 CSIRO Australia
* All rights reserved.
*
* Permission to use, copy, modify, and distribute this software and its
* documentation for any purpose, without fee, and without written
* agreement is hereby granted, provided that the above copyright
* notice, the (updated) modification history and the author appear in
* all copies of this source code.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS  `AS IS'
* AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED  TO, THE
* IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR  PURPOSE
* ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR  CONTRIBUTORS
* BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
* CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, LOSS OF USE,  DATA,
* OR PROFITS) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
* CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR  OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
* THE POSSIBILITY OF SUCH DAMAGE.
*/

/**
 * @author JeongGil Ko
 * @author Kevin Klues
 */

configuration HplSam3uTwiP {
  provides interface HplSam3uTwi as HplSam3uTwi0;
  provides interface HplSam3uTwi as HplSam3uTwi1;
  provides interface HplSam3uTwiInterrupt as HplSam3uTwiInterrupt0;
  provides interface HplSam3uTwiInterrupt as HplSam3uTwiInterrupt1;
}

implementation {

  components HplSam3uTwiImplP as HplTwiP;
  HplSam3uTwi0 = HplTwiP.HplSam3uTwi0;
  HplSam3uTwi1 = HplTwiP.HplSam3uTwi1;
  HplSam3uTwiInterrupt0 = HplTwiP.Interrupt0;
  HplSam3uTwiInterrupt1 = HplTwiP.Interrupt1;

  // make and connect pins/clock/interrupt for this dude
  components HplNVICC, HplSam3uClockC, HplSam3uGeneralIOC, LedsC, NoLedsC;
  HplTwiP.Twi0Interrupt -> HplNVICC.TWI0Interrupt;
  HplTwiP.Twi1Interrupt -> HplNVICC.TWI1Interrupt;
  HplTwiP.Twi0ClockControl -> HplSam3uClockC.TWI0PPCntl;
  HplTwiP.Twi1ClockControl -> HplSam3uClockC.TWI1PPCntl;
  HplTwiP.Twd0Pin -> HplSam3uGeneralIOC.HplPioA9;
  HplTwiP.Twd1Pin -> HplSam3uGeneralIOC.HplPioA24;
  HplTwiP.Twck0Pin -> HplSam3uGeneralIOC.HplPioA10;
  HplTwiP.Twck1Pin -> HplSam3uGeneralIOC.HplPioA25;
  HplTwiP.Leds -> NoLedsC;  

  components McuSleepC;
  HplTwiP.Twi0InterruptWrapper -> McuSleepC;
  HplTwiP.Twi1InterruptWrapper -> McuSleepC;
}
