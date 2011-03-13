/**
 *  Copyright (c) 2005-2006 Crossbow Technology, Inc.
 *  All rights reserved.
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
 *
 *  @author Hu Siquan <husq@xbow.com>
 *
 *  $Id: MicDeviceP.nc,v 1.2 2010-07-21 13:23:50 zkincses Exp $
 */

#include "mts300.h"
#include "I2C.h"
configuration MicDeviceP {
  provides {
    interface Resource[uint8_t client];
    interface Atm128AdcConfig;
    interface MicSetting;
  }
}
implementation {
  components MicP, MicaBusC, 
    new Atm128I2CMasterC() as I2CPot,
    new TimerMilliC() as WarmupTimer,
    new RoundRobinArbiterC(UQ_MIC_RESOURCE) as Arbiter,
    new SplitControlPowerManagerC() as PowerManager;

  Resource = Arbiter;
  Atm128AdcConfig = MicP;
  MicSetting = MicP;
	
  PowerManager.ResourceDefaultOwner -> Arbiter;
  PowerManager.ArbiterInfo -> Arbiter;
  PowerManager.SplitControl -> MicP;

  MicP.Timer -> WarmupTimer;
  MicP.MicPower  -> MicaBusC.PW3;
  MicP.MicMuxSel -> MicaBusC.PW6;
  MicP.InterruptPin -> MicaBusC.Int3;
  MicP.MicAdc -> MicaBusC.Adc2;
  MicP.I2CPacket -> I2CPot;
  MicP.I2CResource -> I2CPot;
  MicP.AlertInterrupt -> MicaBusC.Int3_Interrupt;
}
