/*
* Copyright (c) 2009 Johns Hopkins University.
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
  Adc12bImpl.Adc12bInterruptWrapper -> McuSleepC;

#ifdef SAM3U_ADC12B_PDC
  components HplSam3uPdcC;
  Adc12bImpl.HplPdc -> HplSam3uPdcC.Adc12bPdcControl;
#endif


}
