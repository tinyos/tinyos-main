/// $Id: Atm128AdcC.nc,v 1.7 2010-06-29 22:07:43 scipio Exp $

/*
 * Copyright (c) 2004-2005 Crossbow Technology, Inc.  All rights reserved.
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
 * - Neither the name of Crossbow Technology nor the names of
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
 * Copyright (c) 2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

#include "Atm128Adc.h"

/**
 * HAL for the Atmega128 A/D conversion susbsystem.
 *
 * @author Hu Siquan <husq@xbow.com>
 * @author David Gay
 */

configuration Atm128AdcC
{
  provides {
    interface Resource[uint8_t client];
    interface Atm128AdcSingle;
    interface Atm128AdcMultiple;
  }
  uses interface ResourceConfigure[uint8_t client];
}
implementation
{
  components Atm128AdcP, HplAtm128AdcC, PlatformC, MainC,
    new RoundRobinArbiterC(UQ_ATM128ADC_RESOURCE) as AdcArbiter,
    new AsyncStdControlPowerManagerC() as PM;

  Resource = AdcArbiter;
  ResourceConfigure = AdcArbiter;
  Atm128AdcSingle = Atm128AdcP;
  Atm128AdcMultiple = Atm128AdcP;

  PlatformC.SubInit -> Atm128AdcP;

  Atm128AdcP.HplAtm128Adc -> HplAtm128AdcC;
  Atm128AdcP.Atm128Calibrate -> PlatformC;

  PM.AsyncStdControl -> Atm128AdcP;
  PM.ResourceDefaultOwner -> AdcArbiter;
}
