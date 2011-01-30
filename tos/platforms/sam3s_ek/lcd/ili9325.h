/* ----------------------------------------------------------------------------
 *         ATMEL Microcontroller Software Support
 * ----------------------------------------------------------------------------
 * Copyright (c) 2009, Atmel Corporation
 *
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
 * ----------------------------------------------------------------------------
 */

/**
 * \file
 *
 * Interface of ILI9325 driver.
 *
 */

#ifndef _ILI9325_
#define _ILI9325_

/*----------------------------------------------------------------------------
 *        Headers
 *----------------------------------------------------------------------------*/

typedef uint32_t LcdColor_t ;

/*----------------------------------------------------------------------------
 *        Definitions
 *----------------------------------------------------------------------------*/

/* ILI9325 ID code */
#define ILI9325_DEVICE_CODE    0x9325

/* ILI9325 LCD Registers */
#define ILI9325_R00H    0x00    /* Driver Code Read                 */
#define ILI9325_R01H    0x01    /* Driver Output Control 1          */
#define ILI9325_R01H_SS                ((uint16_t)0x0100)
#define ILI9325_R01H_SM                ((uint16_t)0x0400)
#define ILI9325_R02H    0x02    /* LCD Driving Control              */
#define ILI9325_R03H    0x03    /* Entry Mode                       */
#define ILI9325_R03H_AM                ((uint16_t)0x0008) /* AM Control the GRAM update direction */
#define ILI9325_R03H_ID0               ((uint16_t)0x0010) /* I/D[1:0] Control the address counter  */
#define ILI9325_R03H_ID1               ((uint16_t)0x0020)
#define ILI9325_R03H_ORG               ((uint16_t)0x0080)
#define ILI9325_R03H_HWM               ((uint16_t)0x0200)
#define ILI9325_R03H_BGR               ((uint16_t)0x1000)
#define ILI9325_R03H_DFM               ((uint16_t)0x4000)
#define ILI9325_R03H_TRI               ((uint16_t)0x8000)
#define ILI9325_R04H    0x04    /* Resize Control                   */
#define ILI9325_R07H    0x07    /* Display Control 1                */
#define ILI9325_R07H_D0                ((uint16_t)0x0001)
#define ILI9325_R07H_D1                ((uint16_t)0x0002)
#define ILI9325_R07H_CL                ((uint16_t)0x0008)
#define ILI9325_R07H_DTE               ((uint16_t)0x0010)
#define ILI9325_R07H_GON               ((uint16_t)0x0020)
#define ILI9325_R07H_BASEE             ((uint16_t)0x0100)
#define ILI9325_R07H_PTDE0             ((uint16_t)0x1000)
#define ILI9325_R07H_PTDE1             ((uint16_t)0x2000)

#define ILI9325_R08H    0x08    /* Display Control 2                */
#define ILI9325_R09H    0x09    /* Display Control 3                */
#define ILI9325_R0AH    0x0A    /* Display Control 4                */
#define ILI9325_R0CH    0x0C    /* RGB Display Interface Control 1  */
#define ILI9325_R0DH    0x0D    /* Frame Maker Position             */
#define ILI9325_R0FH    0x0F    /* RGB Display Interface Control 2  */

#define ILI9325_R10H    0x10    /* Power Control 1 */
#define ILI9325_R11H    0x11    /* Power Control 2 */
#define ILI9325_R12H    0x12    /* Power Control 3 */
#define ILI9325_R13H    0x13    /* Power Control 4 */

#define ILI9325_R20H    0x20    /* Horizontal GRAM Address Set  */
#define ILI9325_R21H    0x21    /* Vertical  GRAM Address Set   */
#define ILI9325_R22H    0x22    /* Write Data to GRAM           */
#define ILI9325_R29H    0x29    /* Power Control 7              */
#define ILI9325_R2BH    0x2B    /* Frame Rate and Color Control */

#define ILI9325_R30H    0x30    /* Gamma Control 1  */
#define ILI9325_R31H    0x31    /* Gamma Control 2  */
#define ILI9325_R32H    0x32    /* Gamma Control 3  */
#define ILI9325_R35H    0x35    /* Gamma Control 4  */
#define ILI9325_R36H    0x36    /* Gamma Control 5  */
#define ILI9325_R37H    0x37    /* Gamma Control 6  */
#define ILI9325_R38H    0x38    /* Gamma Control 7  */
#define ILI9325_R39H    0x39    /* Gamma Control 8  */
#define ILI9325_R3CH    0x3C    /* Gamma Control 9  */
#define ILI9325_R3DH    0x3D    /* Gamma Control 10 */

#define ILI9325_R50H    0x50    /* Horizontal Address Start Position */
#define ILI9325_R51H    0x51    /* Horizontal Address End Position   */
#define ILI9325_R52H    0x52    /* Vertical Address Start Position   */
#define ILI9325_R53H    0x53    /* Vertical Address End Position     */

#define ILI9325_R60H    0x60    /* Driver Output Control 2    */
#define ILI9325_R60H_GS                ((uint16_t)0x8000)
#define ILI9325_R61H    0x61    /* Base Image Display Control */
#define ILI9325_R6AH    0x6A    /* Vertical Scroll Control    */

#define ILI9325_R80H    0x80    /* Partial Image 1 Display Position  */
#define ILI9325_R81H    0x81    /* Partial Image 1 Area (Start Line) */
#define ILI9325_R82H    0x82    /* Partial Image 1 Area (End Line)   */
#define ILI9325_R83H    0x83    /* Partial Image 2 Display Position  */
#define ILI9325_R84H    0x84    /* Partial Image 2 Area (Start Line) */
#define ILI9325_R85H    0x85    /* Partial Image 2 Area (End Line)   */

#define ILI9325_R90H    0x90    /* Panel Interface Control 1 */
#define ILI9325_R92H    0x92    /* Panel Interface Control 2 */
#define ILI9325_R95H    0x95    /* Panel Interface Control 4 */

#define ILI9325_RA1H    0xA1    /* OTP VCM Programming Control */
#define ILI9325_RA2H    0xA2    /* OTP VCM Status and Enable   */
#define ILI9325_RA5H    0xA5    /* OTP Programming ID Key      */

/*----------------------------------------------------------------------------
 *        Types
 *----------------------------------------------------------------------------*/

typedef volatile uint8_t REG8;

/*----------------------------------------------------------------------------
 *        Marcos
 *----------------------------------------------------------------------------*/

#define BOARD_LCD_RS     (1 << 1)
    // LCD index register address
#define LCD_IR(baseAddr) (*((REG8 *)(baseAddr)))
    // LCD status register address
#define LCD_SR(baseAddr) (*((REG8 *)(baseAddr)))
    // LCD data address
#define LCD_D(baseAddr)  (*((REG8 *)((uint32_t)(baseAddr) + BOARD_LCD_RS)))


#endif /* #ifndef ILI9325 */
