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
 * $Revision: 1.7 $
 * $Date: 2008-06-17 16:53:50 $
 * ========================================================================
 */

 /**
 * Controlling the Tda5250 at the Hpl layer.
 *
 * @author Kevin Klues (klues@tkn.tu-berlin.de)
 */

#include "tda5250Const.h"
#include "tda5250RegDefaultSettings.h"
#include "tda5250RegTypes.h"
configuration Tda5250RadioC {
  provides {
    interface SplitControl;
    interface Tda5250Control;
    interface ResourceRequested;
    interface RadioByteComm;
    interface ClkDiv;
  }
}
implementation {
  components Tda5250RadioP
           , HplTda5250ConfigC
           , HplTda5250DataC
           , new Alarm32khz16C() as DelayTimer
           , MainC;

  MainC.SoftwareInit -> HplTda5250ConfigC;
  MainC.SoftwareInit -> HplTda5250DataC;
  MainC.SoftwareInit -> Tda5250RadioP;
           
  Tda5250Control = Tda5250RadioP;
  ResourceRequested = Tda5250RadioP;
  RadioByteComm = Tda5250RadioP;
  SplitControl = Tda5250RadioP;
  ClkDiv = Tda5250RadioP;

  Tda5250RadioP.DelayTimer -> DelayTimer;
  
  Tda5250RadioP.ConfigResource -> HplTda5250ConfigC;
  Tda5250RadioP.DataResource -> HplTda5250DataC;
  Tda5250RadioP.DataResourceRequested -> HplTda5250DataC;
  
  Tda5250RadioP.HplTda5250Config -> HplTda5250ConfigC;
  Tda5250RadioP.HplTda5250Data -> HplTda5250DataC;
  Tda5250RadioP.HplTda5250DataControl -> HplTda5250DataC;

}
