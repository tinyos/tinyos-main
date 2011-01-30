/**
 * Copyright (c) 2009 The Regents of the University of California.
 * All rights reserved.
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
 * - Neither the name of the copyright holders nor the names of its
 *   contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
 * AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 * WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * Heavily inspired by the at91 library.
 * @author Thomas Schmid
 **/

configuration LcdC
{
    provides
    {
        interface Lcd;
        interface Draw;
    }
}
implementation
{
    
    components LcdP, Hx8347C;

    Lcd = LcdP.Lcd;
    Draw = LcdP.Draw;

    LcdP.Hx8347 -> Hx8347C;

    components new TimerMilliC() as T0;
    components new TimerMilliC() as T1;
    Hx8347C.InitTimer -> T0;
    Hx8347C.OnTimer -> T1;

    components HplSam3uGeneralIOC;
    LcdP.DB0 -> HplSam3uGeneralIOC.HplPioB9;
    LcdP.DB1 -> HplSam3uGeneralIOC.HplPioB10;
    LcdP.DB2 -> HplSam3uGeneralIOC.HplPioB11;
    LcdP.DB3 -> HplSam3uGeneralIOC.HplPioB12;
    LcdP.DB4 -> HplSam3uGeneralIOC.HplPioB13;
    LcdP.DB5 -> HplSam3uGeneralIOC.HplPioB14;
    LcdP.DB6 -> HplSam3uGeneralIOC.HplPioB15;
    LcdP.DB7 -> HplSam3uGeneralIOC.HplPioB16;
    LcdP.DB8 -> HplSam3uGeneralIOC.HplPioB25;
    LcdP.DB9 -> HplSam3uGeneralIOC.HplPioB26;
    LcdP.DB10 -> HplSam3uGeneralIOC.HplPioB27;
    LcdP.DB11 -> HplSam3uGeneralIOC.HplPioB28;
    LcdP.DB12 -> HplSam3uGeneralIOC.HplPioB29;
    LcdP.DB13 -> HplSam3uGeneralIOC.HplPioB30;
    LcdP.DB14 -> HplSam3uGeneralIOC.HplPioB31;
    LcdP.DB15 -> HplSam3uGeneralIOC.HplPioB6;

    LcdP.LCD_RS -> HplSam3uGeneralIOC.HplPioB8;
    LcdP.NRD    -> HplSam3uGeneralIOC.HplPioB19;
    LcdP.NWE    -> HplSam3uGeneralIOC.HplPioB23;
    LcdP.NCS2   -> HplSam3uGeneralIOC.HplPioC16;

    LcdP.Backlight -> HplSam3uGeneralIOC.PioC19;

    components HplSam3uClockC;
    LcdP.HSMC4ClockControl -> HplSam3uClockC.HSMC4PPCntl;
}
