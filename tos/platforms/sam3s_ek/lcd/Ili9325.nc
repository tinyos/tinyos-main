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
