/*
 * Copyright (c) 2009 Communication Group and Eislab at
 * Lulea University of Technology
 *
 * Contact: Laurynas Riliskis, LTU
 * Mail: laurynas.riliskis@ltu.se
 * All rights reserved.
 *
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of Communication Group at Lulea University of Technology
 *   nor the names of its contributors may be used to endorse or promote
 *    products derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL STANFORD
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * MMA7261QT configuration.
 *
 * @author Henrik Makitaavola
 */

configuration HplMMA7261QTC
{
  provides interface Read<uint16_t> as AccelX;
  provides interface Read<uint16_t> as AccelY;
  provides interface Read<uint16_t> as AccelZ;
  
  provides interface GeneralIO as Sleep;
  provides interface GeneralIO as GSelect1;
  provides interface GeneralIO as GSelect2;
}
implementation
{
  components new AdcReadClientC() as _AccelX, 
             new AdcReadClientC() as _AccelY,
             new AdcReadClientC() as _AccelZ,
             HplM16c60GeneralIOC as IOs,
             HplMMA7261QTP;
             
  HplMMA7261QTP.VCC -> IOs.PortP76;
  HplMMA7261QTP.Sleep -> IOs.PortP12;
  HplMMA7261QTP.GSelect1 -> IOs.PortP30;
  HplMMA7261QTP.GSelect2 -> IOs.PortP31;
  HplMMA7261QTP.AccelXPort -> IOs.PortP105;
  HplMMA7261QTP.AccelYPort -> IOs.PortP104;
  HplMMA7261QTP.AccelZPort -> IOs.PortP103;
  
  Sleep = IOs.PortP12;
  GSelect1 = IOs.PortP30;
  GSelect2 = IOs.PortP31;
  
  _AccelX.M16c60AdcConfig -> HplMMA7261QTP.AccelXConf;
  _AccelY.M16c60AdcConfig -> HplMMA7261QTP.AccelYConf;
  _AccelZ.M16c60AdcConfig -> HplMMA7261QTP.AccelZConf;
  
  AccelX = _AccelX;
  AccelY = _AccelY;
  AccelZ = _AccelZ;
  
  components RealMainP;
  RealMainP.PlatformInit -> HplMMA7261QTP.Init;
  
}
