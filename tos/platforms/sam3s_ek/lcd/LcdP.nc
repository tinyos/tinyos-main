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
#include <sam3smchardware.h>
#include "lcd.h"
#include "color.h"
#include "font.h"
#include "font10x14.h"

module LcdP
{
    uses {
        interface Ili9325;

        interface HplSam3GeneralIOPin as DB0;
        interface HplSam3GeneralIOPin as DB1;
        interface HplSam3GeneralIOPin as DB2;
        interface HplSam3GeneralIOPin as DB3;
        interface HplSam3GeneralIOPin as DB4;
        interface HplSam3GeneralIOPin as DB5;
        interface HplSam3GeneralIOPin as DB6;
        interface HplSam3GeneralIOPin as DB7;
        interface HplSam3GeneralIOPin as LCD_RS;
        interface HplSam3GeneralIOPin as NRD;
        interface HplSam3GeneralIOPin as NWE;
        interface HplSam3GeneralIOPin as NCS;

        interface GeneralIO as Backlight;

        interface HplSam3PeripheralClockCntl as ClockControl;
    }
    provides 
    {
        interface Lcd;
        interface Draw;
    }
}
implementation
{

#define RGB24ToRGB16(color) (((color >> 8) & 0xF800) | \
        ((color >> 5) & 0x7E0) | \
        ((color >> 3) & 0x1F))
