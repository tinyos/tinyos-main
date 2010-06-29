/// $Id: HplAtm128GeneralIOPortP.nc,v 1.5 2010-06-29 22:07:43 scipio Exp $

/*
 * Copyright (c) 2004-2005 Crossbow Technology, Inc.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of Crossbow Technology nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * Generic component to expose a full 8-bit port of GPIO pins.
 *
 * @author Martin Turon <mturon@xbow.com>
 */

generic configuration HplAtm128GeneralIOPortP (uint8_t port_addr, uint8_t ddr_addr, uint8_t pin_addr)
{
  // provides all the ports as raw ports
  provides {
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
  new HplAtm128GeneralIOPinP (port_addr, ddr_addr, pin_addr, 0) as Bit0,
    new HplAtm128GeneralIOPinP (port_addr, ddr_addr, pin_addr, 1) as Bit1,
    new HplAtm128GeneralIOPinP (port_addr, ddr_addr, pin_addr, 2) as Bit2,
    new HplAtm128GeneralIOPinP (port_addr, ddr_addr, pin_addr, 3) as Bit3,
    new HplAtm128GeneralIOPinP (port_addr, ddr_addr, pin_addr, 4) as Bit4,
    new HplAtm128GeneralIOPinP (port_addr, ddr_addr, pin_addr, 5) as Bit5,
    new HplAtm128GeneralIOPinP (port_addr, ddr_addr, pin_addr, 6) as Bit6,
    new HplAtm128GeneralIOPinP (port_addr, ddr_addr, pin_addr, 7) as Bit7;

  Pin0 = Bit0;
  Pin1 = Bit1;
  Pin2 = Bit2;
  Pin3 = Bit3;
  Pin4 = Bit4;
  Pin5 = Bit5;
  Pin6 = Bit6;
  Pin7 = Bit7;
}
