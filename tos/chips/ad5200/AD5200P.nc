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
 * $Revision: 1.4 $
 * $Date: 2006-12-12 18:23:02 $
 * ========================================================================
 */

/**
 * There is currently no TEP for describing devices of this type.<br><br>
 *
 * This component provides the internal implementation of the ad5200 potentiometer
 * chip.  It is currently the only chip of its type, and does not conform to
 * any existing TEP standard.  This component will be updated as a TEP for
 * potentiometers is developed in the near future.
 *
 * @author Kevin Klues (klues@tkn.tu-berlin.de)
 */

  module AD5200P {
  provides {
    interface Init;
    interface Pot;
    interface StdControl;
  }
  uses {
    interface GeneralIO as ENPOT;
    interface GeneralIO as SDPOT;
    interface SpiByte;
  }
  }
  implementation {
    uint8_t Pot_value = -1;

    /************** interface commands **************/
    command error_t Init.init() {
      call ENPOT.makeOutput();
      call SDPOT.makeOutput();
      call ENPOT.set();
      call SDPOT.set();
      return SUCCESS;
    }

    command error_t StdControl.start() {
      call SDPOT.set();
      call ENPOT.set();
      return SUCCESS;
    }
    command error_t StdControl.stop() {
      call ENPOT.set();
      call SDPOT.clr();
      return SUCCESS;
    }

    async command error_t Pot.set(uint8_t setting) {
      call ENPOT.clr();
      call SpiByte.write(setting);
      call ENPOT.set();
      atomic Pot_value = setting;
      return SUCCESS;
    }

    async command uint8_t Pot.get() {
      return Pot_value;
    }

    async command error_t Pot.increase() {
      if (Pot_value < 255 && Pot_value >= 0) {
        Pot_value++;
        return call Pot.set(Pot_value);
      }
      else return FAIL;
    }

    async command error_t Pot.decrease() {
      if (Pot_value > 0) {
        Pot_value--;
        return call Pot.set(Pot_value);
      }
      else return FAIL;
    }
  }
