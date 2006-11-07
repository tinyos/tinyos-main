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
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, Data,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * ========================================================================
 */

/*
 * This configuration provides 'virtual' output pins using the 
 * mm74hc595 Serial-In Parallel-Out (SIPO) chip from Fairchild Semiconductor.
 *
 * This driver expects to find a HPL module called HplMM74HC595PinsC (that should 
 * be implemented for a platform or sensorboard) providing GeneralIO interfaces for 
 * the three physical pins of the MM74HC595 that it uses.
 *
 * These virtual output pins are presented as implementing the 
 * GeneralIO interface. Calling GeneralIO.makeOutput() or GeneralIO.makeInput() 
 * has no effect -- these pins are always outputs.
 * 
 * @author Henri Dubois-Ferriere
 *
 */

configuration MM74HC595C {
  provides interface GeneralIO as VirtualPin0; // Q_A on MM74HC595 datasheet
  provides interface GeneralIO as VirtualPin1; // Q_B
  provides interface GeneralIO as VirtualPin2; // Q_C
  provides interface GeneralIO as VirtualPin3; // Q_D
  provides interface GeneralIO as VirtualPin4; // Q_E
  provides interface GeneralIO as VirtualPin5; // Q_F
  provides interface GeneralIO as VirtualPin6; // Q_G
  provides interface GeneralIO as VirtualPin7; // Q_H
}
implementation {

  components MM74HC595ImplP, HplMM74HC595PinsC;
  MM74HC595ImplP.Ser -> HplMM74HC595PinsC.Ser;
  MM74HC595ImplP.Sck -> HplMM74HC595PinsC.Sck;
  MM74HC595ImplP.Rck -> HplMM74HC595PinsC.Rck;

  components MainC;
  MainC.SoftwareInit -> MM74HC595ImplP.Init;

  components BusyWaitMicroC;
  MM74HC595ImplP.BusyWait -> BusyWaitMicroC;

  components new MM74HC595P(0) as VPin0;
  VPin0.set -> MM74HC595ImplP.set;
  VPin0.get -> MM74HC595ImplP.get;
  VPin0.toggle -> MM74HC595ImplP.toggle;
  VPin0.clr -> MM74HC595ImplP.clr;
  VirtualPin0 = VPin0;

  components new MM74HC595P(1) as VPin1;
  VPin1.set -> MM74HC595ImplP.set;
  VPin1.get -> MM74HC595ImplP.get;
  VPin1.toggle -> MM74HC595ImplP.toggle;
  VPin1.clr -> MM74HC595ImplP.clr;
  VirtualPin1 = VPin1;

  components new MM74HC595P(2) as VPin2;
  VPin2.set -> MM74HC595ImplP.set;
  VPin2.get -> MM74HC595ImplP.get;
  VPin2.toggle -> MM74HC595ImplP.toggle;
  VPin2.clr -> MM74HC595ImplP.clr;
  VirtualPin2 = VPin2;

  components new MM74HC595P(3) as VPin3;
  VPin3.set -> MM74HC595ImplP.set;
  VPin3.get -> MM74HC595ImplP.get;
  VPin3.toggle -> MM74HC595ImplP.toggle;
  VPin3.clr -> MM74HC595ImplP.clr;
  VirtualPin3 = VPin3;

  components new MM74HC595P(4) as VPin4;
  VPin4.set -> MM74HC595ImplP.set;
  VPin4.get -> MM74HC595ImplP.get;
  VPin4.toggle -> MM74HC595ImplP.toggle;
  VPin4.clr -> MM74HC595ImplP.clr;
  VirtualPin4 = VPin4;

  components new MM74HC595P(5) as VPin5;
  VPin5.set -> MM74HC595ImplP.set;
  VPin5.get -> MM74HC595ImplP.get;
  VPin5.toggle -> MM74HC595ImplP.toggle;
  VPin5.clr -> MM74HC595ImplP.clr;
  VirtualPin5 = VPin5;

  components new MM74HC595P(6) as VPin6;
  VPin6.set -> MM74HC595ImplP.set;
  VPin6.get -> MM74HC595ImplP.get;
  VPin6.toggle -> MM74HC595ImplP.toggle;
  VPin6.clr -> MM74HC595ImplP.clr;
  VirtualPin6 = VPin6;

  components new MM74HC595P(7) as VPin7;
  VPin7.set -> MM74HC595ImplP.set;
  VPin7.get -> MM74HC595ImplP.get;
  VPin7.toggle -> MM74HC595ImplP.toggle;
  VPin7.clr -> MM74HC595ImplP.clr;
  VirtualPin7 = VPin7;

}
  
