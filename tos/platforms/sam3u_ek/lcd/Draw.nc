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

interface Draw
{
    async command void fill(uint32_t color);

    async command void drawPixel(
            uint32_t x,
            uint32_t y,
            uint32_t c);

    async command void drawRectangle(
            uint32_t x,
            uint32_t y,
            uint32_t width,
            uint32_t height,
            uint32_t color);

    async command void drawString(
            uint32_t x,
            uint32_t y,
            const char *pString,
            uint32_t color);

    async command void drawStringWithBGColor(
            uint32_t x,
            uint32_t y,
            const char *pString,
            uint32_t fontColor,
            uint32_t bgColor);

    async command void drawInt(
            uint32_t x,
            uint32_t y,
            uint32_t n,
            int8_t sign,
            uint32_t fontColor);

    async command void drawIntWithBGColor(
            uint32_t x,
            uint32_t y,
            uint32_t n,
            int8_t sign,
            uint32_t fontColor,
            uint32_t bgColor);

    async command void getStringSize(
            const char *pString,
            uint32_t *pWidth,
            uint32_t *pHeight);

    async command void drawChar(
            uint32_t x,
            uint32_t y,
            char c,
            uint32_t color);

    async command void drawCharWithBGColor(
            uint32_t x,
            uint32_t y,
            char c,
            uint32_t fontColor,
            uint32_t bgColor);
}
