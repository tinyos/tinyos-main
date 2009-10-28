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
 
 /*
 * Copyright (c) 2004-2005 Crossbow Technology, Inc.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL CROSSBOW TECHNOLOGY OR ANY OF ITS LICENSORS BE LIABLE TO 
 * ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL 
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF CROSSBOW OR ITS LICENSOR HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH 
 * DAMAGE. 
 *
 * CROSSBOW TECHNOLOGY AND ITS LICENSORS SPECIFICALLY DISCLAIM ALL WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY 
 * AND FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE PROVIDED HEREUNDER IS 
 * ON AN "AS IS" BASIS, AND NEITHER CROSSBOW NOR ANY LICENSOR HAS ANY 
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR 
 * MODIFICATIONS.
 * 
 * @author Martin Turon <mturon@xbow.com>
 */
 
/**
 * The HplM16c62pGeneralIOC configuration provides GeneralIO interfaces for all
 * the M16c/62p's pins.
 *
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 */

#include "iom16c62p.h"

configuration HplM16c62pGeneralIOC
{
  // provides all the ports as raw ports
  provides
  {
    interface GeneralIO as PortP00;
    interface GeneralIO as PortP01;
    interface GeneralIO as PortP02;
    interface GeneralIO as PortP03;
    interface GeneralIO as PortP04;
    interface GeneralIO as PortP05;
    interface GeneralIO as PortP06;
    interface GeneralIO as PortP07;

    interface GeneralIO as PortP10;
    interface GeneralIO as PortP11;
    interface GeneralIO as PortP12;
    interface GeneralIO as PortP13;
    interface GeneralIO as PortP14;
    interface GeneralIO as PortP15;
    interface GeneralIO as PortP16;
    interface GeneralIO as PortP17;

    interface GeneralIO as PortP20;
    interface GeneralIO as PortP21;
    interface GeneralIO as PortP22;
    interface GeneralIO as PortP23;
    interface GeneralIO as PortP24;
    interface GeneralIO as PortP25;
    interface GeneralIO as PortP26;
    interface GeneralIO as PortP27;

    interface GeneralIO as PortP30;
    interface GeneralIO as PortP31;
    interface GeneralIO as PortP32;
    interface GeneralIO as PortP33;
    interface GeneralIO as PortP34;
    interface GeneralIO as PortP35;
    interface GeneralIO as PortP36;
    interface GeneralIO as PortP37;

    interface GeneralIO as PortP40;
    interface GeneralIO as PortP41;
    interface GeneralIO as PortP42;
    interface GeneralIO as PortP43;
    interface GeneralIO as PortP44;
    interface GeneralIO as PortP45;
    interface GeneralIO as PortP46;
    interface GeneralIO as PortP47;

    interface GeneralIO as PortP50;
    interface GeneralIO as PortP51;
    interface GeneralIO as PortP52;
    interface GeneralIO as PortP53;
    interface GeneralIO as PortP54;
    interface GeneralIO as PortP55;
    interface GeneralIO as PortP56;
    interface GeneralIO as PortP57;
  
    interface GeneralIO as PortP60;
    interface GeneralIO as PortP61;
    interface GeneralIO as PortP62;
    interface GeneralIO as PortP63;
    interface GeneralIO as PortP64;
    interface GeneralIO as PortP65;
    interface GeneralIO as PortP66;
    interface GeneralIO as PortP67;
  
    interface GeneralIO as PortP70;
    interface GeneralIO as PortP71;
    interface GeneralIO as PortP72;
    interface GeneralIO as PortP73;
    interface GeneralIO as PortP74;
    interface GeneralIO as PortP75;
    interface GeneralIO as PortP76;
    interface GeneralIO as PortP77;
  
    interface GeneralIO as PortP80;
    interface GeneralIO as PortP81;
    interface GeneralIO as PortP82;
    interface GeneralIO as PortP83;
    interface GeneralIO as PortP84;
    interface GeneralIO as PortP85;
    interface GeneralIO as PortP86;
    interface GeneralIO as PortP87;
  
    interface GeneralIO as PortP90;
    interface GeneralIO as PortP91;
    interface GeneralIO as PortP92;
    interface GeneralIO as PortP93;
    interface GeneralIO as PortP94;
    interface GeneralIO as PortP95;
    interface GeneralIO as PortP96;
    interface GeneralIO as PortP97;
 
    interface GeneralIO as PortP100;
    interface GeneralIO as PortP101;
    interface GeneralIO as PortP102;
    interface GeneralIO as PortP103;
    interface GeneralIO as PortP104;
    interface GeneralIO as PortP105;
    interface GeneralIO as PortP106;
    interface GeneralIO as PortP107;
  
  }
}
implementation
{
  components 
    new HplM16c62pGeneralIOPortP((uint16_t)&P0.BYTE, (uint16_t)&PD0.BYTE) as PortP0,
    new HplM16c62pGeneralIOPortP((uint16_t)&P1.BYTE, (uint16_t)&PD1.BYTE) as PortP1,
    new HplM16c62pGeneralIOPortP((uint16_t)&P2.BYTE, (uint16_t)&PD2.BYTE) as PortP2,
    new HplM16c62pGeneralIOPortP((uint16_t)&P3.BYTE, (uint16_t)&PD3.BYTE) as PortP3,
    new HplM16c62pGeneralIOPortP((uint16_t)&P4.BYTE, (uint16_t)&PD4.BYTE) as PortP4,
    new HplM16c62pGeneralIOPortP((uint16_t)&P5.BYTE, (uint16_t)&PD5.BYTE) as PortP5,
    new HplM16c62pGeneralIOPortP((uint16_t)&P6.BYTE, (uint16_t)&PD6.BYTE) as PortP6,
    new HplM16c62pGeneralIOPortP((uint16_t)&P7.BYTE, (uint16_t)&PD7.BYTE) as PortP7,
    new HplM16c62pGeneralIOPortP((uint16_t)&P8.BYTE, (uint16_t)&PD8.BYTE) as PortP8,
    new HplM16c62pGeneralIOPortP((uint16_t)&P9.BYTE, (uint16_t)&PD9.BYTE) as PortP9,
    new HplM16c62pGeneralIOPortP((uint16_t)&P10.BYTE, (uint16_t)&PD10.BYTE) as PortP_10;

  PortP00 = PortP0.Pin0;
  PortP01 = PortP0.Pin1;
  PortP02 = PortP0.Pin2;
  PortP03 = PortP0.Pin3;
  PortP04 = PortP0.Pin4;
  PortP05 = PortP0.Pin5;
  PortP06 = PortP0.Pin6;
  PortP07 = PortP0.Pin7;

  PortP10 = PortP1.Pin0;
  PortP11 = PortP1.Pin1;
  PortP12 = PortP1.Pin2;
  PortP13 = PortP1.Pin3;
  PortP14 = PortP1.Pin4;
  PortP15 = PortP1.Pin5;
  PortP16 = PortP1.Pin6;
  PortP17 = PortP1.Pin7;

  PortP20 = PortP2.Pin0;
  PortP21 = PortP2.Pin1;
  PortP22 = PortP2.Pin2;
  PortP23 = PortP2.Pin3;
  PortP24 = PortP2.Pin4;
  PortP25 = PortP2.Pin5;
  PortP26 = PortP2.Pin6;
  PortP27 = PortP2.Pin7;

  PortP30 = PortP3.Pin0;
  PortP31 = PortP3.Pin1;
  PortP32 = PortP3.Pin2;
  PortP33 = PortP3.Pin3;
  PortP34 = PortP3.Pin4;
  PortP35 = PortP3.Pin5;
  PortP36 = PortP3.Pin6;
  PortP37 = PortP3.Pin7;

  PortP40 = PortP4.Pin0;
  PortP41 = PortP4.Pin1;
  PortP42 = PortP4.Pin2;
  PortP43 = PortP4.Pin3;
  PortP44 = PortP4.Pin4;
  PortP45 = PortP4.Pin5;
  PortP46 = PortP4.Pin6;
  PortP47 = PortP4.Pin7;

  PortP50 = PortP5.Pin0;
  PortP51 = PortP5.Pin1;
  PortP52 = PortP5.Pin2;
  PortP53 = PortP5.Pin3;
  PortP54 = PortP5.Pin4;
  PortP55 = PortP5.Pin5;
  PortP56 = PortP5.Pin6;
  PortP57 = PortP5.Pin7;

  PortP60 = PortP6.Pin0;
  PortP61 = PortP6.Pin1;
  PortP62 = PortP6.Pin2;
  PortP63 = PortP6.Pin3;
  PortP64 = PortP6.Pin4;
  PortP65 = PortP6.Pin5;
  PortP66 = PortP6.Pin6;
  PortP67 = PortP6.Pin7;

  PortP70 = PortP7.Pin0;
  PortP71 = PortP7.Pin1;
  PortP72 = PortP7.Pin2;
  PortP73 = PortP7.Pin3;
  PortP74 = PortP7.Pin4;
  PortP75 = PortP7.Pin5;
  PortP76 = PortP7.Pin6;
  PortP77 = PortP7.Pin7;

  PortP80 = PortP8.Pin0;
  PortP81 = PortP8.Pin1;
  PortP82 = PortP8.Pin2;
  PortP83 = PortP8.Pin3;
  PortP84 = PortP8.Pin4;
  PortP85 = PortP8.Pin5;
  PortP86 = PortP8.Pin6;
  PortP87 = PortP8.Pin7;
  
  components 
    new HplM16c62pGeneralIOPinPRC2P() as PortP90W,
    new HplM16c62pGeneralIOPinPRC2P() as PortP91W,
    new HplM16c62pGeneralIOPinPRC2P() as PortP92W,
    new HplM16c62pGeneralIOPinPRC2P() as PortP93W,
    new HplM16c62pGeneralIOPinPRC2P() as PortP94W,
    new HplM16c62pGeneralIOPinPRC2P() as PortP95W,
    new HplM16c62pGeneralIOPinPRC2P() as PortP96W,
    new HplM16c62pGeneralIOPinPRC2P() as PortP97W;

  PortP90W -> PortP9.Pin0;
  PortP91W -> PortP9.Pin1;
  PortP92W -> PortP9.Pin2;
  PortP93W -> PortP9.Pin3;
  PortP94W -> PortP9.Pin4;
  PortP95W -> PortP9.Pin5;
  PortP96W -> PortP9.Pin6;
  PortP97W -> PortP9.Pin7;
  
  PortP90 = PortP90W;
  PortP91 = PortP91W;
  PortP92 = PortP92W;
  PortP93 = PortP93W;
  PortP94 = PortP94W;
  PortP95 = PortP95W;
  PortP96 = PortP96W;
  PortP97 = PortP97W;

  PortP100 = PortP_10.Pin0;
  PortP101 = PortP_10.Pin1;
  PortP102 = PortP_10.Pin2;
  PortP103 = PortP_10.Pin3;
  PortP104 = PortP_10.Pin4;
  PortP105 = PortP_10.Pin5;
  PortP106 = PortP_10.Pin6;
  PortP107 = PortP_10.Pin7;
}
