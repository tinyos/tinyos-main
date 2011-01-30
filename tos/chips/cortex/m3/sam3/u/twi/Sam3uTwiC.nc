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

#include "sam3utwihardware.h"

configuration Sam3uTwiC{
  provides interface Resource;
  provides interface ResourceRequested;
  provides interface I2CPacket<TI2CBasicAddr> as TwiBasicAddr0;
  provides interface I2CPacket<TI2CBasicAddr> as TwiBasicAddr1;
  provides interface ResourceConfigure as Configure0[ uint8_t id ];
  provides interface ResourceConfigure as Configure1[ uint8_t id ];
  provides interface Sam3uTwiInternalAddress as InternalAddress0;
  provides interface Sam3uTwiInternalAddress as InternalAddress1;
  uses interface Sam3uTwiConfigure as TwiConfig0;
  uses interface Sam3uTwiConfigure as TwiConfig1;
}
implementation{

  enum {
    CLIENT_ID = unique( SAM3U_TWI_BUS ),
  };

  components Sam3uTwiResourceCtrlC as ResourceCtrl;
  components HplSam3uTwiResourceCtrlC;
  Resource = ResourceCtrl.Resource[ CLIENT_ID ];
  ResourceRequested = HplSam3uTwiResourceCtrlC;
  ResourceCtrl.TwiResource[ CLIENT_ID ] -> HplSam3uTwiResourceCtrlC;

#ifdef SAM3U_TWI_PDC
  components new Sam3uTwiPDCP(0) as TwiP0;
  components new Sam3uTwiPDCP(1) as TwiP1;
  components HplSam3uPdcC;
  TwiP0.HplPdc -> HplSam3uPdcC.Twi0PdcControl;
  TwiP1.HplPdc -> HplSam3uPdcC.Twi1PdcControl;
#else
  components new Sam3uTwiP() as TwiP0;
  components new Sam3uTwiP() as TwiP1;
#endif
  TwiBasicAddr0 = TwiP0.TwiBasicAddr;
  TwiBasicAddr1 = TwiP1.TwiBasicAddr;
  TwiConfig0 = TwiP0.Sam3uTwiConfigure[ CLIENT_ID ];
  TwiConfig1 = TwiP1.Sam3uTwiConfigure[ CLIENT_ID ];
  InternalAddress0 = TwiP0.InternalAddr;
  InternalAddress1 = TwiP1.InternalAddr;
  Configure0 = TwiP0.ResourceConfigure;
  Configure1 = TwiP1.ResourceConfigure;
  TwiP0.ResourceConfigure[ CLIENT_ID ] <- HplSam3uTwiResourceCtrlC.ResourceConfigure;
  TwiP1.ResourceConfigure[ CLIENT_ID ] <- HplSam3uTwiResourceCtrlC.ResourceConfigure;

  components HplSam3uTwiC as HplTwiC;
  TwiP0.TwiInterrupt -> HplTwiC.HplSam3uTwiInterrupt0;
  TwiP1.TwiInterrupt -> HplTwiC.HplSam3uTwiInterrupt1;
  TwiP0.HplTwi -> HplTwiC.HplSam3uTwi0;
  TwiP1.HplTwi -> HplTwiC.HplSam3uTwi1;

  components BusyWaitMicroC;
  TwiP0.BusyWait -> BusyWaitMicroC;
  TwiP1.BusyWait -> BusyWaitMicroC;

  components new AlarmTMicro16C() as Alarm0;
  components new AlarmTMicro16C() as Alarm1;
  TwiP0.Alarm -> Alarm0;
  TwiP1.Alarm -> Alarm1;

  components LedsC;
  TwiP0.Leds -> LedsC;
  TwiP1.Leds -> LedsC;
}
