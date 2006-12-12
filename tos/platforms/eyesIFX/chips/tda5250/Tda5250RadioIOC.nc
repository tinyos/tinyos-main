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
 * $Revision: 1.4 $
 * $Date: 2006-12-12 18:23:41 $
 * ========================================================================
 */

 /**
 * Configuration file for using the IO pins to the TDA5250 Radio on
 * the eyesIFX platforms.
 *
 * @author Kevin Klues <klues@tkn.tu-berlin.de>
 */
configuration Tda5250RadioIOC
{
  provides interface GeneralIO as Tda5250RadioPASKNFSK;
  provides interface GeneralIO as Tda5250RadioBUSM;
  provides interface GeneralIO as Tda5250RadioENTDA;
  provides interface GeneralIO as Tda5250RadioTXRX;
  provides interface GeneralIO as Tda5250RadioDATA;
  provides interface GeneralIO as Tda5250RadioPWDDD;
}
implementation {
  components
      HplMsp430GeneralIOC as MspGeneralIO
    , Tda5250ASKNFSKFakePinP      
    , new Msp430GpioC() as rBUSM
    , new Msp430GpioC() as rENTDA
    , new Msp430GpioC() as rTXRX
    , new Msp430GpioC() as rDATA
    , new Msp430GpioC() as rPWDD
    ;

  Tda5250RadioBUSM = rBUSM;
  Tda5250RadioENTDA = rENTDA;
  Tda5250RadioTXRX = rTXRX;
  Tda5250RadioDATA = rDATA;
  Tda5250RadioPWDDD = rPWDD;

  Tda5250RadioPASKNFSK = Tda5250ASKNFSKFakePinP;
  rBUSM -> MspGeneralIO.Port15;
  rENTDA -> MspGeneralIO.Port16;
  rTXRX -> MspGeneralIO.Port14;
  rDATA -> MspGeneralIO.Port11;
  rPWDD -> MspGeneralIO.Port10;
}

