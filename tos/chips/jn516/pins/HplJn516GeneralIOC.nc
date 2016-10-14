/**
 * Copyright (c) 2015, Technische Universitaet Berlin
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
 * @author Tim Bormann <code@tkn.tu-berlin.de>
 * @author Sanjeet Raj Pandey <code@tkn.tu-berlin.de>
 */

/**
 * HPL for the jn516 family of microprocessors. This provides an
 * abstraction for general-purpose I/O.
 */

configuration HplJn516GeneralIOC
{
  provides interface HplJn516GeneralIO as Port0;
  provides interface HplJn516GeneralIO as Port1;
  provides interface HplJn516GeneralIO as Port2;
  provides interface HplJn516GeneralIO as Port3;
  provides interface HplJn516GeneralIO as Port4;
  provides interface HplJn516GeneralIO as Port5;
  provides interface HplJn516GeneralIO as Port6;
  provides interface HplJn516GeneralIO as Port7;
  provides interface HplJn516GeneralIO as Port8;
  provides interface HplJn516GeneralIO as Port9;
  provides interface HplJn516GeneralIO as Port10;
  provides interface HplJn516GeneralIO as Port11;
  provides interface HplJn516GeneralIO as Port12;
  provides interface HplJn516GeneralIO as Port13;
  provides interface HplJn516GeneralIO as Port14;
  provides interface HplJn516GeneralIO as Port15;
  provides interface HplJn516GeneralIO as Port16;
  provides interface HplJn516GeneralIO as Port17;
  provides interface HplJn516GeneralIO as Port18;
  provides interface HplJn516GeneralIO as Port19;

  provides interface HplJn516GeneralIO as PortNull;
  provides interface HplJn516GeneralIO as PortVirtual;
}
implementation
{
  components
    new HplJn516GeneralIOP(0) as P0, //LED D3 on DR1199, high-active
    new HplJn516GeneralIOP(1) as P1,
    new HplJn516GeneralIOP(2) as P2, //LED D6 on DR1174, low-active  [led0 on NXP DK4 Controller Board]
    new HplJn516GeneralIOP(3) as P3, //LED D3 on DR1174, low-active  [led1 on NXP DK4 Controller Board]
    new HplJn516GeneralIOP(4) as P4,
    new HplJn516GeneralIOP(5) as P5,
    new HplJn516GeneralIOP(6) as P6,
    new HplJn516GeneralIOP(7) as P7,
    new HplJn516GeneralIOP(8) as P8,
    new HplJn516GeneralIOP(9) as P9,
    new HplJn516GeneralIOP(10) as P10,
    new HplJn516GeneralIOP(11) as P11,
    new HplJn516GeneralIOP(12) as P12,
    new HplJn516GeneralIOP(13) as P13, //LED D2 on DR1199, high-active
    new HplJn516GeneralIOP(14) as P14,
    new HplJn516GeneralIOP(15) as P15,
    new HplJn516GeneralIOP(16) as P16, //LED D1 on DR1199, high-active
    new HplJn516GeneralIOP(17) as P17,
    new HplJn516GeneralIOP(18) as P18,
    new HplJn516GeneralIOP(19) as P19,

    new HplJn516NullIOP() as PNull,
    new HplJn516VirtualIOP() as PVirtual;

  Port0 = P0;
  Port1 = P1;
  Port2 = P2;
  Port3 = P3;
  Port4 = P4;
  Port5 = P5;
  Port6 = P6;
  Port7 = P7;
  Port8 = P8;
  Port9 = P9;
  Port10 = P10;
  Port11 = P11;
  Port12 = P12;
  Port13 = P13;
  Port14 = P14;
  Port15 = P15;
  Port16 = P16;
  Port17 = P17;
  Port18 = P18;
  Port19 = P19;

  PortNull = PNull;
  PortVirtual = PVirtual;
}
