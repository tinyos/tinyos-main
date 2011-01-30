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

configuration WireAdcStreamP {
  provides interface ReadStream<uint16_t>[uint8_t client];
  uses {
    interface AdcConfigure<const sam3u_adc12_channel_config_t*>[uint8_t client];
    interface Sam3uGetAdc12b[uint8_t client];
    interface Resource[uint8_t client];
  }
}
implementation {
#ifndef SAM3U_ADC12B_PDC
  components AdcStreamP;
#else
  components AdcStreamPDCP as AdcStreamP;
#endif
  components MainC, new AlarmTMicro32C() as Alarm,
    new ArbitratedReadStreamC(uniqueCount(ADCC_READ_STREAM_SERVICE), uint16_t) as ArbitrateReadStream;

  ReadStream = ArbitrateReadStream;
  AdcConfigure = AdcStreamP;
  Resource = ArbitrateReadStream;

  ArbitrateReadStream.Service -> AdcStreamP;

#ifdef SAM3U_ADC12B_PDC
  components HplSam3uPdcC;
  AdcStreamP.HplPdc -> HplSam3uPdcC.Adc12bPdcControl;
#else
  AdcStreamP.Alarm -> Alarm;
#endif

  AdcStreamP.Init <- MainC;
  Sam3uGetAdc12b = AdcStreamP.GetAdc;

  components LedsC, NoLedsC;
  AdcStreamP.Leds -> LedsC;
}
