/**
 * "Copyright (c) 2009 The Regents of the University of California.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
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
