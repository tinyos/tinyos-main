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
    
    components LcdP, Ili9325C;

    Lcd = LcdP.Lcd;
    Draw = LcdP.Draw;

    LcdP.Ili9325 -> Ili9325C;

    components new TimerMilliC() as T0;
    Ili9325C.InitTimer -> T0;

    components HplSam3sGeneralIOC;
    LcdP.DB0 -> HplSam3sGeneralIOC.HplPioC0;
    LcdP.DB1 -> HplSam3sGeneralIOC.HplPioC1;
    LcdP.DB2 -> HplSam3sGeneralIOC.HplPioC2;
    LcdP.DB3 -> HplSam3sGeneralIOC.HplPioC3;
    LcdP.DB4 -> HplSam3sGeneralIOC.HplPioC4;
    LcdP.DB5 -> HplSam3sGeneralIOC.HplPioC5;
    LcdP.DB6 -> HplSam3sGeneralIOC.HplPioC6;
    LcdP.DB7 -> HplSam3sGeneralIOC.HplPioC7;

    LcdP.LCD_RS -> HplSam3sGeneralIOC.HplPioC19;
    LcdP.NRD    -> HplSam3sGeneralIOC.HplPioC11;
    LcdP.NWE    -> HplSam3sGeneralIOC.HplPioC8;
    LcdP.NCS   -> HplSam3sGeneralIOC.HplPioC15;

    LcdP.Backlight -> HplSam3sGeneralIOC.PioC13;

    components HplSam3sClockC;
    LcdP.ClockControl -> HplSam3sClockC.SMCCntl;
}
