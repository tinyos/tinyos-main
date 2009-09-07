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
 */
  
/**
 * Generic component to expose a full 8-bit port of GPIO pins.
 *
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 * @author Martin Turon <mturon@xbow.com>
 */

generic configuration HplM16c62pGeneralIOPortP(uint16_t port_addr,
                                               uint16_t ddr_addr)
{
  // provides all the ports as raw ports
  provides
  {
    interface GeneralIO as Pin0;
    interface GeneralIO as Pin1;
    interface GeneralIO as Pin2;
    interface GeneralIO as Pin3;
    interface GeneralIO as Pin4;
    interface GeneralIO as Pin5;
    interface GeneralIO as Pin6;
    interface GeneralIO as Pin7;
  }
}
implementation
{
  components 
    new HplM16c62pGeneralIOPinP (port_addr, ddr_addr, 0) as Bit0,
    new HplM16c62pGeneralIOPinP (port_addr, ddr_addr, 1) as Bit1,
    new HplM16c62pGeneralIOPinP (port_addr, ddr_addr, 2) as Bit2,
    new HplM16c62pGeneralIOPinP (port_addr, ddr_addr, 3) as Bit3,
    new HplM16c62pGeneralIOPinP (port_addr, ddr_addr, 4) as Bit4,
    new HplM16c62pGeneralIOPinP (port_addr, ddr_addr, 5) as Bit5,
    new HplM16c62pGeneralIOPinP (port_addr, ddr_addr, 6) as Bit6,
    new HplM16c62pGeneralIOPinP (port_addr, ddr_addr, 7) as Bit7;

  Pin0 = Bit0;
  Pin1 = Bit1;
  Pin2 = Bit2;
  Pin3 = Bit3;
  Pin4 = Bit4;
  Pin5 = Bit5;
  Pin6 = Bit6;
  Pin7 = Bit7;
}
