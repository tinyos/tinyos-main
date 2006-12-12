/*
 * Copyright (c) 2004, Technische Universitaet Berlin
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
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES {} LOSS OF USE, DATA,
 * OR PROFITS {} OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Description ---------------------------------------------------------
 * Controlling the TDA5250 at the HPL layer for use with the MSP430 on the
 * eyesIFX platforms, Configuration.
 * - Revision -------------------------------------------------------------
 * $Revision: 1.4 $
 * $Date: 2006-12-12 18:23:41 $
 * @author: Kevin Klues (klues@tkn.tu-berlin.de)
 * ========================================================================
 */

#include "tda5250BusResourceSettings.h"

/**
 * Configuration file for the registers of TDA5250 Radio on
 * the eyesIFX platforms.
 *
 * @author Kevin Klues (klues@tkn.tu-berlin.de)
 */
configuration Tda5250RegCommC {
  provides {
    interface Init;
    interface Tda5250RegComm;
    interface Pot;
    interface Resource;
  }
}
implementation {
  components new Msp430Spi0C() as Spi
           , Tda5250RegCommP
           , Tda5250RadioIOC
           , AD5200P
           , AD5200PotIOC
           ;

  Init = Tda5250RegCommP;
  Init = AD5200P;
  Pot = AD5200P.Pot;
  Resource = Tda5250RegCommP.Resource;

  Tda5250RegComm = Tda5250RegCommP;

  Tda5250RegCommP.BusM -> Tda5250RadioIOC.Tda5250RadioBUSM;

  Tda5250RegCommP.SpiByte -> Spi;
  Tda5250RegCommP.SpiResource -> Spi;

  AD5200P.ENPOT -> AD5200PotIOC.AD5200PotENPOT;
  AD5200P.SDPOT -> AD5200PotIOC.AD5200PotSDPOT;
  AD5200P.SpiByte -> Spi;



}
