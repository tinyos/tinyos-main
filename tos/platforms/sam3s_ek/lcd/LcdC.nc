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
