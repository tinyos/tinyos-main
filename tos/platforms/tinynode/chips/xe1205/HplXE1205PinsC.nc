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
 * HPL implementation of general-purpose I/O for the Semtech XE1205
 * radio connected to a TI MSP430 processor on a tinynode platform.
 *
 * @author Henri Dubois-Ferriere
 */


configuration HplXE1205PinsC {

  provides interface GeneralIO as Irq0Pin      @atmostonce();
  provides interface GeneralIO as Irq1Pin      @atmostonce();
  provides interface GeneralIO as AntSelTXPin  @atmostonce();
  provides interface GeneralIO as AntSelRXPin  @atmostonce();
  provides interface GeneralIO as DataPin      @atmostonce();
  provides interface GeneralIO as ModeSel0Pin  @atmostonce();
  provides interface GeneralIO as ModeSel1Pin  @atmostonce();
  provides interface GeneralIO as NssDataPin   @atmostonce();
  provides interface GeneralIO as NssConfigPin @atmostonce();
}

implementation {

  components HplMsp430GeneralIOC;
  components new Msp430GpioC() as Irq0PinM;
  components new Msp430GpioC() as Irq1PinM;
  components new Msp430GpioC() as AntSelTXM;
  components new Msp430GpioC() as AntSelRXM;
  components new Msp430GpioC() as DataM;
  components new Msp430GpioC() as ModeSel0M;
  components new Msp430GpioC() as ModeSel1M;
  components new Msp430GpioC() as NssConfigM;
  components new Msp430GpioC() as NssDataM;

  Irq0PinM -> HplMsp430GeneralIOC.Port20;
  Irq1PinM -> HplMsp430GeneralIOC.Port21;
  AntSelTXM -> HplMsp430GeneralIOC.Port27;
  AntSelRXM -> HplMsp430GeneralIOC.Port26;
  DataM -> HplMsp430GeneralIOC.Port57;
  ModeSel0M -> HplMsp430GeneralIOC.Port34;
  ModeSel1M -> HplMsp430GeneralIOC.Port35;
  NssConfigM -> HplMsp430GeneralIOC.Port14;
  NssDataM -> HplMsp430GeneralIOC.Port10;


  Irq0Pin = Irq0PinM;
  Irq1Pin = Irq1PinM;
  AntSelTXPin = AntSelTXM;
  AntSelRXPin = AntSelRXM;
  DataPin = DataM;
  ModeSel0Pin = ModeSel0M;
  ModeSel1Pin = ModeSel1M;
  NssConfigPin = NssConfigM;
  NssDataPin = NssDataM;
}
