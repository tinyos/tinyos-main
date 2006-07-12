/* 
 * Copyright (c) 2006, Ecole Polytechnique Federale de Lausanne (EPFL),
 * Switzerland.
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
 * - Neither the name of the Ecole Polytechnique Federale de Lausanne (EPFL) 
 *   nor the names of its contributors may be used to 
 *   endorse or promote products derived from this software without 
 *   specific prior written permission.
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
 * ========================================================================
 */

/*
 * @author Henri Dubois-Ferriere
 *
 */


module XE1205PhySwitchP {
  
  provides interface XE1205PhySwitch;
  provides interface Init @atleastonce();

  uses interface GeneralIO as AntSelTXPin;
  uses interface GeneralIO as AntSelRXPin;
  uses interface GeneralIO as DataPin; // only used in continuous mode, not currently supported
  uses interface GeneralIO as ModeSel0Pin;
  uses interface GeneralIO as ModeSel1Pin;
  uses interface GeneralIO as Irq0Pin;
  uses interface GeneralIO as Irq1Pin;
}
implementation {

  command error_t Init.init() {
    call ModeSel0Pin.makeOutput();
    call ModeSel1Pin.makeOutput();
    call AntSelTXPin.makeOutput();
    call AntSelRXPin.makeOutput();
    call DataPin.makeOutput();
    call XE1205PhySwitch.standbyMode();
    return SUCCESS;
  }

  async command void XE1205PhySwitch.sleepMode() { 
    call ModeSel0Pin.clr();
    call ModeSel1Pin.clr();
    call Irq0Pin.makeOutput();
    call Irq1Pin.makeOutput();
    call DataPin.makeOutput();
  }

  async command void XE1205PhySwitch.standbyMode() { 
    call ModeSel0Pin.set();
    call ModeSel1Pin.set();
    call Irq0Pin.makeOutput();
    call Irq1Pin.makeOutput();
    call DataPin.makeOutput();
  }

  async command void XE1205PhySwitch.rxMode() {
    call Irq0Pin.makeInput();
    call Irq1Pin.makeInput();
    call DataPin.makeInput();

    call ModeSel0Pin.set();
    call ModeSel1Pin.clr();

  }

  async command void XE1205PhySwitch.txMode() {
    call Irq0Pin.makeInput();
    call Irq1Pin.makeInput();
    call DataPin.makeOutput();
    call ModeSel1Pin.set();
    call ModeSel0Pin.clr();
  }

  async command void XE1205PhySwitch.antennaOff() { 
    call AntSelRXPin.clr();
    call AntSelTXPin.clr();
  }

  async command void XE1205PhySwitch.antennaRx() {
    call AntSelRXPin.set();
    call AntSelTXPin.clr();
  }
        
  async command void XE1205PhySwitch.antennaTx() {
    call AntSelRXPin.clr();
    call AntSelTXPin.set();
  }

}
