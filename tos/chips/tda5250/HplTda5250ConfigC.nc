/*
 * Copyright (c) 2004, Technische Universitat Berlin
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
 * - Neither the name of the Technische Universitat Berlin nor the names
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
 * - Revision -------------------------------------------------------------
 * $Revision: 1.3 $
 * $Date: 2006-11-07 19:31:15 $
 * ========================================================================
 */

 /**
 * Controlling the TDA5250 at the HPL layer.
 *
 * @author Kevin Klues (klues@tkn.tu-berlin.de)
 */

#include "tda5250Const.h"
#include "tda5250RegDefaultSettings.h"
#include "tda5250RegTypes.h"

configuration HplTda5250ConfigC {
  provides {
    interface Init;
    interface HplTda5250Config;
    interface Resource as Resource;
  }
}
implementation {
  components HplTda5250ConfigP
           , Tda5250RegistersC
           , Tda5250RadioIOC
           , Tda5250RadioInterruptC
           ;

  Init = HplTda5250ConfigP;
  Init = Tda5250RegistersC;
  Resource = Tda5250RegistersC.Resource;
  HplTda5250Config = HplTda5250ConfigP;

  HplTda5250ConfigP.CONFIG -> Tda5250RegistersC.CONFIG;
  HplTda5250ConfigP.FSK -> Tda5250RegistersC.FSK;
  HplTda5250ConfigP.XTAL_TUNING -> Tda5250RegistersC.XTAL_TUNING;
  HplTda5250ConfigP.LPF -> Tda5250RegistersC.LPF;
  HplTda5250ConfigP.ON_TIME -> Tda5250RegistersC.ON_TIME;
  HplTda5250ConfigP.OFF_TIME -> Tda5250RegistersC.OFF_TIME;
  HplTda5250ConfigP.COUNT_TH1 -> Tda5250RegistersC.COUNT_TH1;
  HplTda5250ConfigP.COUNT_TH2 -> Tda5250RegistersC.COUNT_TH2;
  HplTda5250ConfigP.RSSI_TH3 -> Tda5250RegistersC.RSSI_TH3;
  HplTda5250ConfigP.RF_POWER -> Tda5250RegistersC.RF_POWER;
  HplTda5250ConfigP.CLK_DIV -> Tda5250RegistersC.CLK_DIV;
  HplTda5250ConfigP.XTAL_CONFIG -> Tda5250RegistersC.XTAL_CONFIG;
  HplTda5250ConfigP.BLOCK_PD -> Tda5250RegistersC.BLOCK_PD;
  HplTda5250ConfigP.STATUS -> Tda5250RegistersC.STATUS;
  HplTda5250ConfigP.ADC -> Tda5250RegistersC.ADC;

  HplTda5250ConfigP.ASKNFSK -> Tda5250RadioIOC.Tda5250RadioPASKNFSK;
  HplTda5250ConfigP.PWDDD -> Tda5250RadioIOC.Tda5250RadioPWDDD;
  HplTda5250ConfigP.TXRX -> Tda5250RadioIOC.Tda5250RadioTXRX;
  HplTda5250ConfigP.PWDDDInterrupt -> Tda5250RadioInterruptC;
}
