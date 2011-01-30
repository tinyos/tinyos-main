/*
 * Copyright (c) 2011 University of Utah.
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
 * - Neither the name of the copyright holder nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * COPYRIGHT HOLDER OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * Heavily inspired by the at91 library.
 *
 * @author Thomas Schmid
 */

#include "ili9325.h"

module Ili9325C
{
    uses
    {
        interface Timer<TMilli> as InitTimer;
    }

    provides interface Ili9325;
}
implementation
{

    enum {
        INIT0,
        INIT1,
        INIT2,
        INIT3,
        INIT4,
    };

    void* spLcdBase;

    uint8_t initState = INIT0;
    /**
     * \brief Write data to LCD Register.
     *
     * \param reg   Register address.
     * \param data  Data to be written.
     */
    async command void Ili9325.writeReg( void *pLcdBase, uint8_t reg, uint16_t data )
    {
        LCD_IR(pLcdBase) = 0;
        LCD_IR(pLcdBase) = reg;
        LCD_D(pLcdBase)  = (data >> 8) & 0xFF;
        LCD_D(pLcdBase)  = data & 0xFF;
    }

    /**
     * \brief Read data from LCD Register.
     *
     * \param reg   Register address.
     *
     * \return      Readed data.
     */
    async command uint16_t Ili9325.readReg(void *pLcdBase,  uint8_t reg )
    {
        uint16_t value;

        LCD_IR(pLcdBase) = 0;
        LCD_IR(pLcdBase) = reg;

        value = LCD_D(pLcdBase);
        value = (value << 8) | LCD_D(pLcdBase);

        return value;
    }


    /**
     * \brief Prepare to write GRAM data.
     */
    async command void Ili9325.writeRAM_Prepare( void *pLcdBase)
    {
        LCD_IR(pLcdBase) = 0 ;
        LCD_IR(pLcdBase) = ILI9325_R22H ; /* Write Data to GRAM (R22h)  */
    }

    /**
     * \brief Write data to LCD GRAM.
     *
     * \param color  24-bits RGB color.
     */
    async command void Ili9325.writeRAM(void *pLcdBase, uint32_t dwColor )
    {
        LCD_D(pLcdBase) = ((dwColor >> 16) & 0xFF);
        LCD_D(pLcdBase) = ((dwColor >> 8) & 0xFF);
        LCD_D(pLcdBase) = (dwColor & 0xFF);
    }

    /**
     * \brief Prepare to read GRAM data.
     */
    async command void Ili9325.readRAM_Prepare( void *pLcdBase)
    {
        LCD_IR(pLcdBase) = 0 ;
        LCD_IR(pLcdBase) = ILI9325_R22H ; /* Write Data to GRAM (R22h)  */
    }

    /**
     * \brief Read data to LCD GRAM.
     *
     * \return color  24-bits RGB color.
     */
    async command uint16_t Ili9325.readRAM( void *pLcdBase)
    {
        uint8_t value[2];
        uint16_t color;

        value[0] = LCD_D(pLcdBase);       /* dummy read */
        value[1] = LCD_D(pLcdBase);       /* dummy read */
        value[0] = LCD_D(pLcdBase);       /* data upper byte */
        value[1] = LCD_D(pLcdBase);       /* data lower byte */

        color = ((value[0] << 8) | (value[1] & 0xff)); 
        return color;
    }

    /**
     * \brief Initialize the LCD controller.
     */
    command void Ili9325.initialize( void *pLcdBase)
    {
        uint16_t chipid ;

        switch(initState)
        {
            case INIT0:

                spLcdBase = pLcdBase;

                /* Check ILI9325 chipid */
                chipid = call Ili9325.readReg(pLcdBase, ILI9325_R00H ) ; /* Driver Code Read (R00h) */
                if ( chipid != ILI9325_DEVICE_CODE )
                {
                    signal Ili9325.initializeDone(FAIL);
                    return;
                }

                /* Turn off LCD */
                call Ili9325.powerDown(pLcdBase) ;

                /* Start initial sequence */
                call Ili9325.writeReg(pLcdBase, ILI9325_R10H, 0x0000); /* DSTB = LP = STB = 0 */
                call Ili9325.writeReg(pLcdBase, ILI9325_R00H, 0x0001); /* start internal OSC */
                call Ili9325.writeReg(pLcdBase, ILI9325_R01H, ILI9325_R01H_SS ) ; /* set SS and SM bit */
                call Ili9325.writeReg(pLcdBase, ILI9325_R02H, 0x0700); /* set 1 line inversion */
                //LCD_writeReg(ILI9325_R03H, 0xD030); /* set GRAM write direction and BGR=1. */
                call Ili9325.writeReg(pLcdBase, ILI9325_R04H, 0x0000); /* Resize register */
                call Ili9325.writeReg(pLcdBase, ILI9325_R08H, 0x0207); /* set the back porch and front porch */
                call Ili9325.writeReg(pLcdBase, ILI9325_R09H, 0x0000); /* set non-display area refresh cycle ISC[3:0] */
                call Ili9325.writeReg(pLcdBase, ILI9325_R0AH, 0x0000); /* FMARK function */
                call Ili9325.writeReg(pLcdBase, ILI9325_R0CH, 0x0000); /* RGB interface setting */
                call Ili9325.writeReg(pLcdBase, ILI9325_R0DH, 0x0000); /* Frame marker Position */
                call Ili9325.writeReg(pLcdBase, ILI9325_R0FH, 0x0000); /* RGB interface polarity */

                /* Power on sequence */
                call Ili9325.writeReg(pLcdBase, ILI9325_R10H, 0x0000); /* SAP, BT[3:0], AP, DSTB, SLP, STB */
                call Ili9325.writeReg(pLcdBase, ILI9325_R11H, 0x0000); /* DC1[2:0], DC0[2:0], VC[2:0] */
                call Ili9325.writeReg(pLcdBase, ILI9325_R12H, 0x0000); /* VREG1OUT voltage */
                call Ili9325.writeReg(pLcdBase, ILI9325_R13H, 0x0000); /* VDV[4:0] for VCOM amplitude */

                initState = INIT1;
                call InitTimer.startOneShot(200);
                break;
                
            case INIT1:

                call Ili9325.writeReg(pLcdBase, ILI9325_R10H, 0x1290); /* SAP, BT[3:0], AP, DSTB, SLP, STB */
                call Ili9325.writeReg(pLcdBase, ILI9325_R11H, 0x0227); /* DC1[2:0], DC0[2:0], VC[2:0] */

                initState = INIT2;
                call InitTimer.startOneShot(50);
                break;

            case INIT2:
                call Ili9325.writeReg(pLcdBase, ILI9325_R12H, 0x001B); /* Internal reference voltage= Vci; */
                initState = INIT3;
                call InitTimer.startOneShot(50);
                break;

            case INIT3:

                call Ili9325.writeReg(pLcdBase, ILI9325_R13H, 0x1100); /* Set VDV[4:0] for VCOM amplitude */
                call Ili9325.writeReg(pLcdBase, ILI9325_R29H, 0x0019); /* Set VCM[5:0] for VCOMH */
                call Ili9325.writeReg(pLcdBase, ILI9325_R2BH, 0x000D); /* Set Frame Rate */
                initState = INIT4;
                call InitTimer.startOneShot(50);
                break;

            case INIT4:

                /* Adjust the Gamma Curve */
                call Ili9325.writeReg(pLcdBase, ILI9325_R30H, 0x0000);
                call Ili9325.writeReg(pLcdBase, ILI9325_R31H, 0x0204);
                call Ili9325.writeReg(pLcdBase, ILI9325_R32H, 0x0200);
                call Ili9325.writeReg(pLcdBase, ILI9325_R35H, 0x0007);
                call Ili9325.writeReg(pLcdBase, ILI9325_R36H, 0x1404);
                call Ili9325.writeReg(pLcdBase, ILI9325_R37H, 0x0705);
                call Ili9325.writeReg(pLcdBase, ILI9325_R38H, 0x0305);
                call Ili9325.writeReg(pLcdBase, ILI9325_R39H, 0x0707);
                call Ili9325.writeReg(pLcdBase, ILI9325_R3CH, 0x0701);
                call Ili9325.writeReg(pLcdBase, ILI9325_R3DH, 0x000e);

                call Ili9325.setDisplayPortrait(pLcdBase, 0);

                /* Vertical Scrolling */
                call Ili9325.writeReg(pLcdBase, ILI9325_R61H, 0x0001 ) ;
                call Ili9325.writeReg(pLcdBase, ILI9325_R6AH, 0x0000 ) ;

                /* Partial Display Control */
                call Ili9325.writeReg(pLcdBase, ILI9325_R80H, 0x0000);
                call Ili9325.writeReg(pLcdBase, ILI9325_R81H, 0x0000);
                call Ili9325.writeReg(pLcdBase, ILI9325_R82H, 0x0000);
                call Ili9325.writeReg(pLcdBase, ILI9325_R83H, 0x0000);
                call Ili9325.writeReg(pLcdBase, ILI9325_R84H, 0x0000);
                call Ili9325.writeReg(pLcdBase, ILI9325_R85H, 0x0000);

                /* Panel Control */
                call Ili9325.writeReg(pLcdBase, ILI9325_R90H, 0x0010);
                call Ili9325.writeReg(pLcdBase, ILI9325_R92H, 0x0600);
                call Ili9325.writeReg(pLcdBase, ILI9325_R95H, 0x0110);

                call Ili9325.setWindow( pLcdBase, 0, 0, BOARD_LCD_WIDTH, BOARD_LCD_HEIGHT ) ;
                call Ili9325.setCursor( pLcdBase, 0, 0 ) ;
                initState = INIT0;
                signal Ili9325.initializeDone(SUCCESS);
                break;
        }
    }

    event void InitTimer.fired()
    {
        call Ili9325.initialize(spLcdBase);
    }

    /**
     * \brief Turn on the LCD.
     */
    command void Ili9325.on( void *pLcdBase )
    {
        /* Display Control 1 (R07h) */
        /* When BASEE = “1”, the base image is displayed. */
        /* GON and DTE Set the output level of gate driver G1 ~ G320 : Normal Display */
        /* D1=1 D0=1 BASEE=1: Base image display Operate */
        call Ili9325.writeReg(pLcdBase, ILI9325_R07H,   ILI9325_R07H_BASEE
                | ILI9325_R07H_GON | ILI9325_R07H_DTE
                | ILI9325_R07H_D1  | ILI9325_R07H_D0 ) ;
    }


    /**
     * \brief Turn off the LCD.
     */
    async command void Ili9325.off( void *pLcdBase)
    {
        /* Display Control 1 (R07h) */
        /* When BASEE = “0”, no base image is displayed. */
        /* When the display is turned off by setting D[1:0] = “00”, the ILI9325 internal display
           operation is halted completely. */
        /* PTDE1/0 = 0: turns off partial image. */
        call Ili9325.writeReg(pLcdBase, ILI9325_R07H, 0x00 ) ;
    }

    /**
     * \brief Power down the LCD.
     */
    async command void Ili9325.powerDown( void *pLcdBase)
    {
        /* Display Control 1 (R07h) */
        /* When BASEE = “0”, no base image is displayed. */
        /* GON and DTE Set the output level of gate driver G1 ~ G320 : Normal Display */
        /* D1=1 D0=1 BASEE=1: Base image display Operate */
        call Ili9325.writeReg(pLcdBase, ILI9325_R07H,   ILI9325_R07H_GON | ILI9325_R07H_DTE
                | ILI9325_R07H_D1  | ILI9325_R07H_D0 ) ;
    }

    /**
     * \brief Set cursor of LCD srceen.
     *
     * \param x  X-coordinate of upper-left corner on LCD.
     * \param y  Y-coordinate of upper-left corner on LCD.
     */
    async command void Ili9325.setCursor( void *pLcdBase, uint16_t x, uint16_t y )
    {
        /* GRAM Horizontal/Vertical Address Set (R20h, R21h) */
        call Ili9325.writeReg(pLcdBase, ILI9325_R20H, x ) ; /* column */
        call Ili9325.writeReg(pLcdBase, ILI9325_R21H, y ) ; /* row */
    }

    async command void Ili9325.setDisplayPortrait(void *pLcdBase, uint32_t dwRGB)
    {
        uint16_t dwValue = 0 ;

        /* When AM = “1”, the address is updated in vertical writing direction. */
        /* DFM Set the mode of transferring data to the internal RAM when TRI = “1”. */
        /* When TRI = “1”, data are transferred to the internal RAM in 8-bit x 3 transfers mode via the 8-bit interface. */
        /* Use the high speed write mode (HWM=1) */
        /* ORG = “1”: The original address “00000h” moves according to the I/D[1:0] setting.  */
        /* I/D[1:0] = 00 Horizontal : decrement Vertical :  decrement, AM=0:Horizontal */
        dwValue = ILI9325_R03H_AM | ILI9325_R03H_DFM | ILI9325_R03H_TRI | ILI9325_R03H_HWM; //| ILI9325_R03H_ORG ;

        if ( dwRGB == 0 )
        {
            /* BGR=”1”: Swap the RGB data to BGR in writing into GRAM. */
            dwValue |= ILI9325_R03H_BGR ;
        }
        call Ili9325.writeReg(pLcdBase,  ILI9325_R03H, dwValue ) ;

        //    LCD_WriteReg( ILI9325_R60H, (0x1d<<8)|0x00 ) ; /*Gate Scan Control */

        call Ili9325.setWindow( pLcdBase, 0, 0, BOARD_LCD_HEIGHT, BOARD_LCD_WIDTH ) ;

    }

    async command void Ili9325.setWindow( void *pLcdBase, uint32_t dwX, uint32_t dwY, uint32_t dwWidth, uint32_t dwHeight )
    {
        /* Horizontal and Vertical RAM Address Position (R50h, R51h, R52h, R53h) */

        /* Set Horizontal Address Start Position */
        call Ili9325.writeReg( pLcdBase, ILI9325_R50H, (uint16_t)dwX ) ;

        /* Set Horizontal Address End Position */
        call Ili9325.writeReg( pLcdBase, ILI9325_R51H, (uint16_t)dwX+dwWidth-1 ) ;

        /* Set Vertical Address Start Position */
        call Ili9325.writeReg( pLcdBase, ILI9325_R52H, (uint16_t)dwY ) ;

        /* Set Vertical Address End Position */
        call Ili9325.writeReg( pLcdBase, ILI9325_R53H, (uint16_t)dwY+dwHeight-1 ) ;
    }

    default event void Ili9325.initializeDone(error_t err) {};
}
