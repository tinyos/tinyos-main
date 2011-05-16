/*
 * Copyright (c) 2008, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Revision -------------------------------------------------------------
 * $Revision: 1.2 $
 * $Date: 2009-03-04 18:31:07 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

#include "Timer62500hz.h"
configuration CC2420TKN154C
{
  provides
  {
    interface SplitControl;
    interface RadioRx;
    interface RadioTx;
    interface SlottedCsmaCa;
    interface UnslottedCsmaCa;
    interface EnergyDetection;
    interface RadioOff;
    interface Set<bool> as RadioPromiscuousMode;
    interface Timestamp;
    interface GetNow<bool> as CCA;
  } uses {
    interface Notify<const void*> as PIBUpdate[uint8_t attributeID];
    interface LocalTime<T62500hz>;
    interface Alarm<T62500hz,uint32_t> as Alarm1;
    interface Alarm<T62500hz,uint32_t> as Alarm2;
    interface FrameUtility;
    interface ReliableWait;
    interface TimeCalc;
    interface Random;
    interface CaptureTime;
  }
} implementation {

  components MainC, CC2420TKN154P as PHY;

  SplitControl = PHY;
  RadioRx = PHY;
  RadioTx = PHY;
  SlottedCsmaCa = PHY;
  UnslottedCsmaCa = PHY;
  RadioOff = PHY;
  EnergyDetection = PHY;
  PIBUpdate = PHY;
  RadioPromiscuousMode = PHY;
  Timestamp = PHY;
  LocalTime = PHY;
  ReliableWait = PHY;
  TimeCalc = PHY;
  CCA = PHY;

  PHY.Random = Random;

  components CC2420ControlTransmitC;
  PHY.SpiResource -> CC2420ControlTransmitC;
  PHY.CC2420Power -> CC2420ControlTransmitC;
  PHY.CC2420Config -> CC2420ControlTransmitC;
  CC2420ControlTransmitC.StartupAlarm = Alarm2;
  FrameUtility = CC2420ControlTransmitC;
  CaptureTime = CC2420ControlTransmitC;

  PHY.TxControl -> CC2420ControlTransmitC;
  PHY.CC2420Tx -> CC2420ControlTransmitC;
  CC2420ControlTransmitC.AckAlarm = Alarm1;

  components CC2420ReceiveC;
  PHY.RxControl -> CC2420ReceiveC;
  PHY.CC2420Rx -> CC2420ReceiveC.CC2420Rx;
  FrameUtility = CC2420ReceiveC;
  CC2420ReceiveC.CC2420Config -> CC2420ControlTransmitC;
}

