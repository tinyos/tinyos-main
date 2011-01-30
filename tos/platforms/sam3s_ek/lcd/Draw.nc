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
