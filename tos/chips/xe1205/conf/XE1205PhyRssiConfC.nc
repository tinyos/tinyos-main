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

/**
 * Implementation of XE1205RssiConf and XE1205PhyConf interfaces.
 *
 * @author Henri Dubois-Ferriere
 */



configuration XE1205PhyRssiConfC {

  provides interface XE1205PhyConf;
  provides interface XE1205RssiConf;
 
}

implementation {
  
  components XE1205PhyRssiConfP;

  components MainC;
  MainC.SoftwareInit -> XE1205PhyRssiConfP.Init;

  components new XE1205SpiC();
  XE1205PhyRssiConfP.SpiResource -> XE1205SpiC;
  XE1205PhyRssiConfP.MCParam0 -> XE1205SpiC.MCParam0;
  XE1205PhyRssiConfP.MCParam1 -> XE1205SpiC.MCParam1;
  XE1205PhyRssiConfP.MCParam2 -> XE1205SpiC.MCParam2;
  XE1205PhyRssiConfP.MCParam3 -> XE1205SpiC.MCParam3;
  XE1205PhyRssiConfP.MCParam4 -> XE1205SpiC.MCParam4;
  XE1205PhyRssiConfP.TXParam7 -> XE1205SpiC.TXParam7;
  XE1205PhyRssiConfP.RXParam8 -> XE1205SpiC.RXParam8;
  XE1205PhyRssiConfP.RXParam9 -> XE1205SpiC.RXParam9;

  XE1205PhyConf = XE1205PhyRssiConfP;
  XE1205RssiConf = XE1205PhyRssiConfP;
}
