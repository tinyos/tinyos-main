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

configuration XE1205PhyC {
  provides interface XE1205PhyRxTx;
  provides interface XE1205PhyRssi;
  provides interface SplitControl;
}
implementation {

  components XE1205PhyP;

  components XE1205PhySwitchC;
  XE1205PhyP.XE1205PhySwitch -> XE1205PhySwitchC;

  components new XE1205SpiC();
  XE1205PhyP.XE1205Fifo -> XE1205SpiC;
  XE1205PhyP.SpiResourceRX -> XE1205SpiC;

  components new XE1205SpiC() as SpiTX;
  XE1205PhyP.SpiResourceTX -> SpiTX;

  components new XE1205SpiC() as SpiConfig;
  XE1205PhyP.SpiResourceConfig -> SpiConfig;

  components new XE1205SpiC() as SpiRSSI;
  XE1205PhyP.SpiResourceRssi -> SpiRSSI;

  components HplXE1205InterruptsC;
  XE1205PhyP.Interrupt0 -> HplXE1205InterruptsC.Interrupt0;
  XE1205PhyP.Interrupt1 -> HplXE1205InterruptsC.Interrupt1;


  XE1205PhyRxTx = XE1205PhyP;
  SplitControl = XE1205PhyP;
  XE1205PhyRssi = XE1205PhyP;

  components MainC;
  MainC.SoftwareInit -> XE1205PhyP.Init;

  components XE1205PatternConfC;
  XE1205PhyP.XE1205PatternConf -> XE1205PatternConfC;

  components XE1205IrqConfC;
  XE1205PhyP.XE1205IrqConf -> XE1205IrqConfC;

  components XE1205PhyRssiConfC;
  XE1205PhyP.XE1205RssiConf -> XE1205PhyRssiConfC;

  components new Alarm32khz16C();
  XE1205PhyP.Alarm32khz16 -> Alarm32khz16C.Alarm;
#if 0
  components new Msp430GpioC() as DpinM, HplMsp430GeneralIOC;
  DpinM -> HplMsp430GeneralIOC.Port41;
  XE1205PhyP.Dpin   -> DpinM;
#endif
}