#define BOARD_LCD_BASE   0x61000000

    const Font gFont = {10, 14};

    /**
     * Initializes the LCD controller.
     * \param pLcdBase   LCD base address.
     */
    command void Lcd.initialize(void)
    {
        smc_setup_t setup;
        smc_pulse_t pulse;
        smc_cycle_t cycle;
        smc_mode_t  mode;

        // Enable pins
        call DB0.disablePioControl();
        call DB0.selectPeripheralA();
        call DB0.enablePullUpResistor();
        call DB1.disablePioControl();
        call DB1.selectPeripheralA();
        call DB1.enablePullUpResistor();
        call DB2.disablePioControl();
        call DB2.selectPeripheralA();
        call DB2.enablePullUpResistor();
        call DB3.disablePioControl();
        call DB3.selectPeripheralA();
        call DB3.enablePullUpResistor();
        call DB4.disablePioControl();
        call DB4.selectPeripheralA();
        call DB4.enablePullUpResistor();
        call DB5.disablePioControl();
        call DB5.selectPeripheralA();
        call DB5.enablePullUpResistor();
        call DB6.disablePioControl();
        call DB6.selectPeripheralA();
        call DB6.enablePullUpResistor();
        call DB7.disablePioControl();
        call DB7.selectPeripheralA();
        call DB7.enablePullUpResistor();

        call LCD_RS.disablePioControl();
        call LCD_RS.selectPeripheralA();
        call LCD_RS.enablePullUpResistor();

        call NRD.disablePioControl();
        call NRD.selectPeripheralA();
        call NRD.enablePullUpResistor();
        call NWE.disablePioControl();
        call NWE.selectPeripheralA();
        call NWE.enablePullUpResistor();
        call NCS.disablePioControl();
        call NCS.selectPeripheralA();
        call NCS.enablePullUpResistor();

        // Enable peripheral clock
        call ClockControl.enable();

        // Enable pins
        call Backlight.makeOutput();

        // EBI SMC Configuration
        setup.flat              = 0;
        setup.bits.nwe_setup    = 2;
        setup.bits.ncs_wr_setup = 2;
        setup.bits.nrd_setup    = 2;
        setup.bits.ncs_rd_setup = 2;
        SMC_CS1->setup = setup;

        pulse.flat              = 0;
        pulse.bits.nwe_pulse    = 4;
        pulse.bits.ncs_wr_pulse = 4;
        pulse.bits.nrd_pulse    = 10;
        pulse.bits.ncs_rd_pulse = 10;
        SMC_CS1->pulse = pulse;

        cycle.flat           = 0;
        cycle.bits.nwe_cycle = 10;
        cycle.bits.nrd_cycle = 22;
        SMC_CS1->cycle = cycle;

        mode.bits.read_mode = 1;
        mode.bits.write_mode = 1;
        mode.bits.dbw = 0; // 8-bit operations
        mode.bits.pmen = 0;
        SMC_CS1->mode = mode;

        // Initialize LCD controller (HX8347)
        call Ili9325.initialize((void *)BOARD_LCD_BASE);

    }

    event void Ili9325.initializeDone(error_t err)
    {
        if(err == SUCCESS)
            call Lcd.setBacklight(25);
        signal Lcd.initializeDone(err);
    }

    /**
     * Turn on the LCD
     */
    command void Lcd.start(void)
    {
        call Ili9325.on((void *)BOARD_LCD_BASE);
        signal Lcd.startDone();
    }

    /**
     * Turn off the LCD
     */
    command void Lcd.stop(void)
    {
        call Ili9325.off((void *)BOARD_LCD_BASE);
    }

    /**
     * Set the backlight of the LCD.
     * \param level   Backlight brightness level [1..32], 32 is maximum level.
     */
    command void Lcd.setBacklight (uint8_t level)
    {
        uint32_t i;

        // Switch off backlight
        call Backlight.clr();
        i = 800 * (48000000 / 1000000);    // wait for at least 500us
        while(i--);

        // Set new backlight level
        for (i = 0; i < level; i++) {


            call Backlight.clr();
            call Backlight.clr();
            call Backlight.clr();

            call Backlight.set();
            call Backlight.set();
            call Backlight.set();
        }
    }

    command void* Lcd.displayBuffer(void* pBuffer)
    {
        return (void *) BOARD_LCD_BASE;
    }

    /**
     * Fills the given LCD buffer with a particular color.
     * Only works in 24-bits packed mode for now.
     * \param color  Fill color.
     */
    async command void Draw.fill(uint32_t color)
    {
        uint32_t i;

        call Ili9325.setCursor((void *)BOARD_LCD_BASE, 0, 0);
        call Ili9325.writeRAM_Prepare((void *)BOARD_LCD_BASE);
        for (i = 0; i < (BOARD_LCD_WIDTH * BOARD_LCD_HEIGHT); i++) {

            call Ili9325.writeRAM((void *)BOARD_LCD_BASE, color);
        }
    }

    /**
     * Sets the specified pixel to the given color.
     * !!! Only works in 24-bits packed mode for now. !!!
     * \param x  X-coordinate of pixel.
     * \param y  Y-coordinate of pixel.
     * \param color  Pixel color.
     */
    async command void Draw.drawPixel(
            uint32_t x,
            uint32_t y,
            uint32_t color)
    {
        void* pBuffer = (void*)BOARD_LCD_BASE;

        call Ili9325.setCursor(pBuffer, BOARD_LCD_WIDTH - x, y);
        call Ili9325.writeRAM_Prepare(pBuffer);
        call Ili9325.writeRAM(pBuffer, color);
    }

    /**
     * Draws a rectangle inside a LCD buffer, at the given coordinates.
     * \param x  X-coordinate of upper-left rectangle corner.
     * \param y  Y-coordinate of upper-left rectangle corner.
     * \param width  Rectangle width in pixels.
     * \param height  Rectangle height in pixels.
     * \param color  Rectangle color.
     */
    async command void Draw.drawRectangle(
            uint32_t x,
            uint32_t y,
            uint32_t width,
            uint32_t height,
            uint32_t color)
    {
        uint32_t rx, ry;

        for (ry=0; ry < height; ry++) {

            for (rx=0; rx < width; rx++) {

                call Draw.drawPixel(x+rx, y+ry, color);
            }
        }
    }
    /**
     * Draws a string inside a LCD buffer, at the given coordinates. Line breaks
     * will be honored.
     * \param x  X-coordinate of string top-left corner.
     * \param y  Y-coordinate of string top-left corner.
     * \param pString  String to display.
     * \param color  String color.
     */
    async command void Draw.drawString(
            uint32_t x,
            uint32_t y,
            const char *pString,
            uint32_t color)
    {
        uint32_t xorg = x;

        while (*pString != 0) {
            if (*pString == '\n') {

                y += gFont.height + 2;
                x = xorg;
            }
            else {

                call Draw.drawChar(x, y, *pString, color);
                x += gFont.width + 2;
            }
            pString++;
        }
    }

    /**
     * Draws a string inside a LCD buffer, at the given coordinates. Line breaks
     * will be honored.
     * \param x  X-coordinate of string top-left corner.
     * \param y  Y-coordinate of string top-left corner.
     * \param pString  String to display.
     * \param color  String color.
     */
    async command void Draw.drawStringWithBGColor(
            uint32_t x,
            uint32_t y,
            const char *pString,
            uint32_t fontColor,
            uint32_t bgColor)
    {
        uint32_t xorg = x;

        while (*pString != 0) {
            if (*pString == '\n') {

                y += gFont.height + 2;
                x = xorg;
            }
            else {

                call Draw.drawCharWithBGColor(x, y, *pString, fontColor, bgColor);
                x += gFont.width + 2;
            }
            pString++;
        }
    }

    /**
     * Draws an integer inside the LCD buffer
     * \param x X-Coordinate of the integers top-right corner.
     * \param y Y-Coordinate of the integers top-right corner.
     * \param n Number to be printed on the screen
     * \param sign <0 if negative number, >=0 if positive
     * \param fontColor Integer color.
     */
    async command void Draw.drawInt(
            uint32_t x,
            uint32_t y,
            uint32_t n,
            int8_t sign,
            uint32_t fontColor)
    {
        uint8_t i;
        i = 0;
        do {       /* generate digits in reverse order */
            char c = n % 10 + '0';   /* get next digit */
            if (i%3 == 0 && i>0)
            {
                call Draw.drawChar(x, y, '\'', fontColor);
                x -= (gFont.width + 2);
            }
            call Draw.drawChar(x, y, c, fontColor);
            x -= (gFont.width + 2);
            i++;
        } while ((n /= 10) > 0);     /* delete it */
        if (sign < 0)
            call Draw.drawChar(x, y, '-', fontColor);
    }

    /**
     * Draws an integer inside the LCD buffer
     * \param x X-Coordinate of the integers top-right corner.
     * \param y Y-Coordinate of the integers top-right corner.
     * \param n Number to be printed on the screen
     * \param sign <0 if negative number, >=0 if positive
     * \param color Integer color.
     * \param bgColor Color of the background.
     */
    async command void Draw.drawIntWithBGColor(
            uint32_t x,
            uint32_t y,
            uint32_t n,
            int8_t sign,
            uint32_t fontColor,
            uint32_t bgColor)
    {
        uint8_t i;
        i = 0;
        do {       /* generate digits in reverse order */
            char c = n % 10 + '0';   /* get next digit */
            if (i%3 == 0 && i>0)
            {
                call Draw.drawChar(x, y, '\'', fontColor);
                x -= (gFont.width + 2);
            }
            call Draw.drawCharWithBGColor(x, y, c, fontColor, bgColor);
            x -= (gFont.width + 2);
            i++;
        } while ((n /= 10) > 0);     /* delete it */
        if (sign < 0)
            call Draw.drawCharWithBGColor(x, y, '-', fontColor, bgColor);
    }

    /**
     * Returns the width & height in pixels that a string will occupy on the screen
     * if drawn using Draw.drawString.
     * \param pString  String.
     * \param pWidth  Pointer for storing the string width (optional).
     * \param pHeight  Pointer for storing the string height (optional).
     * \return String width in pixels.
     */
    async command void Draw.getStringSize(
            const char *pString,
            uint32_t *pWidth,
            uint32_t *pHeight)
    {
        uint32_t width = 0;
        uint32_t height = gFont.height;

        while (*pString != 0) {

            if (*pString == '\n') {

                height += gFont.height + 2;
            }
            else {

                width += gFont.width + 2;
            }
            pString++;
        }

        if (width > 0) width -= 2;

        if (pWidth) *pWidth = width;
        if (pHeight) *pHeight = height;
    }

    /**
     * Draws an ASCII character on the given LCD buffer.
     * \param x  X-coordinate of character upper-left corner.
     * \param y  Y-coordinate of character upper-left corner.
     * \param c  Character to output.
     * \param color  Character color.
     */
    async command void Draw.drawChar(
            uint32_t x,
            uint32_t y,
            char c,
            uint32_t color)
    {
        uint32_t row, col;

        if(!((c >= 0x20) && (c <= 0x7F)))
        {
            return;
        }

        for (col = 0; col < 10; col++) {

            for (row = 0; row < 8; row++) {

                if ((pCharset10x14[((c - 0x20) * 20) + col * 2] >> (7 - row)) & 0x1) {

                    call Draw.drawPixel(x+col, y+row, color);
                }
            }
            for (row = 0; row < 6; row++) {

                if ((pCharset10x14[((c - 0x20) * 20) + col * 2 + 1] >> (7 - row)) & 0x1) {

                    call Draw.drawPixel(x+col, y+row+8, color);
                }
            }
        }
    }

    /**
     * Draws an ASCII character on the given LCD buffer.
     * \param x  X-coordinate of character upper-left corner.
     * \param y  Y-coordinate of character upper-left corner.
     * \param c  Character to output.
     * \param fontColor  Character foreground color.
     * \param bgColor Background color of character
     */
    async command void Draw.drawCharWithBGColor(
            uint32_t x,
            uint32_t y,
            char c,
            uint32_t fontColor,
            uint32_t bgColor)
    {
        uint32_t row, col;

        if(!((c >= 0x20) && (c <= 0x7F)))
        {
            return;
        }

        for (col = 0; col < 10; col++) {

            for (row = 0; row < 8; row++) {

                if ((pCharset10x14[((c - 0x20) * 20) + col * 2] >> (7 - row)) & 0x1) {

                    call Draw.drawPixel(x+col, y+row, fontColor);
                } else {
                    call Draw.drawPixel(x+col, y+row, bgColor);
                }
            }
            for (row = 0; row < 6; row++) {

                if ((pCharset10x14[((c - 0x20) * 20) + col * 2 + 1] >> (7 - row)) & 0x1) {

                    call Draw.drawPixel(x+col, y+row+8, fontColor);
                } else {
                    call Draw.drawPixel(x+col, y+row+8, bgColor);
                }
            }
        }
    }

}
