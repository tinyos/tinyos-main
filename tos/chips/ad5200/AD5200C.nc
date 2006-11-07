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
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

/*
 * - Revision -------------------------------------------------------------
 * $Revision: 1.3 $
 * $Date: 2006-11-07 19:30:43 $
 * ========================================================================
 */

/**
 * There is currently no TEP for describing devices of this type.<br><br>
 *
 * This component provides the implementation of the ad5200 potentiometer
 * chip.  It is currently the only chip of its type, and does not conform to
 * any existing TEP standard.  This component will be updated as a TEP for
 * potentiometers is developed in the near future.
 *
 * @author Kevin Klues (klues@tkn.tu-berlin.de)
 */

configuration AD5200C {
provides {
  interface Pot;
  interface Resource;
  interface StdControl;
}
}

implementation {
  components AD5200P
      , AD5200SpiC
      , AD5200PotIO
      , MainC
      ;

      StdControl = AD5200P;
      Pot = AD5200P;
      Resource = AD5200SpiC;


      MainC.SoftwareInit-> AD5200P.Init;
      AD5200P.ENPOT -> AD5200PotIO.AD5200PotENPOT;
      AD5200P.SDPOT -> AD5200PotIO.AD5200PotSDPOT;
      AD5200P.SpiByte -> AD5200SpiC;
}
