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

interface Ili9325 
{
    async command void writeReg(void *pLcdBase, uint8_t reg, uint16_t data);
    async command uint16_t readReg(void *pLcdBase, uint8_t reg);
    async command void writeRAM_Prepare(void *pLcdBase);
    async command void writeRAM(void *pLcdBase, uint32_t color);
    async command void readRAM_Prepare(void *pLcdBase);
    async command uint16_t readRAM(void *pLcdBase);
    command void initialize(void *pLcdBase);
    event void initializeDone(error_t err);
    async command void setCursor(void *pLcdBase, uint16_t x, uint16_t y);
    command void on(void *pLcdBase);
    async command void off(void *pLcdBase);
    async command void powerDown(void *pLcdBase);
    async command void setDisplayPortrait(void *pLcdBase, uint32_t dwRGB);
    async command void setWindow( void *pLcdBase, uint32_t dwX, uint32_t dwY, uint32_t dwWidth, uint32_t dwHeight );
}
