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
 * @author Thomas Schmid
 */

#include "sam3sadchardware.h"

configuration WireAdcStreamP {
  provides interface ReadStream<uint16_t>[uint8_t client];
  uses {
    interface AdcConfigure<const sam3s_adc_channel_config_t*>[uint8_t client];
    interface Sam3sGetAdc[uint8_t client];
    interface Resource[uint8_t client];
  }
}
implementation {
#ifndef SAM3S_ADC_PDC
  components AdcStreamP;
#else
  components AdcStreamPDCP as AdcStreamP;
#endif
  components MainC, new AlarmTMicro16C() as Alarm,
    new ArbitratedReadStreamC(uniqueCount(ADCC_READ_STREAM_SERVICE), uint16_t) as ArbitrateReadStream;

  ReadStream = ArbitrateReadStream;
  AdcConfigure = AdcStreamP;
  Resource = ArbitrateReadStream;

  ArbitrateReadStream.Service -> AdcStreamP;

#ifdef SAM3S_ADC_PDC
  components HplSam3sPdcC;
  AdcStreamP.HplPdc -> HplSam3sPdcC.AdcPdcControl;
#else
  AdcStreamP.Alarm -> Alarm;
#endif

  AdcStreamP.Init <- MainC;
  Sam3sGetAdc = AdcStreamP.GetAdc;

  components LedsC, NoLedsC;
  AdcStreamP.Leds -> LedsC;
}
