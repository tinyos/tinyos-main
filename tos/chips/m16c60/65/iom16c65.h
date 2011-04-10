/*--------------------------------------------------------------------------------*/
/*
 * Copyright (c) 2010 Eistec AB.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 * 3. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
 * SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
 * OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
 * IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
 * OF SUCH DAMAGE.
 *
 *--------------------------------------------------------------------------------*/

#ifndef __IOM16C65_H__
#define __IOM16C65_H__

/*--------------------------------------------------------------------------------*/
/* General register definitions                                                   */

union register8_t {
  struct {
    unsigned char bit0      :1;
    unsigned char bit1      :1;
    unsigned char bit2      :1;
    unsigned char bit3      :1;
    unsigned char bit4      :1;
    unsigned char bit5      :1;
    unsigned char bit6      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

union register16_t {
  struct {
    unsigned char bit0      :1;
    unsigned char bit1      :1;
    unsigned char bit2      :1;
    unsigned char bit3      :1;
    unsigned char bit4      :1;
    unsigned char bit5      :1;
    unsigned char bit6      :1;
    unsigned char bit7      :1;
    unsigned char bit8      :1;
    unsigned char bit9      :1;
    unsigned char bit10     :1;
    unsigned char bit11     :1;
    unsigned char bit12     :1;
    unsigned char bit13     :1;
    unsigned char bit14     :1;
    unsigned char bit15     :1;
  } BIT;
  struct {
    unsigned char BYTE0;
    unsigned char BYTE1;
  } BYTES;
  unsigned short WORD;
};

union register32_t {
  struct {
    unsigned char bit0      :1;
    unsigned char bit1      :1;
    unsigned char bit2      :1;
    unsigned char bit3      :1;
    unsigned char bit4      :1;
    unsigned char bit5      :1;
    unsigned char bit6      :1;
    unsigned char bit7      :1;
    unsigned char bit8      :1;
    unsigned char bit9      :1;
    unsigned char bit10     :1;
    unsigned char bit11     :1;
    unsigned char bit12     :1;
    unsigned char bit13     :1;
    unsigned char bit14     :1;
    unsigned char bit15     :1;
    unsigned char bit16     :1;
    unsigned char bit17     :1;
    unsigned char bit18     :1;
    unsigned char bit19     :1;
    unsigned char bit20     :1;
    unsigned char bit21     :1;
    unsigned char bit22     :1;
    unsigned char bit23     :1;
    unsigned char bit24     :1;
    unsigned char bit25     :1;
    unsigned char bit26     :1;
    unsigned char bit27     :1;
    unsigned char bit28     :1;
    unsigned char bit29     :1;
    unsigned char bit30     :1;
    unsigned char bit31     :1;
  } BIT;
  struct {
    unsigned char BYTE0;
    unsigned char BYTE1;
    unsigned char BYTE2;
    unsigned char BYTE3;
  } BYTES;
  struct {
    unsigned short WORD0;
    unsigned short WORD1;
  } WORDS;
  unsigned long dWORD;
};

/*--------------------------------------------------------------------------------*/
/* Processor Mode Register 0                                                      */

union pm0_t {
  struct {
    unsigned char PM00      :1;
    unsigned char PM01      :1;
    unsigned char PM02      :1;
    unsigned char PM03      :1;
    unsigned char PM04      :1;
    unsigned char PM05      :1;
    unsigned char PM06      :1;
    unsigned char PM07      :1;
  } BIT;
  unsigned char BYTE;
};

#define PM0         (*(volatile union pm0_t        *)(0x0004))

/*--------------------------------------------------------------------------------*/
/* Processor Mode Register 1                                                      */

union pm1_t {
  struct {
    unsigned char PM10      :1;
    unsigned char PM11      :1;
    unsigned char PM12      :1;
    unsigned char PM13      :1;
    unsigned char PM14      :1;
    unsigned char PM15      :1;
    unsigned char bit6      :1;
    unsigned char PM17      :1;
  } BIT;
  unsigned char BYTE;
};

#define PM1         (*(volatile union pm1_t        *)(0x0005))

/*--------------------------------------------------------------------------------*/
/* System Clock Control Register 0                                                */

union cm0_t {
  struct {
    unsigned char CM00      :1;
    unsigned char CM01      :1;
    unsigned char CM02      :1;
    unsigned char CM03      :1;
    unsigned char CM04      :1;
    unsigned char CM05      :1;
    unsigned char CM06      :1;
    unsigned char CM07      :1;
  } BIT;
  unsigned char BYTE;
};

#define CM0         (*(volatile union cm0_t        *)(0x0006))

/*--------------------------------------------------------------------------------*/
/* System Clock Control Register 1                                                */

union cm1_t {
  struct {
    unsigned char CM10      :1;
    unsigned char CM11      :1;
    unsigned char bit2      :1;
    unsigned char CM13      :1;
    unsigned char CM14      :1;
    unsigned char CM15      :1;
    unsigned char CM16      :1;
    unsigned char CM17      :1;
  } BIT;
  unsigned char BYTE;
};

#define CM1         (*(volatile union cm1_t        *)(0x0007))

/*--------------------------------------------------------------------------------*/
/* Chip Select Control Register                                                   */

union csr_t {
  struct {
    unsigned char CS0       :1;
    unsigned char CS1       :1;
    unsigned char CS2       :1;
    unsigned char CS3       :1;
    unsigned char CS0W      :1;
    unsigned char CS1W      :1;
    unsigned char CS2W      :1;
    unsigned char CS3W      :1;
  } BIT;
  unsigned char BYTE;
};

#define CSR         (*(volatile union csr_t        *)(0x0008))

/*--------------------------------------------------------------------------------*/
/* External Area Recovery Cycle Control Register                                  */

union ewr_t {
  struct {
    unsigned char EWR0      :1;
    unsigned char EWR1      :1;
    unsigned char bit2      :1;
    unsigned char bit3      :1;
    unsigned char bit4      :1;
    unsigned char bit5      :1;
    unsigned char bit6      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define EWR         (*(volatile union ewr_t        *)(0x0009))

/*--------------------------------------------------------------------------------*/
/* Protect Register                                                               */

union prcr_t {
  struct {
    unsigned char PRC0      :1;
    unsigned char PRC1      :1;
    unsigned char PRC2      :1;
    unsigned char PRC3      :1;
    unsigned char bit4      :1;
    unsigned char bit5      :1;
    unsigned char PRC6      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define PRCR        (*(volatile union prcr_t       *)(0x000A))

/*--------------------------------------------------------------------------------*/
/* Data Bank Register                                                             */

union dbr_t {
  struct {
    unsigned char bit0      :1;
    unsigned char bit1      :1;
    unsigned char OFS       :1;
    unsigned char BSR0      :1;
    unsigned char BSR1      :1;
    unsigned char BSR2      :1;
    unsigned char bit6      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define DBR         (*(volatile union dbr_t        *)(0x000B))

/*--------------------------------------------------------------------------------*/
/* Oscillation Stop Detection Register                                            */

union cm2_t {
  struct {
    unsigned char CM20      :1;
    unsigned char CM21      :1;
    unsigned char CM22      :1;
    unsigned char CM23      :1;
    unsigned char bit4      :1;
    unsigned char bit5      :1;
    unsigned char bit6      :1;
    unsigned char CM27      :1;
  } BIT;
  unsigned char BYTE;
};

#define CM2         (*(volatile union cm2_t        *)(0x000C))

/*--------------------------------------------------------------------------------*/
/* Program 2 Area Control Register                                                */

union prg2c_t {
  struct {
    unsigned char PRG2C0    :1;
    unsigned char IRON      :1;
    unsigned char bit2      :1;
    unsigned char bit3      :1;
    unsigned char bit4      :1;
    unsigned char bit5      :1;
    unsigned char bit6      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define PRG2C       (*(volatile union prg2c_t      *)(0x0010))

/*--------------------------------------------------------------------------------*/
/* External Area Wait Control Expansion Register                                  */

union ewc_t {
  struct {
    unsigned char EWC00     :1;
    unsigned char EWC01     :1;
    unsigned char EWC10     :1;
    unsigned char EWC11     :1;
    unsigned char EWC20     :1;
    unsigned char EWC21     :1;
    unsigned char EWC30     :1;
    unsigned char EWC31     :1;
  } BIT;
  unsigned char BYTE;
};

#define EWC         (*(volatile union ewc_t        *)(0x0011))

/*--------------------------------------------------------------------------------*/
/* Peripheral Clock Select Register                                               */

union pclkr_t {
  struct {
    unsigned char PCLK0     :1;
    unsigned char PCLK1     :1;
    unsigned char bit2      :1;
    unsigned char bit3      :1;
    unsigned char bit4      :1;
    unsigned char PCLK5     :1;
    unsigned char bit6      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define PCLKR       (*(volatile union pclkr_t      *)(0x0012))

/*--------------------------------------------------------------------------------*/
/* Clock Prescaler Reset Flag                                                     */

union cpsrf_t {
  struct {
    unsigned char bit0      :1;
    unsigned char bit1      :1;
    unsigned char bit2      :1;
    unsigned char bit3      :1;
    unsigned char bit4      :1;
    unsigned char bit5      :1;
    unsigned char bit6      :1;
    unsigned char CPSR      :1;
  } BIT;
  unsigned char BYTE;
};

#define CPSRF       (*(volatile union cpsrf_t      *)(0x0015))

/*--------------------------------------------------------------------------------*/
/* Reset Source Determine Register                                                */

union rstfr_t {
  struct {
    unsigned char CWR       :1;
    unsigned char HWR       :1;
    unsigned char SWR       :1;
    unsigned char WDR       :1;
    unsigned char LVD1R     :1;
    unsigned char LVD2R     :1;
    unsigned char OSDR      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define RSTFR       (*(volatile union rstfr_t      *)(0x0018))

/*--------------------------------------------------------------------------------*/
/* Voltage Detector 2 Flag Register                                               */

union vcr1_t {
  struct {
    unsigned char bit0      :1;
    unsigned char bit1      :1;
    unsigned char bit2      :1;
    unsigned char VC13      :1;
    unsigned char bit4      :1;
    unsigned char bit5      :1;
    unsigned char bit6      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define VCR1        (*(volatile union vcr1_t       *)(0x0019))

/*--------------------------------------------------------------------------------*/
/* Voltage Detector Operation Enable Register                                     */

union vcr2_t {
  struct {
    unsigned char bit0      :1;
    unsigned char bit1      :1;
    unsigned char bit2      :1;
    unsigned char bit3      :1;
    unsigned char bit4      :1;
    unsigned char VC25      :1;
    unsigned char VC26      :1;
    unsigned char VC27      :1;
  } BIT;
  unsigned char BYTE;
};

#define VCR2        (*(volatile union vcr2_t       *)(0x001A))

/*--------------------------------------------------------------------------------*/
/* Chip Select Expansion Control Register                                         */

union cse_t {
  struct {
    unsigned char CSE00W    :1;
    unsigned char CSE01W    :1;
    unsigned char CSE10W    :1;
    unsigned char CSE11W    :1;
    unsigned char CSE20W    :1;
    unsigned char CSE21W    :1;
    unsigned char CSE30W    :1;
    unsigned char CSE31W    :1;
  } BIT;
  unsigned char BYTE;
};

#define CSE         (*(volatile union cse_t        *)(0x001B))

/*--------------------------------------------------------------------------------*/
/* PLL Control Register 0                                                         */

union plc0_t {
  struct {
    unsigned char PLC00     :1;
    unsigned char PLC01     :1;
    unsigned char PLC02     :1;
    unsigned char bit3      :1;
    unsigned char PLC04     :1;
    unsigned char PLC05     :1;
    unsigned char bit6      :1;
    unsigned char PLC07     :1;
  } BIT;
  unsigned char BYTE;
};

#define PLC0        (*(volatile union plc0_t       *)(0x001C))

/*--------------------------------------------------------------------------------*/
/* Processor Mode Register 2                                                      */

union pm2_t {
  struct {
    unsigned char bit0      :1;
    unsigned char PM21      :1;
    unsigned char bit2      :1;
    unsigned char bit3      :1;
    unsigned char PM24      :1;
    unsigned char PM25      :1;
    unsigned char bit6      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define PM2         (*(volatile union pm2_t        *)(0x001E))

/*--------------------------------------------------------------------------------*/
/* 40 MHz On-Chip Oscillator Control Register 0                                   */

union fra0_t {
  struct {
    unsigned char FRA00     :1;
    unsigned char FRA01     :1;
    unsigned char bit2      :1;
    unsigned char bit3      :1;
    unsigned char bit4      :1;
    unsigned char bit5      :1;
    unsigned char bit6      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define FRA0        (*(volatile union fra0_t       *)(0x0022))

/*--------------------------------------------------------------------------------*/
/* Voltage Monitor Function Select Register                                       */

union vwce_t {
  struct {
    unsigned char VW12E     :1;
    unsigned char bit1      :1;
    unsigned char bit2      :1;
    unsigned char bit3      :1;
    unsigned char bit4      :1;
    unsigned char bit5      :1;
    unsigned char bit6      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define VWCE        (*(volatile union vwce_t       *)(0x0026))

/*--------------------------------------------------------------------------------*/
/* Voltage Detector 1 Level Select Register                                       */

union vd1ls_t {
  struct {
    unsigned char VD1LS0    :1;
    unsigned char VD1LS1    :1;
    unsigned char VD1LS2    :1;
    unsigned char VD1LS3    :1;
    unsigned char bit4      :1;
    unsigned char bit5      :1;
    unsigned char bit6      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define VD1LS       (*(volatile union vd1ls_t      *)(0x0028))

/*--------------------------------------------------------------------------------*/
/* Voltage Monitor 0 Control Register                                             */

union vw0c_t {
  struct {
    unsigned char VW0C0     :1;
    unsigned char VW0C1     :1;
    unsigned char bit2      :1;
    unsigned char bit3      :1;
    unsigned char VW0F0     :1;
    unsigned char VW0F1     :1;
    unsigned char bit6      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define VW0C        (*(volatile union vw0c_t       *)(0x002A))

/*--------------------------------------------------------------------------------*/
/* Voltage Monitor 1 Control Register                                             */

union vw1c_t {
  struct {
    unsigned char VW1C0     :1;
    unsigned char VW1C1     :1;
    unsigned char VW1C2     :1;
    unsigned char VW1C3     :1;
    unsigned char VW1F0     :1;
    unsigned char VW1F1     :1;
    unsigned char VW1C6     :1;
    unsigned char VW1C7     :1;
  } BIT;
  unsigned char BYTE;
};

#define VW1C        (*(volatile union vw1c_t       *)(0x002B))

/*--------------------------------------------------------------------------------*/
/* Voltage Monitor 2 Control Register                                             */

union vw2c_t {
  struct {
    unsigned char VW2C0     :1;
    unsigned char VW2C1     :1;
    unsigned char VW2C2     :1;
    unsigned char VW2C3     :1;
    unsigned char VW2F0     :1;
    unsigned char VW2F1     :1;
    unsigned char VW2C6     :1;
    unsigned char VW2C7     :1;
  } BIT;
  unsigned char BYTE;
};

#define VW2C        (*(volatile union vw2c_t       *)(0x002C))

/*--------------------------------------------------------------------------------*/
/* Interrupt Control Register 1                                                   */

union icr1_t {
  struct {
    unsigned char ILVL0     :1;
    unsigned char ILVL1     :1;
    unsigned char ILVL2     :1;
    unsigned char IR        :1;
    unsigned char bit4      :1;
    unsigned char bit5      :1;
    unsigned char bit6      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

/*--------------------------------------------------------------------------------*/
/* Interrupt Control Register 2                                                   */

union icr2_t {
  struct {
    unsigned char ILVL0     :1;
    unsigned char ILVL1     :1;
    unsigned char ILVL2     :1;
    unsigned char IR        :1;
    unsigned char POL       :1;
    unsigned char bit5      :1;
    unsigned char bit6      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

/*--------------------------------------------------------------------------------*/
/* INT7 Interrupt Control Register                                                */

#define INT7IC      (*(volatile union icr2_t       *)(0x0042))

/*--------------------------------------------------------------------------------*/
/* INT6 Interrupt Control Register                                                */

#define INT6IC      (*(volatile union icr2_t       *)(0x0043))

/*--------------------------------------------------------------------------------*/
/* INT3 Interrupt Control Register                                                */

#define INT3IC      (*(volatile union icr2_t       *)(0x0044))

/*--------------------------------------------------------------------------------*/
/* Timer B5 Interrupt Control Register                                            */

#define TB5IC       (*(volatile union icr1_t       *)(0x0045))

/*--------------------------------------------------------------------------------*/
/* Timer B4 Interrupt Control Register                                            */

#define TB4IC       (*(volatile union icr1_t       *)(0x0046))

/*--------------------------------------------------------------------------------*/
/* UART1 Bus Collision Detection Interrupt Control Register                       */

#define U1BCNIC     (*(volatile union icr1_t       *)(0x0046))

/*--------------------------------------------------------------------------------*/
/* Timer B3 Interrupt Control Register                                            */

#define TB3IC       (*(volatile union icr1_t       *)(0x0047))

/*--------------------------------------------------------------------------------*/
/* UART0 Bus Collision Detection Interrupt Control Register                       */

#define U0BCNIC     (*(volatile union icr1_t       *)(0x0047))

/*--------------------------------------------------------------------------------*/
/* SI/O4 Interrupt Control Register                                               */

#define S4IC        (*(volatile union icr2_t       *)(0x0048))

/*--------------------------------------------------------------------------------*/
/* INT5 Interrupt Control Register                                                */

#define INT5IC      (*(volatile union icr2_t       *)(0x0048))

/*--------------------------------------------------------------------------------*/
/* SI/O3 Interrupt Control Register                                               */

#define S3IC        (*(volatile union icr2_t       *)(0x0049))

/*--------------------------------------------------------------------------------*/
/* INT4 Interrupt Control Register                                                */

#define INT4IC      (*(volatile union icr2_t       *)(0x0049))

/*--------------------------------------------------------------------------------*/
/* UART2 Bus Collision Detection Interrupt Control Register                       */

#define BCNIC       (*(volatile union icr1_t       *)(0x004A))

/*--------------------------------------------------------------------------------*/
/* DMA0 Interrupt Control Register                                                */

#define DM0IC       (*(volatile union icr1_t       *)(0x004B))

/*--------------------------------------------------------------------------------*/
/* DMA1 Interrupt Control Register                                                */

#define DM1IC       (*(volatile union icr1_t       *)(0x004C))

/*--------------------------------------------------------------------------------*/
/* Key Input Interrupt Control Register                                           */

#define KUPIC       (*(volatile union icr1_t       *)(0x004D))

/*--------------------------------------------------------------------------------*/
/* A/D Conversion Interrupt Control Register                                      */

#define ADIC        (*(volatile union icr1_t       *)(0x004E))

/*--------------------------------------------------------------------------------*/
/* UART2 Transmit Interrupt Control Register                                      */

#define S2TIC       (*(volatile union icr1_t       *)(0x004F))

/*--------------------------------------------------------------------------------*/
/* UART2 Receive Interrupt Control Register                                       */

#define S2RIC       (*(volatile union icr1_t       *)(0x0050))

/*--------------------------------------------------------------------------------*/
/* UART0 Transmit Interrupt Control Register                                      */

#define S0TIC       (*(volatile union icr1_t       *)(0x0051))

/*--------------------------------------------------------------------------------*/
/* UART0 Receive Interrupt Control Register                                       */

#define S0RIC       (*(volatile union icr1_t       *)(0x0052))

/*--------------------------------------------------------------------------------*/
/* UART1 Transmit Interrupt Control Register                                      */

#define S1TIC       (*(volatile union icr1_t       *)(0x0053))

/*--------------------------------------------------------------------------------*/
/* UART1 Receive Interrupt Control Register                                       */

#define S1RIC       (*(volatile union icr1_t       *)(0x0054))

/*--------------------------------------------------------------------------------*/
/* Timer A0 Interrupt Control Register                                            */

#define TA0IC       (*(volatile union icr1_t       *)(0x0055))

/*--------------------------------------------------------------------------------*/
/* Timer A1 Interrupt Control Register                                            */

#define TA1IC       (*(volatile union icr1_t       *)(0x0056))

/*--------------------------------------------------------------------------------*/
/* Timer A2 Interrupt Control Register                                            */

#define TA2IC       (*(volatile union icr1_t       *)(0x0057))

/*--------------------------------------------------------------------------------*/
/* Timer A3 Interrupt Control Register                                            */

#define TA3IC       (*(volatile union icr1_t       *)(0x0058))

/*--------------------------------------------------------------------------------*/
/* Timer A4 Interrupt Control Register                                            */

#define TA4IC       (*(volatile union icr1_t       *)(0x0059))

/*--------------------------------------------------------------------------------*/
/* Timer B0 Interrupt Control Register                                            */

#define TB0IC       (*(volatile union icr1_t       *)(0x005A))

/*--------------------------------------------------------------------------------*/
/* Timer B1 Interrupt Control Register                                            */

#define TB1IC       (*(volatile union icr1_t       *)(0x005B))

/*--------------------------------------------------------------------------------*/
/* Timer B2 Interrupt Control Register                                            */

#define TB2IC       (*(volatile union icr1_t       *)(0x005C))

/*--------------------------------------------------------------------------------*/
/* INT0 Interrupt Control Register                                                */

#define INT0IC      (*(volatile union icr2_t       *)(0x005D))

/*--------------------------------------------------------------------------------*/
/* INT1 Interrupt Control Register                                                */

#define INT1IC      (*(volatile union icr2_t       *)(0x005E))

/*--------------------------------------------------------------------------------*/
/* INT2 Interrupt Control Register                                                */

#define INT2IC      (*(volatile union icr2_t       *)(0x005F))

/*--------------------------------------------------------------------------------*/
/* DMA2 Interrupt Control Register                                                */

#define DM2IC       (*(volatile union icr1_t       *)(0x0069))

/*--------------------------------------------------------------------------------*/
/* DMA3 Interrupt Control Register                                                */

#define DM3IC       (*(volatile union icr1_t       *)(0x006A))

/*--------------------------------------------------------------------------------*/
/* UART5 Bus Collision Detection Interrupt Control Register                       */

#define U5BCNIC     (*(volatile union icr1_t       *)(0x006B))

/*--------------------------------------------------------------------------------*/
/* CEC1 Interrupt Control Register                                                */

#define CEC1IC      (*(volatile union icr1_t       *)(0x006B))

/*--------------------------------------------------------------------------------*/
/* UART5 Transmit Interrupt Control Register                                      */

#define S5TIC       (*(volatile union icr1_t       *)(0x006C))

/*--------------------------------------------------------------------------------*/
/* CEC2 Interrupt Control Register                                                */

#define CEC2IC      (*(volatile union icr1_t       *)(0x006C))

/*--------------------------------------------------------------------------------*/
/* UART5 Receive Interrupt Control Register                                       */

#define S5RIC       (*(volatile union icr1_t       *)(0x006D))

/*--------------------------------------------------------------------------------*/
/* UART6 Bus Collision Detection Interrupt Control Register                       */

#define U6BCNIC     (*(volatile union icr1_t       *)(0x006E))

/*--------------------------------------------------------------------------------*/
/* Real-Time Clock Periodic Interrupt Control Register                            */

#define RTCTIC      (*(volatile union icr1_t       *)(0x006E))

/*--------------------------------------------------------------------------------*/
/* UART6 Transmit Interrupt Control Register                                      */

#define S6TIC       (*(volatile union icr1_t       *)(0x006F))

/*--------------------------------------------------------------------------------*/
/* Real-Time Clock Compare Interrupt Control Register                             */

#define RTCCIC      (*(volatile union icr1_t       *)(0x006F))

/*--------------------------------------------------------------------------------*/
/* UART6 Receive Interrupt Control Register                                       */

#define S6RIC       (*(volatile union icr1_t       *)(0x0070))

/*--------------------------------------------------------------------------------*/
/* UART7 Bus Collision Detection Interrupt Control Register                       */

#define U7BCNIC     (*(volatile union icr1_t       *)(0x0071))

/*--------------------------------------------------------------------------------*/
/* Remote Control Signal Receiver 0 Interrupt Control Register                    */

#define PMC0IC      (*(volatile union icr1_t       *)(0x0071))

/*--------------------------------------------------------------------------------*/
/* UART7 Transmit Interrupt Control Register                                      */

#define S7TIC       (*(volatile union icr1_t       *)(0x0072))

/*--------------------------------------------------------------------------------*/
/* Remote Control Signal Receiver 1 Interrupt Control Register                    */

#define PMC1IC      (*(volatile union icr1_t       *)(0x0072))

/*--------------------------------------------------------------------------------*/
/* UART7 Receive Interrupt Control Register                                       */

#define S7RIC       (*(volatile union icr1_t       *)(0x0073))

/*--------------------------------------------------------------------------------*/
/* I2C-bus Interface Interrupt Control Register                                   */

#define IICIC       (*(volatile union icr1_t       *)(0x007B))

/*--------------------------------------------------------------------------------*/
/* SCL/SDA Interrupt Control Register                                             */

#define SCLDAIC     (*(volatile union icr1_t       *)(0x007C))

/*--------------------------------------------------------------------------------*/
/* DMA0 Source Pointer                                                            */

#define SAR0        (*(volatile union register32_t *)(0x0180))

/*--------------------------------------------------------------------------------*/
/* DMA0 Destination Pointer                                                       */

#define DAR0        (*(volatile union register32_t *)(0x0184))

/*--------------------------------------------------------------------------------*/
/* DMA0 Transfer Counter                                                          */

#define TCR0        (*(volatile union register16_t *)(0x0188))

/*--------------------------------------------------------------------------------*/
/* DMA0 Control Register                                                          */

union dm0con_t {
  struct {
    unsigned char DMBIT     :1;
    unsigned char DMASL     :1;
    unsigned char DMAS      :1;
    unsigned char DMAE      :1;
    unsigned char DSD       :1;
    unsigned char DAD       :1;
    unsigned char bit6      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define DM0CON      (*(volatile union dm0con_t     *)(0x018C))

/*--------------------------------------------------------------------------------*/
/* DMA1 Source Pointer                                                            */

#define SAR1        (*(volatile union register32_t *)(0x0190))

/*--------------------------------------------------------------------------------*/
/* DMA1 Destination Pointer                                                       */

#define DAR1        (*(volatile union register32_t *)(0x0194))

/*--------------------------------------------------------------------------------*/
/* DMA1 Transfer Counter                                                          */

#define TCR1        (*(volatile union register16_t *)(0x0198))

/*--------------------------------------------------------------------------------*/
/* DMA1 Control Register                                                          */

union dm1con_t {
  struct {
    unsigned char DMBIT     :1;
    unsigned char DMASL     :1;
    unsigned char DMAS      :1;
    unsigned char DMAE      :1;
    unsigned char DSD       :1;
    unsigned char DAD       :1;
    unsigned char bit6      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define DM1CON      (*(volatile union dm1con_t     *)(0x019C))

/*--------------------------------------------------------------------------------*/
/* DMA2 Source Pointer                                                            */

#define SAR2        (*(volatile union register32_t *)(0x01A0))

/*--------------------------------------------------------------------------------*/
/* DMA2 Destination Pointer                                                       */

#define DAR2        (*(volatile union register32_t *)(0x01A4))

/*--------------------------------------------------------------------------------*/
/* DMA2 Transfer Counter                                                          */

#define TCR2        (*(volatile union register16_t *)(0x01A8))

/*--------------------------------------------------------------------------------*/
/* DMA2 Control Register                                                          */

union dm2con_t {
  struct {
    unsigned char DMBIT     :1;
    unsigned char DMASL     :1;
    unsigned char DMAS      :1;
    unsigned char DMAE      :1;
    unsigned char DSD       :1;
    unsigned char DAD       :1;
    unsigned char bit6      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define DM2CON      (*(volatile union dm2con_t     *)(0x01AC))

/*--------------------------------------------------------------------------------*/
/* DMA3 Source Pointer                                                            */

#define SAR3        (*(volatile union register32_t *)(0x01B0))

/*--------------------------------------------------------------------------------*/
/* DMA3 Destination Pointer                                                       */

#define DAR3        (*(volatile union register32_t *)(0x01B4))

/*--------------------------------------------------------------------------------*/
/* DMA3 Transfer Counter                                                          */

#define TCR3        (*(volatile union register16_t *)(0x01B8))

/*--------------------------------------------------------------------------------*/
/* DMA3 Control Register                                                          */

union dm3con_t {
  struct {
    unsigned char DMBIT     :1;
    unsigned char DMASL     :1;
    unsigned char DMAS      :1;
    unsigned char DMAE      :1;
    unsigned char DSD       :1;
    unsigned char DAD       :1;
    unsigned char bit6      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define DM3CON      (*(volatile union dm3con_t     *)(0x01BC))

/*--------------------------------------------------------------------------------*/
/* Timer B0-1 Register                                                            */

#define TB01        (*(volatile union register16_t *)(0x01C0))

/*--------------------------------------------------------------------------------*/
/* Timer B1-1 Register                                                            */

#define TB11        (*(volatile union register16_t *)(0x01C2))

/*--------------------------------------------------------------------------------*/
/* Timer B2-1 Register                                                            */

#define TB21        (*(volatile union register16_t *)(0x01C4))

/*--------------------------------------------------------------------------------*/
/* Pulse Period/Pulse Width Measurement Mode Function Select Register 1           */

union ppwfs1_t {
  struct {
    unsigned char PPWFS10   :1;
    unsigned char PPWFS11   :1;
    unsigned char PPWFS12   :1;
    unsigned char bit3      :1;
    unsigned char bit4      :1;
    unsigned char bit5      :1;
    unsigned char bit6      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define PPWFS1      (*(volatile union ppwfs1_t     *)(0x01C6))

/*--------------------------------------------------------------------------------*/
/* Timer B Count Source Select Register 0                                         */

union tbcs0_t {
  struct {
    unsigned char TCS0      :1;
    unsigned char TCS1      :1;
    unsigned char TCS2      :1;
    unsigned char TCS3      :1;
    unsigned char TCS4      :1;
    unsigned char TCS5      :1;
    unsigned char TCS6      :1;
    unsigned char TCS7      :1;
  } BIT;
  unsigned char BYTE;
};

#define TBCS0       (*(volatile union tbcs0_t      *)(0x01C8))

/*--------------------------------------------------------------------------------*/
/* Timer B Count Source Select Register 1                                         */

union tbcs1_t {
  struct {
    unsigned char TCS0      :1;
    unsigned char TCS1      :1;
    unsigned char TCS2      :1;
    unsigned char TCS3      :1;
    unsigned char bit4      :1;
    unsigned char bit5      :1;
    unsigned char bit6      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define TBCS1       (*(volatile union tbcs1_t      *)(0x01C9))

/*--------------------------------------------------------------------------------*/
/* Timer AB Division Control Register 0                                           */

union tckdivc0_t {
  struct {
    unsigned char TCDIV00   :1;
    unsigned char bit1      :1;
    unsigned char bit2      :1;
    unsigned char bit3      :1;
    unsigned char bit4      :1;
    unsigned char bit5      :1;
    unsigned char bit6      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define TCKDIVC0    (*(volatile union tckdivc0_t   *)(0x01CB))

/*--------------------------------------------------------------------------------*/
/* Timer A Count Source Select Register 0                                         */

union tacs0_t {
  struct {
    unsigned char TCS0      :1;
    unsigned char TCS1      :1;
    unsigned char TCS2      :1;
    unsigned char TCS3      :1;
    unsigned char TCS4      :1;
    unsigned char TCS5      :1;
    unsigned char TCS6      :1;
    unsigned char TCS7      :1;
  } BIT;
  unsigned char BYTE;
};

#define TACS0       (*(volatile union tacs0_t      *)(0x01D0))

/*--------------------------------------------------------------------------------*/
/* Timer A Count Source Select Register 1                                         */

union tacs1_t {
  struct {
    unsigned char TCS0      :1;
    unsigned char TCS1      :1;
    unsigned char TCS2      :1;
    unsigned char TCS3      :1;
    unsigned char TCS4      :1;
    unsigned char TCS5      :1;
    unsigned char TCS6      :1;
    unsigned char TCS7      :1;
  } BIT;
  unsigned char BYTE;
};

#define TACS1       (*(volatile union tacs1_t      *)(0x01D1))

/*--------------------------------------------------------------------------------*/
/* Timer A Count Source Select Register 2                                         */

union tacs2_t {
  struct {
    unsigned char TCS0      :1;
    unsigned char TCS1      :1;
    unsigned char TCS2      :1;
    unsigned char TCS3      :1;
    unsigned char bit4      :1;
    unsigned char bit5      :1;
    unsigned char bit6      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define TACS2       (*(volatile union tacs2_t      *)(0x01D2))

/*--------------------------------------------------------------------------------*/
/* 16-Bit Pulse Width Modulation Mode Function Select Register                    */

union pwmfs_t {
  struct {
    unsigned char bit0      :1;
    unsigned char PWMFS1    :1;
    unsigned char PWMFS2    :1;
    unsigned char bit3      :1;
    unsigned char PWMFS4    :1;
    unsigned char bit5      :1;
    unsigned char bit6      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define PWMFS       (*(volatile union pwmfs_t      *)(0x01D4))

/*--------------------------------------------------------------------------------*/
/* Timer A Waveform Output Function Select Register                               */

union tapofs_t {
  struct {
    unsigned char POFS0     :1;
    unsigned char POFS1     :1;
    unsigned char POFS2     :1;
    unsigned char POFS3     :1;
    unsigned char POFS4     :1;
    unsigned char bit5      :1;
    unsigned char bit6      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define TAPOFS      (*(volatile union tapofs_t     *)(0x01D5))

/*--------------------------------------------------------------------------------*/
/* Timer A Output Waveform Change Enable Register                                 */

union taow_t {
  struct {
    unsigned char bit0      :1;
    unsigned char TA1OW     :1;
    unsigned char TA2OW     :1;
    unsigned char bit3      :1;
    unsigned char TA4OW     :1;
    unsigned char bit5      :1;
    unsigned char bit6      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define TAOW        (*(volatile union taow_t       *)(0x01D8))

/*--------------------------------------------------------------------------------*/
/* Three-Phase Protect Control Register                                           */

union tprc_t {
  struct {
    unsigned char TPRC0     :1;
    unsigned char bit1      :1;
    unsigned char bit2      :1;
    unsigned char bit3      :1;
    unsigned char bit4      :1;
    unsigned char bit5      :1;
    unsigned char bit6      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define TPRC        (*(volatile union tprc_t       *)(0x01DA))

/*--------------------------------------------------------------------------------*/
/* Timer B3-1 Register                                                            */

#define TB31        (*(volatile union register16_t *)(0x01E0))

/*--------------------------------------------------------------------------------*/
/* Timer B4-1 Register                                                            */

#define TB41        (*(volatile union register16_t *)(0x01E2))

/*--------------------------------------------------------------------------------*/
/* Timer B5-1 Register                                                            */

#define TB51        (*(volatile union register16_t *)(0x01E4))

/*--------------------------------------------------------------------------------*/
/* Pulse Period/Pulse Width Measurement Mode Function Select Register 2           */

union ppwfs2_t {
  struct {
    unsigned char PPWFS20   :1;
    unsigned char PPWFS21   :1;
    unsigned char PPWFS22   :1;
    unsigned char bit3      :1;
    unsigned char bit4      :1;
    unsigned char bit5      :1;
    unsigned char bit6      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define PPWFS2      (*(volatile union ppwfs2_t     *)(0x01E6))

/*--------------------------------------------------------------------------------*/
/* Timer B Count Source Select Register 2                                         */

union tbcs2_t {
  struct {
    unsigned char TCS0      :1;
    unsigned char TCS1      :1;
    unsigned char TCS2      :1;
    unsigned char TCS3      :1;
    unsigned char TCS4      :1;
    unsigned char TCS5      :1;
    unsigned char TCS6      :1;
    unsigned char TCS7      :1;
  } BIT;
  unsigned char BYTE;
};

#define TBCS2       (*(volatile union tbcs2_t      *)(0x01E8))

/*--------------------------------------------------------------------------------*/
/* Timer B Count Source Select Register 3                                         */

union tbcs3_t {
  struct {
    unsigned char TCS0      :1;
    unsigned char TCS1      :1;
    unsigned char TCS2      :1;
    unsigned char TCS3      :1;
    unsigned char bit4      :1;
    unsigned char bit5      :1;
    unsigned char bit6      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define TBCS3       (*(volatile union tbcs3_t      *)(0x01E9))

/*--------------------------------------------------------------------------------*/
/* PMC0 Function Select Register 0                                                */

union pmc0con0_t {
  struct {
    unsigned char EN        :1;
    unsigned char SINV      :1;
    unsigned char FIL       :1;
    unsigned char EHOLD     :1;
    unsigned char HDEN      :1;
    unsigned char SDEN      :1;
    unsigned char DRINT0    :1;
    unsigned char DRINT1    :1;
  } BIT;
  unsigned char BYTE;
};

#define PMC0CON0    (*(volatile union pmc0con0_t   *)(0x01F0))

/*--------------------------------------------------------------------------------*/
/* PMC0 Function Select Register 1                                                */

union pmc0con1_t {
  struct {
    unsigned char TYP0      :1;
    unsigned char TYP1      :1;
    unsigned char CSS       :1;
    unsigned char bit3      :1;
    unsigned char bit4      :1;
    unsigned char bit5      :1;
    unsigned char EXSDEN    :1;
    unsigned char EXHDEN    :1;
  } BIT;
  unsigned char BYTE;
};

#define PMC0CON1    (*(volatile union pmc0con1_t   *)(0x01F1))

/*--------------------------------------------------------------------------------*/
/* PMC0 Function Select Register 2                                                */

union pmc0con2_t {
  struct {
    unsigned char ENFLG     :1;
    unsigned char bit1      :1;
    unsigned char bit2      :1;
    unsigned char INFLG     :1;
    unsigned char CEFLG     :1;
    unsigned char CEINT     :1;
    unsigned char PSEL0     :1;
    unsigned char PSEL1     :1;
  } BIT;
  unsigned char BYTE;
};

#define PMC0CON2    (*(volatile union pmc0con2_t   *)(0x01F2))

/*--------------------------------------------------------------------------------*/
/* PMC0 Function Select Register 3                                                */

union pmc0con3_t {
  struct {
    unsigned char CRE       :1;
    unsigned char CFR       :1;
    unsigned char CST       :1;
    unsigned char PD        :1;
    unsigned char CSRC0     :1;
    unsigned char CSRC1     :1;
    unsigned char CDIV0     :1;
    unsigned char CDIV1     :1;
  } BIT;
  unsigned char BYTE;
};

#define PMC0CON3    (*(volatile union pmc0con3_t   *)(0x01F3))

/*--------------------------------------------------------------------------------*/
/* PMC0 Status Register                                                           */

union pmc0sts_t {
  struct {
    unsigned char CPFLG     :1;
    unsigned char REFLG     :1;
    unsigned char DRFLG     :1;
    unsigned char BFULFLG   :1;
    unsigned char PTHDFLG   :1;
    unsigned char PTD0FLG   :1;
    unsigned char PTD1FLG   :1;
    unsigned char SDFLG     :1;
  } BIT;
  unsigned char BYTE;
};

#define PMC0STS     (*(volatile union pmc0sts_t    *)(0x01F4))

/*--------------------------------------------------------------------------------*/
/* PMC0 Interrupt Source Select Register                                          */

union pmc0int_t {
  struct {
    unsigned char CPINT     :1;
    unsigned char REINT     :1;
    unsigned char DRINT     :1;
    unsigned char BFULINT   :1;
    unsigned char PTHDINT   :1;
    unsigned char PTDINT    :1;
    unsigned char TIMINT    :1;
    unsigned char SDINT     :1;
  } BIT;
  unsigned char BYTE;
};

#define PMC0INT     (*(volatile union pmc0int_t    *)(0x01F5))

/*--------------------------------------------------------------------------------*/
/* PMC0 Compare Control Register                                                  */

union pmc0cpc_t {
  struct {
    unsigned char CPN0      :1;
    unsigned char CPN1      :1;
    unsigned char CPN2      :1;
    unsigned char bit3      :1;
    unsigned char CPEN      :1;
    unsigned char bit5      :1;
    unsigned char bit6      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define PMC0CPC     (*(volatile union pmc0cpc_t    *)(0x01F6))

/*--------------------------------------------------------------------------------*/
/* PMC0 Compare Data Register                                                     */

#define PMC0CPD     (*(volatile union register8_t  *)(0x01F7))

/*--------------------------------------------------------------------------------*/
/* PMC1 Function Select Register 0                                                */

union pmc1con0_t {
  struct {
    unsigned char EN        :1;
    unsigned char SINV      :1;
    unsigned char FIL       :1;
    unsigned char bit3      :1;
    unsigned char HDEN      :1;
    unsigned char bit5      :1;
    unsigned char bit6      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define PMC1CON0    (*(volatile union pmc1con0_t   *)(0x01F8))

/*--------------------------------------------------------------------------------*/
/* PMC1 Function Select Register 1                                                */

union pmc1con1_t {
  struct {
    unsigned char TYP0      :1;
    unsigned char TYP1      :1;
    unsigned char bit2      :1;
    unsigned char bit3      :1;
    unsigned char bit4      :1;
    unsigned char bit5      :1;
    unsigned char bit6      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define PMC1CON1    (*(volatile union pmc1con1_t   *)(0x01F9))

/*--------------------------------------------------------------------------------*/
/* PMC1 Function Select Register 2                                                */

union pmc1con2_t {
  struct {
    unsigned char ENFLG     :1;
    unsigned char bit1      :1;
    unsigned char bit2      :1;
    unsigned char INFLG     :1;
    unsigned char CEFLG     :1;
    unsigned char CEINT     :1;
    unsigned char PSEL0     :1;
    unsigned char PSEL1     :1;
  } BIT;
  unsigned char BYTE;
};

#define PMC1CON2    (*(volatile union pmc1con2_t   *)(0x01FA))

/*--------------------------------------------------------------------------------*/
/* PMC1 Function Select Register 3                                                */

union pmc1con3_t {
  struct {
    unsigned char CRE       :1;
    unsigned char CFR       :1;
    unsigned char CST       :1;
    unsigned char PD        :1;
    unsigned char CSRC0     :1;
    unsigned char CSRC1     :1;
    unsigned char CDIV0     :1;
    unsigned char CDIV1     :1;
  } BIT;
  unsigned char BYTE;
};

#define PMC1CON3    (*(volatile union pmc1con3_t   *)(0x01FB))

/*--------------------------------------------------------------------------------*/
/* PMC1 Status Register                                                           */

union pmc1sts_t {
  struct {
    unsigned char bit0      :1;
    unsigned char REFLG     :1;
    unsigned char DRFLG     :1;
    unsigned char bit3      :1;
    unsigned char PTHDFLG   :1;
    unsigned char PTD0FLG   :1;
    unsigned char PTD1FLG   :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define PMC1STS     (*(volatile union pmc1sts_t    *)(0x01FC))

/*--------------------------------------------------------------------------------*/
/* PMC1 Interrupt Source Select Register                                          */

union pmc1int_t {
  struct {
    unsigned char bit0      :1;
    unsigned char REINT     :1;
    unsigned char DRINT     :1;
    unsigned char bit3      :1;
    unsigned char PTHDINT   :1;
    unsigned char PTDINT    :1;
    unsigned char TIMINT    :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define PMC1INT     (*(volatile union register8_t  *)(0x01FD))

/*--------------------------------------------------------------------------------*/
/* Interrupt Source Select Register 3                                             */

union ifsr3a_t {
  struct {
    unsigned char IFSR30    :1;
    unsigned char IFSR31    :1;
    unsigned char bit2      :1;
    unsigned char IFSR33    :1;
    unsigned char IFSR34    :1;
    unsigned char IFSR35    :1;
    unsigned char IFSR36    :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define IFSR3A      (*(volatile union ifsr3a_t     *)(0x0205))

/*--------------------------------------------------------------------------------*/
/* Interrupt Source Select Register 2                                             */

union ifsr2a_t {
  struct {
    unsigned char bit0      :1;
    unsigned char bit1      :1;
    unsigned char IFSR22    :1;
    unsigned char IFSR23    :1;
    unsigned char IFSR24    :1;
    unsigned char IFSR25    :1;
    unsigned char IFSR26    :1;
    unsigned char IFSR27    :1;
  } BIT;
  unsigned char BYTE;
};

#define IFSR2A      (*(volatile union ifsr2a_t     *)(0x0206))

/*--------------------------------------------------------------------------------*/
/* Interrupt Source Select Register                                               */

union ifsr_t {
  struct {
    unsigned char IFSR0     :1;
    unsigned char IFSR1     :1;
    unsigned char IFSR2     :1;
    unsigned char IFSR3     :1;
    unsigned char IFSR4     :1;
    unsigned char IFSR5     :1;
    unsigned char IFSR6     :1;
    unsigned char IFSR7     :1;
  } BIT;
  unsigned char BYTE;
};

#define IFSR        (*(volatile union ifsr_t       *)(0x0207))

/*--------------------------------------------------------------------------------*/
/* Address Match Interrupt Enable Register                                        */

union aier_t {
  struct {
    unsigned char AIER0     :1;
    unsigned char AIER1     :1;
    unsigned char bit2      :1;
    unsigned char bit3      :1;
    unsigned char bit4      :1;
    unsigned char bit5      :1;
    unsigned char bit6      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define AIER        (*(volatile union aier_t       *)(0x020E))

/*--------------------------------------------------------------------------------*/
/* Address Match Interrupt Enable Register 2                                      */

union aier2_t {
  struct {
    unsigned char AIER20    :1;
    unsigned char AIER21    :1;
    unsigned char bit2      :1;
    unsigned char bit3      :1;
    unsigned char bit4      :1;
    unsigned char bit5      :1;
    unsigned char bit6      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define AIER2       (*(volatile union aier2_t      *)(0x020F))

/*--------------------------------------------------------------------------------*/
/* Address Match Interrupt Register 0                                             */

#define RMAD0       (*(volatile union register32_t *)(0x0210))

/*--------------------------------------------------------------------------------*/
/* Address Match Interrupt Register 1                                             */

#define RMAD1       (*(volatile union register32_t *)(0x0214))

/*--------------------------------------------------------------------------------*/
/* Address Match Interrupt Register 2                                             */

#define RMAD2       (*(volatile union register32_t *)(0x0218))

/*--------------------------------------------------------------------------------*/
/* Address Match Interrupt Register 3                                             */

#define RMAD3       (*(volatile union register32_t *)(0x021C))

/*--------------------------------------------------------------------------------*/
/* Flash Memory Control Register 0                                                */

union fmr0_t {
  struct {
    unsigned char FMR00     :1;
    unsigned char FMR01     :1;
    unsigned char FMR02     :1;
    unsigned char FMSTP     :1;
    unsigned char bit4      :1;
    unsigned char bit5      :1;
    unsigned char FMR06     :1;
    unsigned char FMR07     :1;
  } BIT;
  unsigned char BYTE;
};

#define FMR0        (*(volatile union fmr0_t       *)(0x0220))

/*--------------------------------------------------------------------------------*/
/* Flash Memory Control Register 1                                                */

union fmr1_t {
  struct {
    unsigned char bit0      :1;
    unsigned char FMR11     :1;
    unsigned char bit2      :1;
    unsigned char bit3      :1;
    unsigned char bit4      :1;
    unsigned char bit5      :1;
    unsigned char FMR16     :1;
    unsigned char FMR17     :1;
  } BIT;
  unsigned char BYTE;
};

#define FMR1        (*(volatile union fmr1_t       *)(0x0221))

/*--------------------------------------------------------------------------------*/
/* Flash Memory Control Register 2                                                */

union fmr2_t {
  struct {
    unsigned char bit0      :1;
    unsigned char bit1      :1;
    unsigned char FMR22     :1;
    unsigned char FMR23     :1;
    unsigned char bit4      :1;
    unsigned char bit5      :1;
    unsigned char bit6      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define FMR2        (*(volatile union fmr2_t       *)(0x0222))

/*--------------------------------------------------------------------------------*/
/* Flash Memory Control Register 6                                                */

union fmr6_t {
  struct {
    unsigned char FMR60     :1;
    unsigned char FMR61     :1;
    unsigned char bit2      :1;
    unsigned char bit3      :1;
    unsigned char bit4      :1;
    unsigned char bit5      :1;
    unsigned char bit6      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define FMR6        (*(volatile union fmr6_t       *)(0x0230))

/*--------------------------------------------------------------------------------*/
/* UART0 Special Mode Register 4                                                  */

union u0smr4_t {
  struct {
    unsigned char STAREQ    :1;
    unsigned char RSTAREQ   :1;
    unsigned char STPREQ    :1;
    unsigned char STSPSEL   :1;
    unsigned char ACKD      :1;
    unsigned char ACKC      :1;
    unsigned char SCLHI     :1;
    unsigned char SWC9      :1;
  } BIT;
  unsigned char BYTE;
};

#define U0SMR4      (*(volatile union u0smr4_t     *)(0x0244))

/*--------------------------------------------------------------------------------*/
/* UART0 Special Mode Register 3                                                  */

union u0smr3_t {
  struct {
    unsigned char bit0      :1;
    unsigned char CKPH      :1;
    unsigned char bit2      :1;
    unsigned char NODC      :1;
    unsigned char bit4      :1;
    unsigned char DL0       :1;
    unsigned char DL1       :1;
    unsigned char DL2       :1;
  } BIT;
  unsigned char BYTE;
};

#define U0SMR3      (*(volatile union u0smr3_t     *)(0x0245))

/*--------------------------------------------------------------------------------*/
/* UART0 Special Mode Register 2                                                  */

union u0smr2_t {
  struct {
    unsigned char IICM2     :1;
    unsigned char CSC       :1;
    unsigned char SWC       :1;
    unsigned char ALS       :1;
    unsigned char STAC      :1;
    unsigned char SWC2      :1;
    unsigned char SDHI      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define U0SMR2      (*(volatile union u0smr2_t     *)(0x0246))

/*--------------------------------------------------------------------------------*/
/* UART0 Special Mode Register                                                    */

union u0smr_t {
  struct {
    unsigned char IICM      :1;
    unsigned char ABC       :1;
    unsigned char BBS       :1;
    unsigned char bit3      :1;
    unsigned char ABSCS     :1;
    unsigned char ACSE      :1;
    unsigned char SSS       :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define U0SMR       (*(volatile union u0smr_t      *)(0x0247))

/*--------------------------------------------------------------------------------*/
/* UART0 Transmit/Receive Mode Register                                           */

union u0mr_t {
  struct {
    unsigned char SMD0      :1;
    unsigned char SMD1      :1;
    unsigned char SMD2      :1;
    unsigned char CKDIR     :1;
    unsigned char STPS      :1;
    unsigned char PRY       :1;
    unsigned char PRYE      :1;
    unsigned char IOPOL     :1;
  } BIT;
  unsigned char BYTE;
};

#define U0MR        (*(volatile union u0mr_t       *)(0x0248))

/*--------------------------------------------------------------------------------*/
/* UART0 Bit Rate Register                                                        */

#define U0BRG       (*(volatile unsigned char  *)(0x0249))

/*--------------------------------------------------------------------------------*/
/* UART0 Transmit Buffer Register                                                 */
union st_u0tb {				/* UART0 Transmit buffer register 16 bit ; Use "MOV" instruction when writing to this register. */
   struct{
	unsigned char U0TBL;     /* UART0 Transmit buffer register low  8 bit 	 */
	unsigned char U0TBH;     /* UART0 Transmit buffer register high 8 bit 	 */
   } BYTE;					 /* Byte access					   				 */
   unsigned short   WORD;	 /* Word Access					   				 */
};
#define U0TB        (*(volatile union st_u0tb *)(0x024A))

/*--------------------------------------------------------------------------------*/
/* UART0 Transmit/Receive Control Register 0                                      */

union u0c0_t {
  struct {
    unsigned char CLK0      :1;
    unsigned char CLK1      :1;
    unsigned char CRS       :1;
    unsigned char TXEPT     :1;
    unsigned char CRD       :1;
    unsigned char NCH       :1;
    unsigned char CKPOL     :1;
    unsigned char UFORM     :1;
  } BIT;
  unsigned char BYTE;
};

#define U0C0        (*(volatile union u0c0_t       *)(0x024C))

/*--------------------------------------------------------------------------------*/
/* UART0 Transmit/Receive Control Register 1                                      */

union u0c1_t {
  struct {
    unsigned char TE        :1;
    unsigned char TI        :1;
    unsigned char RE        :1;
    unsigned char RI        :1;
    unsigned char bit4      :1;
    unsigned char bit5      :1;
    unsigned char U0LCH     :1;
    unsigned char U0ERE     :1;
  } BIT;
  unsigned char BYTE;
};

#define U0C1        (*(volatile union u0c1_t       *)(0x024D))

/*--------------------------------------------------------------------------------*/
/* UART0 Receive Buffer Register                                                  */

union u0rb_t {
  struct {
    unsigned char bit0      :1;
    unsigned char bit1      :1;
    unsigned char bit2      :1;
    unsigned char bit3      :1;
    unsigned char bit4      :1;
    unsigned char bit5      :1;
    unsigned char bit6      :1;
    unsigned char bit7      :1;
    unsigned char bit8      :1;
    unsigned char bit9      :1;
    unsigned char bit10     :1;
    unsigned char ABT       :1;
    unsigned char OER       :1;
    unsigned char FER       :1;
    unsigned char PER       :1;
    unsigned char SUM       :1;
  } BIT;
  struct {
    unsigned char BYTE0;
    unsigned char BYTE1;
  } BYTES;
  struct {
    unsigned char U0RBL;
    unsigned char U0RBH;
  } BYTE;
  unsigned short WORD;
};

#define U0RB        (*(volatile union u0rb_t       *)(0x024E))

/*--------------------------------------------------------------------------------*/
/* UART Transmit/Receive Control Register 2                                       */

union ucon_t {
  struct {
    unsigned char U0IRS     :1;
    unsigned char U1IRS     :1;
    unsigned char U0RRM     :1;
    unsigned char U1RRM     :1;
    unsigned char CLKMD0    :1;
    unsigned char CLKMD1    :1;
    unsigned char RCSP      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define UCON        (*(volatile union ucon_t       *)(0x0250))

/*--------------------------------------------------------------------------------*/
/* UART Clock Select Register                                                     */

union uclksel0_t {
  struct {
    unsigned char bit0      :1;
    unsigned char bit1      :1;
    unsigned char OCOSEL0   :1;
    unsigned char OCOSEL1   :1;
    unsigned char bit4      :1;
    unsigned char bit5      :1;
    unsigned char bit6      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define UCLKSEL0    (*(volatile union uclksel0_t   *)(0x0252))

/*--------------------------------------------------------------------------------*/
/* UART1 Special Mode Register 4                                                  */

union u1smr4_t {
  struct {
    unsigned char STAREQ    :1;
    unsigned char RSTAREQ   :1;
    unsigned char STPREQ    :1;
    unsigned char STSPSEL   :1;
    unsigned char ACKD      :1;
    unsigned char ACKC      :1;
    unsigned char SCLHI     :1;
    unsigned char SWC9      :1;
  } BIT;
  unsigned char BYTE;
};

#define U1SMR4      (*(volatile union u1smr4_t     *)(0x0254))

/*--------------------------------------------------------------------------------*/
/* UART1 Special Mode Register 3                                                  */

union u1smr3_t {
  struct {
    unsigned char bit0      :1;
    unsigned char CKPH      :1;
    unsigned char bit2      :1;
    unsigned char NODC      :1;
    unsigned char bit4      :1;
    unsigned char DL0       :1;
    unsigned char DL1       :1;
    unsigned char DL2       :1;
  } BIT;
  unsigned char BYTE;
};

#define U1SMR3      (*(volatile union u1smr3_t     *)(0x0255))

/*--------------------------------------------------------------------------------*/
/* UART1 Special Mode Register 2                                                  */

union u1smr2_t {
  struct {
    unsigned char IICM2     :1;
    unsigned char CSC       :1;
    unsigned char SWC       :1;
    unsigned char ALS       :1;
    unsigned char STAC      :1;
    unsigned char SWC2      :1;
    unsigned char SDHI      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define U1SMR2      (*(volatile union u1smr2_t     *)(0x0256))

/*--------------------------------------------------------------------------------*/
/* UART1 Special Mode Register                                                    */

union u1smr_t {
  struct {
    unsigned char IICM      :1;
    unsigned char ABC       :1;
    unsigned char BBS       :1;
    unsigned char bit3      :1;
    unsigned char ABSCS     :1;
    unsigned char ACSE      :1;
    unsigned char SSS       :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define U1SMR       (*(volatile union u1smr_t      *)(0x0257))

/*--------------------------------------------------------------------------------*/
/* UART1 Transmit/Receive Mode Register                                           */

union u1mr_t {
  struct {
    unsigned char SMD0      :1;
    unsigned char SMD1      :1;
    unsigned char SMD2      :1;
    unsigned char CKDIR     :1;
    unsigned char STPS      :1;
    unsigned char PRY       :1;
    unsigned char PRYE      :1;
    unsigned char IOPOL     :1;
  } BIT;
  unsigned char BYTE;
};

#define U1MR        (*(volatile union u1mr_t       *)(0x0258))

/*--------------------------------------------------------------------------------*/
/* UART1 Bit Rate Register                                                        */

#define U1BRG       (*(volatile unsigned char  *)(0x0259))

/*--------------------------------------------------------------------------------*/
/* UART1 Transmit Buffer Register                                                 */
union st_u1tb {				 /* UART1 Transmit buffer register 16 bit ; Use "MOV" instruction when writing to this register. */
   struct{
	unsigned char U1TBL;     /* UART1 Transmit buffer register low  8 bit    */
	unsigned char U1TBH;     /* UART1 Transmit buffer register high 8 bit    */
   } BYTE;					 /* Byte access					   				 */
   unsigned short   WORD;	 /* Word Access					   				 */
};
#define U1TB        (*(volatile union st_u1tb *)(0x025A))

/*--------------------------------------------------------------------------------*/
/* UART1 Transmit/Receive Control Register 0                                      */

union u1c0_t {
  struct {
    unsigned char CLK0      :1;
    unsigned char CLK1      :1;
    unsigned char CRS       :1;
    unsigned char TXEPT     :1;
    unsigned char CRD       :1;
    unsigned char NCH       :1;
    unsigned char CKPOL     :1;
    unsigned char UFORM     :1;
  } BIT;
  unsigned char BYTE;
};

#define U1C0        (*(volatile union u1c0_t       *)(0x025C))

/*--------------------------------------------------------------------------------*/
/* UART1 Transmit/Receive Control Register 1                                      */

union u1c1_t {
  struct {
    unsigned char TE        :1;
    unsigned char TI        :1;
    unsigned char RE        :1;
    unsigned char RI        :1;
    unsigned char bit4      :1;
    unsigned char bit5      :1;
    unsigned char U1LCH     :1;
    unsigned char U1ERE     :1;
  } BIT;
  unsigned char BYTE;
};

#define U1C1        (*(volatile union u1c1_t       *)(0x025D))

/*--------------------------------------------------------------------------------*/
/* UART1 Receive Buffer Register                                                  */

union u1rb_t {
  struct {
    unsigned char bit0      :1;
    unsigned char bit1      :1;
    unsigned char bit2      :1;
    unsigned char bit3      :1;
    unsigned char bit4      :1;
    unsigned char bit5      :1;
    unsigned char bit6      :1;
    unsigned char bit7      :1;
    unsigned char bit8      :1;
    unsigned char bit9      :1;
    unsigned char bit10     :1;
    unsigned char ABT       :1;
    unsigned char OER       :1;
    unsigned char FER       :1;
    unsigned char PER       :1;
    unsigned char SUM       :1;
  } BIT;
  struct {
    unsigned char BYTE0;
    unsigned char BYTE1;
  } BYTES;
  struct {
    unsigned char U1RBL;
    unsigned char U1RBH;
  } BYTE;
  unsigned short WORD;
};

#define U1RB        (*(volatile union u1rb_t       *)(0x025E))

/*--------------------------------------------------------------------------------*/
/* UART2 Special Mode Register 4                                                  */

union u2smr4_t {
  struct {
    unsigned char STAREQ    :1;
    unsigned char RSTAREQ   :1;
    unsigned char STPREQ    :1;
    unsigned char STSPSEL   :1;
    unsigned char ACKD      :1;
    unsigned char ACKC      :1;
    unsigned char SCLHI     :1;
    unsigned char SWC9      :1;
  } BIT;
  unsigned char BYTE;
};

#define U2SMR4      (*(volatile union u2smr4_t     *)(0x0264))

/*--------------------------------------------------------------------------------*/
/* UART2 Special Mode Register 3                                                  */

union u2smr3_t {
  struct {
    unsigned char bit0      :1;
    unsigned char CKPH      :1;
    unsigned char bit2      :1;
    unsigned char NODC      :1;
    unsigned char bit4      :1;
    unsigned char DL0       :1;
    unsigned char DL1       :1;
    unsigned char DL2       :1;
  } BIT;
  unsigned char BYTE;
};

#define U2SMR3      (*(volatile union u2smr3_t     *)(0x0265))

/*--------------------------------------------------------------------------------*/
/* UART2 Special Mode Register 2                                                  */

union u2smr2_t {
  struct {
    unsigned char IICM2     :1;
    unsigned char CSC       :1;
    unsigned char SWC       :1;
    unsigned char ALS       :1;
    unsigned char STAC      :1;
    unsigned char SWC2      :1;
    unsigned char SDHI      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define U2SMR2      (*(volatile union u2smr2_t     *)(0x0266))

/*--------------------------------------------------------------------------------*/
/* UART2 Special Mode Register                                                    */

union u2smr_t {
  struct {
    unsigned char IICM      :1;
    unsigned char ABC       :1;
    unsigned char BBS       :1;
    unsigned char bit3      :1;
    unsigned char ABSCS     :1;
    unsigned char ACSE      :1;
    unsigned char SSS       :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define U2SMR       (*(volatile union u2smr_t      *)(0x0267))

/*--------------------------------------------------------------------------------*/
/* UART2 Transmit/Receive Mode Register                                           */

union u2mr_t {
  struct {
    unsigned char SMD0      :1;
    unsigned char SMD1      :1;
    unsigned char SMD2      :1;
    unsigned char CKDIR     :1;
    unsigned char STPS      :1;
    unsigned char PRY       :1;
    unsigned char PRYE      :1;
    unsigned char IOPOL     :1;
  } BIT;
  unsigned char BYTE;
};

#define U2MR        (*(volatile union u2mr_t       *)(0x0268))

/*--------------------------------------------------------------------------------*/
/* UART2 Bit Rate Register                                                        */

#define U2BRG       (*(volatile unsigned char  *)(0x0269))

/*--------------------------------------------------------------------------------*/
/* UART2 Transmit Buffer Register                                                 */
union st_u2tb {				 /* UART2 Transmit buffer register 16 bit ; Use "MOV" instruction when writing to this register. */
   struct{
	unsigned char U2TBL;     /* UART2 Transmit buffer register low  8 bit 	 */
	unsigned char U2TBH;     /* UART2 Transmit buffer register high 8 bit  	 */
   } BYTE;				 	 /* Byte access					   				 */
   unsigned short   WORD;	 /* Word Access					   				 */
};

#define U2TB        (*(volatile union st_u2tb *)(0x026A))

/*--------------------------------------------------------------------------------*/
/* UART2 Transmit/Receive Control Register 0                                      */

union u2c0_t {
  struct {
    unsigned char CLK0      :1;
    unsigned char CLK1      :1;
    unsigned char CRS       :1;
    unsigned char TXEPT     :1;
    unsigned char CRD       :1;
    unsigned char NCH       :1;
    unsigned char CKPOL     :1;
    unsigned char UFORM     :1;
  } BIT;
  unsigned char BYTE;
};

#define U2C0        (*(volatile union u2c0_t       *)(0x026C))

/*--------------------------------------------------------------------------------*/
/* UART2 Transmit/Receive Control Register 1                                      */

union u2c1_t {
  struct {
    unsigned char TE_U2C1   :1;
    unsigned char TI_U2C1   :1;
    unsigned char RE_U2C1   :1;
    unsigned char RI_U2C1   :1;
    unsigned char U2IRS     :1;
    unsigned char U2RRM     :1;
    unsigned char U2LCH     :1;
    unsigned char U2ERE     :1;
  } BIT;
  unsigned char BYTE;
};

#define U2C1        (*(volatile union u2c1_t       *)(0x026D))

/*--------------------------------------------------------------------------------*/
/* UART2 Receive Buffer Register                                                  */

union u2rb_t {
  struct {
    unsigned char bit0      :1;
    unsigned char bit1      :1;
    unsigned char bit2      :1;
    unsigned char bit3      :1;
    unsigned char bit4      :1;
    unsigned char bit5      :1;
    unsigned char bit6      :1;
    unsigned char bit7      :1;
    unsigned char bit8      :1;
    unsigned char bit9      :1;
    unsigned char bit10     :1;
    unsigned char ABT       :1;
    unsigned char OER       :1;
    unsigned char FER       :1;
    unsigned char PER       :1;
    unsigned char SUM       :1;
  } BIT;
  struct {
    unsigned char BYTE0;
    unsigned char BYTE1;
  } BYTES;
  struct {
    unsigned char U2RBL;
    unsigned char U2RBH;
  } BYTE;
  unsigned short WORD;
};

#define U2RB        (*(volatile union u2rb_t       *)(0x026E))

/*--------------------------------------------------------------------------------*/
/* SI/O3 Transmit/Receive Register                                                */

#define S3TRR       (*(volatile union register8_t  *)(0x0270))

/*--------------------------------------------------------------------------------*/
/* SI/O3 Control Register                                                         */

union s3c_t {
  struct {
    unsigned char SM30      :1;
    unsigned char SM31      :1;
    unsigned char SM32      :1;
    unsigned char SM33      :1;
    unsigned char SM34      :1;
    unsigned char SM35      :1;
    unsigned char SM36      :1;
    unsigned char SM37      :1;
  } BIT;
  unsigned char BYTE;
};

#define S3C         (*(volatile union s3c_t        *)(0x0272))

/*--------------------------------------------------------------------------------*/
/* SI/O3 Bit Rate Register                                                        */

#define S3BRG       (*(volatile union register8_t  *)(0x0273))

/*--------------------------------------------------------------------------------*/
/* SI/O4 Transmit/Receive Register                                                */

#define S4TRR       (*(volatile union register8_t  *)(0x0274))

/*--------------------------------------------------------------------------------*/
/* SI/O4 Control Register                                                         */

union s4c_t {
  struct {
    unsigned char SM40      :1;
    unsigned char SM41      :1;
    unsigned char SM42      :1;
    unsigned char SM43      :1;
    unsigned char SM44      :1;
    unsigned char SM45      :1;
    unsigned char SM46      :1;
    unsigned char SM47      :1;
  } BIT;
  unsigned char BYTE;
};

#define S4C         (*(volatile union s4c_t        *)(0x0276))

/*--------------------------------------------------------------------------------*/
/* SI/O4 Bit Rate Register                                                        */

#define S4BRG       (*(volatile union register8_t  *)(0x0277))

/*--------------------------------------------------------------------------------*/
/* SI/O3,4 Control Register 2                                                     */

union s34c2_t {
  struct {
    unsigned char bit0      :1;
    unsigned char bit1      :1;
    unsigned char SM22      :1;
    unsigned char bit3      :1;
    unsigned char bit4      :1;
    unsigned char bit5      :1;
    unsigned char SM26      :1;
    unsigned char SM27      :1;
  } BIT;
  unsigned char BYTE;
};

#define S34C2       (*(volatile union s34c2_t      *)(0x0278))

/*--------------------------------------------------------------------------------*/
/* UART5 Special Mode Register 4                                                  */

union u5smr4_t {
  struct {
    unsigned char STAREQ    :1;
    unsigned char RSTAREQ   :1;
    unsigned char STPREQ    :1;
    unsigned char STSPSEL   :1;
    unsigned char ACKD      :1;
    unsigned char ACKC      :1;
    unsigned char SCLHI     :1;
    unsigned char SWC9      :1;
  } BIT;
  unsigned char BYTE;
};

#define U5SMR4      (*(volatile union u5smr4_t     *)(0x0284))

/*--------------------------------------------------------------------------------*/
/* UART5 Special Mode Register 3                                                  */

union u5smr3_t {
  struct {
    unsigned char bit0      :1;
    unsigned char CKPH      :1;
    unsigned char bit2      :1;
    unsigned char NODC      :1;
    unsigned char bit4      :1;
    unsigned char DL0       :1;
    unsigned char DL1       :1;
    unsigned char DL2       :1;
  } BIT;
  unsigned char BYTE;
};

#define U5SMR3      (*(volatile union u5smr3_t     *)(0x0285))

/*--------------------------------------------------------------------------------*/
/* UART5 Special Mode Register 2                                                  */

union u5smr2_t {
  struct {
    unsigned char IICM2     :1;
    unsigned char CSC       :1;
    unsigned char SWC       :1;
    unsigned char ALS       :1;
    unsigned char STAC      :1;
    unsigned char SWC2      :1;
    unsigned char SDHI      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define U5SMR2      (*(volatile union u5smr2_t     *)(0x0286))

/*--------------------------------------------------------------------------------*/
/* UART5 Special Mode Register                                                    */

union u5smr_t {
  struct {
    unsigned char IICM      :1;
    unsigned char ABC       :1;
    unsigned char BBS       :1;
    unsigned char bit3      :1;
    unsigned char ABSCS     :1;
    unsigned char ACSE      :1;
    unsigned char SSS       :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define U5SMR       (*(volatile union u5smr_t      *)(0x0287))

/*--------------------------------------------------------------------------------*/
/* UART5 Transmit/Receive Mode Register                                           */

union u5mr_t {
  struct {
    unsigned char SMD0      :1;
    unsigned char SMD1      :1;
    unsigned char SMD2      :1;
    unsigned char CKDIR     :1;
    unsigned char STPS      :1;
    unsigned char PRY       :1;
    unsigned char PRYE      :1;
    unsigned char IOPOL     :1;
  } BIT;
  unsigned char BYTE;
};

#define U5MR        (*(volatile union u5mr_t       *)(0x0288))

/*--------------------------------------------------------------------------------*/
/* UART5 Bit Rate Register                                                        */

#define U5BRG       (*(volatile union register8_t  *)(0x0289))

/*--------------------------------------------------------------------------------*/
/* UART5 Transmit Buffer Register                                                 */

#define U5TB        (*(volatile union register16_t *)(0x028A))

/*--------------------------------------------------------------------------------*/
/* UART5 Transmit/Receive Control Register 0                                      */

union u5c0_t {
  struct {
    unsigned char CLK0      :1;
    unsigned char CLK1      :1;
    unsigned char CRS       :1;
    unsigned char TXEPT     :1;
    unsigned char CRD       :1;
    unsigned char NCH       :1;
    unsigned char CKPOL     :1;
    unsigned char UFORM     :1;
  } BIT;
  unsigned char BYTE;
};

#define U5C0        (*(volatile union u5c0_t       *)(0x028C))

/*--------------------------------------------------------------------------------*/
/* UART5 Transmit/Receive Control Register 1                                      */

union u5c1_t {
  struct {
    unsigned char TE        :1;
    unsigned char TI        :1;
    unsigned char RE        :1;
    unsigned char RI        :1;
    unsigned char U5IRS     :1;
    unsigned char U5RRM     :1;
    unsigned char U5LCH     :1;
    unsigned char U5ERE     :1;
  } BIT;
  unsigned char BYTE;
};

#define U5C1        (*(volatile union u5c1_t       *)(0x028D))

/*--------------------------------------------------------------------------------*/
/* UART5 Receive Buffer Register                                                  */

union u5rb_t {
  struct {
    unsigned char bit0      :1;
    unsigned char bit1      :1;
    unsigned char bit2      :1;
    unsigned char bit3      :1;
    unsigned char bit4      :1;
    unsigned char bit5      :1;
    unsigned char bit6      :1;
    unsigned char bit7      :1;
    unsigned char bit8      :1;
    unsigned char bit9      :1;
    unsigned char bit10     :1;
    unsigned char ABT       :1;
    unsigned char OER       :1;
    unsigned char FER       :1;
    unsigned char PER       :1;
    unsigned char SUM       :1;
  } BIT;
  struct {
    unsigned char BYTE0;
    unsigned char BYTE1;
  } BYTES;
  unsigned short WORD;
};

#define U5RB        (*(volatile union u5rb_t       *)(0x028E))

/*--------------------------------------------------------------------------------*/
/* UART6 Special Mode Register 4                                                  */

union u6smr4_t {
  struct {
    unsigned char STAREQ    :1;
    unsigned char RSTAREQ   :1;
    unsigned char STPREQ    :1;
    unsigned char STSPSEL   :1;
    unsigned char ACKD      :1;
    unsigned char ACKC      :1;
    unsigned char SCLHI     :1;
    unsigned char SWC9      :1;
  } BIT;
  unsigned char BYTE;
};

#define U6SMR4      (*(volatile union u6smr4_t     *)(0x0294))

/*--------------------------------------------------------------------------------*/
/* UART6 Special Mode Register 3                                                  */

union u6smr3_t {
  struct {
    unsigned char bit0      :1;
    unsigned char CKPH      :1;
    unsigned char bit2      :1;
    unsigned char NODC      :1;
    unsigned char bit4      :1;
    unsigned char DL0       :1;
    unsigned char DL1       :1;
    unsigned char DL2       :1;
  } BIT;
  unsigned char BYTE;
};

#define U6SMR3      (*(volatile union u6smr3_t     *)(0x0295))

/*--------------------------------------------------------------------------------*/
/* UART6 Special Mode Register 2                                                  */

union u6smr2_t {
  struct {
    unsigned char IICM2     :1;
    unsigned char CSC       :1;
    unsigned char SWC       :1;
    unsigned char ALS       :1;
    unsigned char STAC      :1;
    unsigned char SWC2      :1;
    unsigned char SDHI      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define U6SMR2      (*(volatile union u6smr2_t     *)(0x0296))

/*--------------------------------------------------------------------------------*/
/* UART6 Special Mode Register                                                    */

union u6smr_t {
  struct {
    unsigned char IICM      :1;
    unsigned char ABC       :1;
    unsigned char BBS       :1;
    unsigned char bit3      :1;
    unsigned char ABSCS     :1;
    unsigned char ACSE      :1;
    unsigned char SSS       :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define U6SMR       (*(volatile union u6smr_t      *)(0x0297))

/*--------------------------------------------------------------------------------*/
/* UART6 Transmit/Receive Mode Register                                           */

union u6mr_t {
  struct {
    unsigned char SMD0      :1;
    unsigned char SMD1      :1;
    unsigned char SMD2      :1;
    unsigned char CKDIR     :1;
    unsigned char STPS      :1;
    unsigned char PRY       :1;
    unsigned char PRYE      :1;
    unsigned char IOPOL     :1;
  } BIT;
  unsigned char BYTE;
};

#define U6MR        (*(volatile union u6mr_t       *)(0x0298))

/*--------------------------------------------------------------------------------*/
/* UART6 Bit Rate Register                                                        */

#define U6BRG       (*(volatile union register8_t  *)(0x0299))

/*--------------------------------------------------------------------------------*/
/* UART6 Transmit Buffer Register                                                 */

#define U6TB        (*(volatile union register16_t *)(0x029A))

/*--------------------------------------------------------------------------------*/
/* UART6 Transmit/Receive Control Register 0                                      */

union u6c0_t {
  struct {
    unsigned char CLK0      :1;
    unsigned char CLK1      :1;
    unsigned char CRS       :1;
    unsigned char TXEPT     :1;
    unsigned char CRD       :1;
    unsigned char NCH       :1;
    unsigned char CKPOL     :1;
    unsigned char UFORM     :1;
  } BIT;
  unsigned char BYTE;
};

#define U6C0        (*(volatile union u6c0_t       *)(0x029C))

/*--------------------------------------------------------------------------------*/
/* UART6 Transmit/Receive Control Register 1                                      */

union u6c1_t {
  struct {
    unsigned char TE        :1;
    unsigned char TI        :1;
    unsigned char RE        :1;
    unsigned char RI        :1;
    unsigned char U6IRS     :1;
    unsigned char U6RRM     :1;
    unsigned char U6LCH     :1;
    unsigned char U6ERE     :1;
  } BIT;
  unsigned char BYTE;
};

#define U6C1        (*(volatile union u6c1_t       *)(0x029D))

/*--------------------------------------------------------------------------------*/
/* UART6 Receive Buffer Register                                                  */

union u6rb_t {
  struct {
    unsigned char bit0      :1;
    unsigned char bit1      :1;
    unsigned char bit2      :1;
    unsigned char bit3      :1;
    unsigned char bit4      :1;
    unsigned char bit5      :1;
    unsigned char bit6      :1;
    unsigned char bit7      :1;
    unsigned char bit8      :1;
    unsigned char bit9      :1;
    unsigned char bit10     :1;
    unsigned char ABT       :1;
    unsigned char OER       :1;
    unsigned char FER       :1;
    unsigned char PER       :1;
    unsigned char SUM       :1;
  } BIT;
  struct {
    unsigned char BYTE0;
    unsigned char BYTE1;
  } BYTES;
  unsigned short WORD;
};

#define U6RB        (*(volatile union u6rb_t       *)(0x029E))

/*--------------------------------------------------------------------------------*/
/* UART7 Special Mode Register 4                                                  */

union u7smr4_t {
  struct {
    unsigned char STAREQ    :1;
    unsigned char RSTAREQ   :1;
    unsigned char STPREQ    :1;
    unsigned char STSPSEL   :1;
    unsigned char ACKD      :1;
    unsigned char ACKC      :1;
    unsigned char SCLHI     :1;
    unsigned char SWC9      :1;
  } BIT;
  unsigned char BYTE;
};

#define U7SMR4      (*(volatile union u7smr4_t     *)(0x02A4))

/*--------------------------------------------------------------------------------*/
/* UART7 Special Mode Register 3                                                  */

union u7smr3_t {
  struct {
    unsigned char bit0      :1;
    unsigned char CKPH      :1;
    unsigned char bit2      :1;
    unsigned char NODC      :1;
    unsigned char bit4      :1;
    unsigned char DL0       :1;
    unsigned char DL1       :1;
    unsigned char DL2       :1;
  } BIT;
  unsigned char BYTE;
};

#define U7SMR3      (*(volatile union u7smr3_t     *)(0x02A5))

/*--------------------------------------------------------------------------------*/
/* UART7 Special Mode Register 2                                                  */

union u7smr2_t {
  struct {
    unsigned char IICM2     :1;
    unsigned char CSC       :1;
    unsigned char SWC       :1;
    unsigned char ALS       :1;
    unsigned char STAC      :1;
    unsigned char SWC2      :1;
    unsigned char SDHI      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define U7SMR2      (*(volatile union u7smr2_t     *)(0x02A6))

/*--------------------------------------------------------------------------------*/
/* UART7 Special Mode Register                                                    */

union u7smr_t {
  struct {
    unsigned char IICM      :1;
    unsigned char ABC       :1;
    unsigned char BBS       :1;
    unsigned char bit3      :1;
    unsigned char ABSCS     :1;
    unsigned char ACSE      :1;
    unsigned char SSS       :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define U7SMR       (*(volatile union u7smr_t      *)(0x02A7))

/*--------------------------------------------------------------------------------*/
/* UART7 Transmit/Receive Mode Register                                           */

union u7mr_t {
  struct {
    unsigned char SMD0      :1;
    unsigned char SMD1      :1;
    unsigned char SMD2      :1;
    unsigned char CKDIR     :1;
    unsigned char STPS      :1;
    unsigned char PRY       :1;
    unsigned char PRYE      :1;
    unsigned char IOPOL     :1;
  } BIT;
  unsigned char BYTE;
};

#define U7MR        (*(volatile union u7mr_t       *)(0x02A8))

/*--------------------------------------------------------------------------------*/
/* UART7 Bit Rate Register                                                        */

#define U7BRG       (*(volatile union register8_t  *)(0x02A9))

/*--------------------------------------------------------------------------------*/
/* UART7 Transmit Buffer Register                                                 */

#define U7TB        (*(volatile union register16_t *)(0x02AA))

/*--------------------------------------------------------------------------------*/
/* UART7 Transmit/Receive Control Register 0                                      */

union u7c0_t {
  struct {
    unsigned char CLK0      :1;
    unsigned char CLK1      :1;
    unsigned char CRS       :1;
    unsigned char TXEPT     :1;
    unsigned char CRD       :1;
    unsigned char NCH       :1;
    unsigned char CKPOL     :1;
    unsigned char UFORM     :1;
  } BIT;
  unsigned char BYTE;
};

#define U7C0        (*(volatile union u7c0_t       *)(0x02AC))

/*--------------------------------------------------------------------------------*/
/* UART7 Transmit/Receive Control Register 1                                      */

union u7c1_t {
  struct {
    unsigned char TE        :1;
    unsigned char TI        :1;
    unsigned char RE        :1;
    unsigned char RI        :1;
    unsigned char U7IRS     :1;
    unsigned char U7RRM     :1;
    unsigned char U7LCH     :1;
    unsigned char U7ERE     :1;
  } BIT;
  unsigned char BYTE;
};

#define U7C1        (*(volatile union u7c1_t       *)(0x02AD))

/*--------------------------------------------------------------------------------*/
/* UART7 Receive Buffer Register                                                  */

union u7rb_t {
  struct {
    unsigned char bit0      :1;
    unsigned char bit1      :1;
    unsigned char bit2      :1;
    unsigned char bit3      :1;
    unsigned char bit4      :1;
    unsigned char bit5      :1;
    unsigned char bit6      :1;
    unsigned char bit7      :1;
    unsigned char bit8      :1;
    unsigned char bit9      :1;
    unsigned char bit10     :1;
    unsigned char ABT       :1;
    unsigned char OER       :1;
    unsigned char FER       :1;
    unsigned char PER       :1;
    unsigned char SUM       :1;
  } BIT;
  struct {
    unsigned char BYTE0;
    unsigned char BYTE1;
  } BYTES;
  unsigned short WORD;
};

#define U7RB        (*(volatile union u7rb_t       *)(0x02AE))

/*--------------------------------------------------------------------------------*/
/* I2C0 Data Shift Register                                                       */

#define S00         (*(volatile union register8_t  *)(0x02B0))

/*--------------------------------------------------------------------------------*/
/* I2C0 Address Register 0                                                        */

union s0d0_t {
  struct {
    unsigned char bit0      :1;
    unsigned char SAD0      :1;
    unsigned char SAD1      :1;
    unsigned char SAD2      :1;
    unsigned char SAD3      :1;
    unsigned char SAD4      :1;
    unsigned char SAD5      :1;
    unsigned char SAD6      :1;
  } BIT;
  unsigned char BYTE;
};

#define S0D0        (*(volatile union s0d0_t       *)(0x02B2))

/*--------------------------------------------------------------------------------*/
/* I2C0 Control Register 0                                                        */

union s1d0_t {
  struct {
    unsigned char BC0       :1;
    unsigned char BC1       :1;
    unsigned char BC2       :1;
    unsigned char ES0       :1;
    unsigned char ALS       :1;
    unsigned char bit5      :1;
    unsigned char IHR       :1;
    unsigned char TISS      :1;
  } BIT;
  unsigned char BYTE;
};

#define S1D0        (*(volatile union s1d0_t       *)(0x02B3))

/*--------------------------------------------------------------------------------*/
/* I2C0 Clock Control Register                                                    */

union s20_t {
  struct {
    unsigned char CCR0      :1;
    unsigned char CCR1      :1;
    unsigned char CCR2      :1;
    unsigned char CCR3      :1;
    unsigned char CCR4      :1;
    unsigned char FASTMODE  :1;
    unsigned char ACKBIT    :1;
    unsigned char ACKCLK    :1;
  } BIT;
  unsigned char BYTE;
};

#define S20         (*(volatile union s20_t        *)(0x02B4))

/*--------------------------------------------------------------------------------*/
/* I2C0 Start/Stop Condition Control Register                                     */

union s2d0_t {
  struct {
    unsigned char SSC0      :1;
    unsigned char SSC1      :1;
    unsigned char SSC2      :1;
    unsigned char SSC3      :1;
    unsigned char SSC4      :1;
    unsigned char SIP       :1;
    unsigned char SIS       :1;
    unsigned char STSPSEL   :1;
  } BIT;
  unsigned char BYTE;
};

#define S2D0        (*(volatile union s2d0_t       *)(0x02B5))

/*--------------------------------------------------------------------------------*/
/* I2C0 Control Register 1                                                        */

union s3d0_t {
  struct {
    unsigned char SIM       :1;
    unsigned char WIT       :1;
    unsigned char PED       :1;
    unsigned char PEC       :1;
    unsigned char SDAM      :1;
    unsigned char SCLM      :1;
    unsigned char ICK0      :1;
    unsigned char ICK1      :1;
  } BIT;
  unsigned char BYTE;
};

#define S3D0        (*(volatile union s3d0_t       *)(0x02B6))

/*--------------------------------------------------------------------------------*/
/* I2C0 Control Register 2                                                        */

union s4d0_t {
  struct {
    unsigned char TOE       :1;
    unsigned char TOF       :1;
    unsigned char TOSEL     :1;
    unsigned char ICK2      :1;
    unsigned char ICK3      :1;
    unsigned char ICK4      :1;
    unsigned char MSLAD     :1;
    unsigned char SCPIN     :1;
  } BIT;
  unsigned char BYTE;
};

#define S4D0        (*(volatile union s4d0_t       *)(0x02B7))

/*--------------------------------------------------------------------------------*/
/* I2C0 Status Register 0                                                         */

union s10_t {
  struct {
    unsigned char LRB       :1;
    unsigned char ADR0      :1;
    unsigned char AAS       :1;
    unsigned char AL        :1;
    unsigned char PIN       :1;
    unsigned char BB        :1;
    unsigned char TRX       :1;
    unsigned char MST       :1;
  } BIT;
  unsigned char BYTE;
};

#define S10         (*(volatile union s10_t        *)(0x02B8))

/*--------------------------------------------------------------------------------*/
/* I2C0 Status Register 1                                                         */

union s11_t {
  struct {
    unsigned char AAS0      :1;
    unsigned char AAS1      :1;
    unsigned char AAS2      :1;
    unsigned char bit3      :1;
    unsigned char bit4      :1;
    unsigned char bit5      :1;
    unsigned char bit6      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define S11         (*(volatile union s11_t        *)(0x02B9))

/*--------------------------------------------------------------------------------*/
/* I2C0 Address Register 1                                                        */

union s0d1_t {
  struct {
    unsigned char bit0      :1;
    unsigned char SAD0      :1;
    unsigned char SAD1      :1;
    unsigned char SAD2      :1;
    unsigned char SAD3      :1;
    unsigned char SAD4      :1;
    unsigned char SAD5      :1;
    unsigned char SAD6      :1;
  } BIT;
  unsigned char BYTE;
};

#define S0D1        (*(volatile union s0d1_t       *)(0x02BA))

/*--------------------------------------------------------------------------------*/
/* I2C0 Address Register 2                                                        */

union s0d2_t {
  struct {
    unsigned char bit0      :1;
    unsigned char SAD0      :1;
    unsigned char SAD1      :1;
    unsigned char SAD2      :1;
    unsigned char SAD3      :1;
    unsigned char SAD4      :1;
    unsigned char SAD5      :1;
    unsigned char SAD6      :1;
  } BIT;
  unsigned char BYTE;
};

#define S0D2        (*(volatile union s0d2_t       *)(0x02BB))

/*--------------------------------------------------------------------------------*/
/* Timer B3/B4/B5 Count Start Flag                                                */

union tbsr_t {
  struct {
    unsigned char bit0      :1;
    unsigned char bit1      :1;
    unsigned char bit2      :1;
    unsigned char bit3      :1;
    unsigned char bit4      :1;
    unsigned char TB3S      :1;
    unsigned char TB4S      :1;
    unsigned char TB5S      :1;
  } BIT;
  unsigned char BYTE;
};

#define TBSR        (*(volatile union tbsr_t       *)(0x0300))

/*--------------------------------------------------------------------------------*/
/* Timer A1-1 Register                                                            */

#define TA11        (*(volatile union register16_t *)(0x0302))

/*--------------------------------------------------------------------------------*/
/* Timer A2-1 Register                                                            */

#define TA21        (*(volatile union register16_t *)(0x0304))

/*--------------------------------------------------------------------------------*/
/* Timer A4-1 Register                                                            */

#define TA41        (*(volatile union register16_t *)(0x0306))

/*--------------------------------------------------------------------------------*/
/* Three-Phase PWM Control Register 0                                             */

union invc0_t {
  struct {
    unsigned char INV00     :1;
    unsigned char INV01     :1;
    unsigned char INV02     :1;
    unsigned char INV03     :1;
    unsigned char INV04     :1;
    unsigned char INV05     :1;
    unsigned char INV06     :1;
    unsigned char INV07     :1;
  } BIT;
  unsigned char BYTE;
};

#define INVC0       (*(volatile union invc0_t      *)(0x0308))

/*--------------------------------------------------------------------------------*/
/* Three-Phase PWM Control Register 1                                             */

union invc1_t {
  struct {
    unsigned char INV10     :1;
    unsigned char INV11     :1;
    unsigned char INV12     :1;
    unsigned char INV13     :1;
    unsigned char INV14     :1;
    unsigned char INV15     :1;
    unsigned char INV16     :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define INVC1       (*(volatile union invc1_t      *)(0x0309))

/*--------------------------------------------------------------------------------*/
/* Three-Phase Output Buffer Register 0                                           */

union idb0_t {
  struct {
    unsigned char DU0       :1;
    unsigned char DUB0      :1;
    unsigned char DV0       :1;
    unsigned char DVB0      :1;
    unsigned char DW0       :1;
    unsigned char DWB0      :1;
    unsigned char bit6      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define IDB0        (*(volatile union idb0_t       *)(0x030A))

/*--------------------------------------------------------------------------------*/
/* Three-Phase Output Buffer Register 1                                           */

union idb1_t {
  struct {
    unsigned char DU1       :1;
    unsigned char DUB1      :1;
    unsigned char DV1       :1;
    unsigned char DVB1      :1;
    unsigned char DW1       :1;
    unsigned char DWB1      :1;
    unsigned char bit6      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define IDB1        (*(volatile union idb1_t       *)(0x030B))

/*--------------------------------------------------------------------------------*/
/* Dead Time Timer                                                                */

#define DTT         (*(volatile union register8_t  *)(0x030C))

/*--------------------------------------------------------------------------------*/
/* Timer B2 Interrupt Generation Frequency Set Counter                            */

#define ICTB2       (*(volatile union register8_t  *)(0x030D))

/*--------------------------------------------------------------------------------*/
/* Position-Data-Retain Function Control Register                                 */

union pdrf_t {
  struct {
    unsigned char PDRW      :1;
    unsigned char PDRV      :1;
    unsigned char PDRU      :1;
    unsigned char PDRT      :1;
    unsigned char bit4      :1;
    unsigned char bit5      :1;
    unsigned char bit6      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define PDRF        (*(volatile union pdrf_t       *)(0x030E))

/*--------------------------------------------------------------------------------*/
/* Timer B3 Register                                                              */

#define TB3         (*(volatile union register16_t *)(0x0310))

/*--------------------------------------------------------------------------------*/
/* Timer B4 Register                                                              */

#define TB4         (*(volatile union register16_t *)(0x0312))

/*--------------------------------------------------------------------------------*/
/* Timer B5 Register                                                              */

#define TB5         (*(volatile union register16_t *)(0x0314))

/*--------------------------------------------------------------------------------*/
/* Port Function Control Register                                                 */

union pfcr_t {
  struct {
    unsigned char PFC0      :1;
    unsigned char PFC1      :1;
    unsigned char PFC2      :1;
    unsigned char PFC3      :1;
    unsigned char PFC4      :1;
    unsigned char PFC5      :1;
    unsigned char bit6      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define PFCR        (*(volatile union pfcr_t       *)(0x0318))

/*--------------------------------------------------------------------------------*/
/* Timer B3 Mode Register                                                         */

union tb3mr_t {
  struct {
    unsigned char TMOD0     :1;
    unsigned char TMOD1     :1;
    unsigned char MR0       :1;
    unsigned char MR1       :1;
    unsigned char bit4      :1;
    unsigned char MR3       :1;
    unsigned char TCK0      :1;
    unsigned char TCK1      :1;
  } BIT;
  unsigned char BYTE;
};

#define TB3MR       (*(volatile union tb3mr_t      *)(0x031B))

/*--------------------------------------------------------------------------------*/
/* Timer B4 Mode Register                                                         */

union tb4mr_t {
  struct {
    unsigned char TMOD0     :1;
    unsigned char TMOD1     :1;
    unsigned char MR0       :1;
    unsigned char MR1       :1;
    unsigned char bit4      :1;
    unsigned char MR3       :1;
    unsigned char TCK0      :1;
    unsigned char TCK1      :1;
  } BIT;
  unsigned char BYTE;
};

#define TB4MR       (*(volatile union tb4mr_t      *)(0x031C))

/*--------------------------------------------------------------------------------*/
/* Timer B5 Mode Register                                                         */

union tb5mr_t {
  struct {
    unsigned char TMOD0     :1;
    unsigned char TMOD1     :1;
    unsigned char MR0       :1;
    unsigned char MR1       :1;
    unsigned char bit4      :1;
    unsigned char MR3       :1;
    unsigned char TCK0      :1;
    unsigned char TCK1      :1;
  } BIT;
  unsigned char BYTE;
};

#define TB5MR       (*(volatile union tb5mr_t      *)(0x031D))

/*--------------------------------------------------------------------------------*/
/* Count Start Flag                                                               */

union tabsr_t {
  struct {
    unsigned char TA0S      :1;
    unsigned char TA1S      :1;
    unsigned char TA2S      :1;
    unsigned char TA3S      :1;
    unsigned char TA4S      :1;
    unsigned char TB0S      :1;
    unsigned char TB1S      :1;
    unsigned char TB2S      :1;
  } BIT;
  unsigned char BYTE;
};

#define TABSR       (*(volatile union tabsr_t      *)(0x0320))

/*--------------------------------------------------------------------------------*/
/* One-Shot Start Flag                                                            */

union onsf_t {
  struct {
    unsigned char TA0OS     :1;
    unsigned char TA1OS     :1;
    unsigned char TA2OS     :1;
    unsigned char TA3OS     :1;
    unsigned char TA4OS     :1;
    unsigned char TAZIE     :1;
    unsigned char TA0TGL    :1;
    unsigned char TA0TGH    :1;
  } BIT;
  unsigned char BYTE;
};

#define ONSF        (*(volatile union onsf_t       *)(0x0322))

/*--------------------------------------------------------------------------------*/
/* Trigger Select Register                                                        */

union trgsr_t {
  struct {
    unsigned char TA1TGL    :1;
    unsigned char TA1TGH    :1;
    unsigned char TA2TGL    :1;
    unsigned char TA2TGH    :1;
    unsigned char TA3TGL    :1;
    unsigned char TA3TGH    :1;
    unsigned char TA4TGL    :1;
    unsigned char TA4TGH    :1;
  } BIT;
  unsigned char BYTE;
};

#define TRGSR       (*(volatile union trgsr_t      *)(0x0323))

/*--------------------------------------------------------------------------------*/
/* Up/Down Flag                                                                   */

union udf_t {
  struct {
    unsigned char TA0UD     :1;
    unsigned char TA1UD     :1;
    unsigned char TA2UD     :1;
    unsigned char TA3UD     :1;
    unsigned char TA4UD     :1;
    unsigned char TA2P      :1;
    unsigned char TA3P      :1;
    unsigned char TA4P      :1;
  } BIT;
  unsigned char BYTE;
};

#define UDF         (*(volatile unsigned char      *)(0x0324))

/*--------------------------------------------------------------------------------*/
/* Timer A0 Register                                                              */

#define TA0         (*(volatile union register16_t *)(0x0326))

/*--------------------------------------------------------------------------------*/
/* Timer A1 Register                                                              */

#define TA1         (*(volatile union register16_t *)(0x0328))

/*--------------------------------------------------------------------------------*/
/* Timer A2 Register                                                              */

#define TA2         (*(volatile union register16_t *)(0x032A))

/*--------------------------------------------------------------------------------*/
/* Timer A3 Register                                                              */

#define TA3         (*(volatile union register16_t *)(0x032C))

/*--------------------------------------------------------------------------------*/
/* Timer A4 Register                                                              */

#define TA4         (*(volatile union register16_t *)(0x032E))

/*--------------------------------------------------------------------------------*/
/* Timer B0 Register                                                              */

#define TB0         (*(volatile union register16_t *)(0x0330))

/*--------------------------------------------------------------------------------*/
/* Timer B1 Register                                                              */

#define TB1         (*(volatile union register16_t *)(0x0332))

/*--------------------------------------------------------------------------------*/
/* Timer B2 Register                                                              */

#define TB2         (*(volatile union register16_t *)(0x0334))

/*--------------------------------------------------------------------------------*/
/* Timer A0 Mode Register                                                         */

union ta0mr_t {
  struct {
    unsigned char TMOD0     :1;
    unsigned char TMOD1     :1;
    unsigned char MR0       :1;
    unsigned char MR1       :1;
    unsigned char MR2       :1;
    unsigned char MR3       :1;
    unsigned char TCK0      :1;
    unsigned char TCK1      :1;
  } BIT;
  unsigned char BYTE;
};

#define TA0MR       (*(volatile union ta0mr_t      *)(0x0336))

/*--------------------------------------------------------------------------------*/
/* Timer A1 Mode Register                                                         */

union ta1mr_t {
  struct {
    unsigned char TMOD0     :1;
    unsigned char TMOD1     :1;
    unsigned char MR0       :1;
    unsigned char MR1       :1;
    unsigned char MR2       :1;
    unsigned char MR3       :1;
    unsigned char TCK0      :1;
    unsigned char TCK1      :1;
  } BIT;
  unsigned char BYTE;
};

#define TA1MR       (*(volatile union ta1mr_t      *)(0x0337))

/*--------------------------------------------------------------------------------*/
/* Timer A2 Mode Register                                                         */

union ta2mr_t {
  struct {
    unsigned char TMOD0     :1;
    unsigned char TMOD1     :1;
    unsigned char MR0       :1;
    unsigned char MR1       :1;
    unsigned char MR2       :1;
    unsigned char MR3       :1;
    unsigned char TCK0      :1;
    unsigned char TCK1      :1;
  } BIT;
  unsigned char BYTE;
};

#define TA2MR       (*(volatile union ta2mr_t      *)(0x0338))

/*--------------------------------------------------------------------------------*/
/* Timer A3 Mode Register                                                         */

union ta3mr_t {
  struct {
    unsigned char TMOD0     :1;
    unsigned char TMOD1     :1;
    unsigned char MR0       :1;
    unsigned char MR1       :1;
    unsigned char MR2       :1;
    unsigned char MR3       :1;
    unsigned char TCK0      :1;
    unsigned char TCK1      :1;
  } BIT;
  unsigned char BYTE;
};

#define TA3MR       (*(volatile union ta3mr_t      *)(0x0339))

/*--------------------------------------------------------------------------------*/
/* Timer A4 Mode Register                                                         */

union ta4mr_t {
  struct {
    unsigned char TMOD0     :1;
    unsigned char TMOD1     :1;
    unsigned char MR0       :1;
    unsigned char MR1       :1;
    unsigned char MR2       :1;
    unsigned char MR3       :1;
    unsigned char TCK0      :1;
    unsigned char TCK1      :1;
  } BIT;
  unsigned char BYTE;
};

#define TA4MR       (*(volatile union ta4mr_t      *)(0x033A))

/*--------------------------------------------------------------------------------*/
/* Timer B0 Mode Register                                                         */

union tb0mr_t {
  struct {
    unsigned char TMOD0     :1;
    unsigned char TMOD1     :1;
    unsigned char MR0       :1;
    unsigned char MR1       :1;
    unsigned char bit4      :1;
    unsigned char MR3       :1;
    unsigned char TCK0      :1;
    unsigned char TCK1      :1;
  } BIT;
  unsigned char BYTE;
};

#define TB0MR       (*(volatile union tb0mr_t      *)(0x033B))

/*--------------------------------------------------------------------------------*/
/* Timer B1 Mode Register                                                         */

union tb1mr_t {
  struct {
    unsigned char TMOD0     :1;
    unsigned char TMOD1     :1;
    unsigned char MR0       :1;
    unsigned char MR1       :1;
    unsigned char bit4      :1;
    unsigned char MR3       :1;
    unsigned char TCK0      :1;
    unsigned char TCK1      :1;
  } BIT;
  unsigned char BYTE;
};

#define TB1MR       (*(volatile union tb1mr_t      *)(0x033C))

/*--------------------------------------------------------------------------------*/
/* Timer B2 Mode Register                                                         */

union tb2mr_t {
  struct {
    unsigned char TMOD0     :1;
    unsigned char TMOD1     :1;
    unsigned char MR0       :1;
    unsigned char MR1       :1;
    unsigned char bit4      :1;
    unsigned char MR3       :1;
    unsigned char TCK0      :1;
    unsigned char TCK1      :1;
  } BIT;
  unsigned char BYTE;
};

#define TB2MR       (*(volatile union tb2mr_t      *)(0x033D))

/*--------------------------------------------------------------------------------*/
/* Timer B2 Special Mode Register                                                 */

union tb2sc_t {
  struct {
    unsigned char PWCON     :1;
    unsigned char IVPCR1    :1;
    unsigned char bit2      :1;
    unsigned char bit3      :1;
    unsigned char bit4      :1;
    unsigned char bit5      :1;
    unsigned char bit6      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define TB2SC       (*(volatile union tb2sc_t      *)(0x033E))

/*--------------------------------------------------------------------------------*/
/* Real-Time Clock Second Data Register                                           */

union rtcsec_t {
  struct {
    unsigned char SC00      :1;
    unsigned char SC01      :1;
    unsigned char SC02      :1;
    unsigned char SC03      :1;
    unsigned char SC10      :1;
    unsigned char SC11      :1;
    unsigned char SC12      :1;
    unsigned char BSY       :1;
  } BIT;
  unsigned char BYTE;
};

#define RTCSEC      (*(volatile union rtcsec_t     *)(0x0340))

/*--------------------------------------------------------------------------------*/
/* Real-Time Clock Minute Data Register                                           */

union rtcmin_t {
  struct {
    unsigned char MN00      :1;
    unsigned char MN01      :1;
    unsigned char MN02      :1;
    unsigned char MN03      :1;
    unsigned char MN10      :1;
    unsigned char MN11      :1;
    unsigned char MN12      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define RTCMIN      (*(volatile union rtcmin_t     *)(0x0341))

/*--------------------------------------------------------------------------------*/
/* Real-Time Clock Hour Data Register                                             */

union rtchr_t {
  struct {
    unsigned char HR00      :1;
    unsigned char HR01      :1;
    unsigned char HR02      :1;
    unsigned char HR03      :1;
    unsigned char HR10      :1;
    unsigned char HR11      :1;
    unsigned char bit6      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define RTCHR       (*(volatile union rtchr_t      *)(0x0342))

/*--------------------------------------------------------------------------------*/
/* Real-Time Clock Day Data Register                                              */

union rtcwk_t {
  struct {
    unsigned char WK0       :1;
    unsigned char WK1       :1;
    unsigned char WK2       :1;
    unsigned char bit3      :1;
    unsigned char bit4      :1;
    unsigned char bit5      :1;
    unsigned char bit6      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define RTCWK       (*(volatile union rtcwk_t      *)(0x0343))

/*--------------------------------------------------------------------------------*/
/* Real-Time Clock Control Register 1                                             */

union rtccr1_t {
  struct {
    unsigned char bit0      :1;
    unsigned char TCSTF     :1;
    unsigned char TOENA     :1;
    unsigned char bit3      :1;
    unsigned char RTCRST    :1;
    unsigned char RTCPM     :1;
    unsigned char H12H24    :1;
    unsigned char TSTART    :1;
  } BIT;
  unsigned char BYTE;
};

#define RTCCR1      (*(volatile union rtccr1_t     *)(0x0344))

/*--------------------------------------------------------------------------------*/
/* Real-Time Clock Control Register 2                                             */

union rtccr2_t {
  struct {
    unsigned char SEIE      :1;
    unsigned char MNIE      :1;
    unsigned char HRIE      :1;
    unsigned char DYIE      :1;
    unsigned char WKIE      :1;
    unsigned char RTCCMP0   :1;
    unsigned char RTCCMP2   :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define RTCCR2      (*(volatile union rtccr2_t     *)(0x0345))

/*--------------------------------------------------------------------------------*/
/* Real-Time Clock Count Source Select Register                                   */

union rtccsr_t {
  struct {
    unsigned char RCS0      :1;
    unsigned char RCS1      :1;
    unsigned char RCS2      :1;
    unsigned char RCS3      :1;
    unsigned char RCS4      :1;
    unsigned char bit5      :1;
    unsigned char bit6      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define RTCCSR      (*(volatile union rtccsr_t     *)(0x0346))

/*--------------------------------------------------------------------------------*/
/* Real-Time Clock Second Compare Data Register                                   */

union rtccsec_t {
  struct {
    unsigned char SCMP00    :1;
    unsigned char SCMP01    :1;
    unsigned char SCMP02    :1;
    unsigned char SCMP03    :1;
    unsigned char SCMP10    :1;
    unsigned char SCMP11    :1;
    unsigned char SCMP12    :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define RTCCSEC     (*(volatile union rtccsec_t    *)(0x0348))

/*--------------------------------------------------------------------------------*/
/* Real-Time Clock Minute Compare Data Register                                   */

union rtccmin_t {
  struct {
    unsigned char MCMP00    :1;
    unsigned char MCMP01    :1;
    unsigned char MCMP02    :1;
    unsigned char MCMP03    :1;
    unsigned char MCMP10    :1;
    unsigned char MCMP11    :1;
    unsigned char MCMP12    :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define RTCCMIN     (*(volatile union rtccmin_t    *)(0x0349))

/*--------------------------------------------------------------------------------*/
/* Real-Time Clock Hour Compare Data Register                                     */

union rtcchr_t {
  struct {
    unsigned char HCMP00    :1;
    unsigned char HCMP01    :1;
    unsigned char HCMP02    :1;
    unsigned char HCMP03    :1;
    unsigned char HCMP10    :1;
    unsigned char HCMP11    :1;
    unsigned char PMCMP     :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define RTCCHR      (*(volatile union rtcchr_t     *)(0x034A))

/*--------------------------------------------------------------------------------*/
/* CEC Function Control Register 1                                                */

union cecc1_t {
  struct {
    unsigned char CECEN     :1;
    unsigned char CCLK0     :1;
    unsigned char CCLK1     :1;
    unsigned char bit3      :1;
    unsigned char bit4      :1;
    unsigned char bit5      :1;
    unsigned char bit6      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define CECC1       (*(volatile union cecc1_t      *)(0x0350))

/*--------------------------------------------------------------------------------*/
/* CEC Function Control Register 2                                                */

union cecc2_t {
  struct {
    unsigned char CRRNG     :1;
    unsigned char CTNACK    :1;
    unsigned char CTACKEN   :1;
    unsigned char CRACK     :1;
    unsigned char CTABTS    :1;
    unsigned char CFIL      :1;
    unsigned char CSTRRNG   :1;
    unsigned char CDATRNG   :1;
  } BIT;
  unsigned char BYTE;
};

#define CECC2       (*(volatile union cecc2_t      *)(0x0351))

/*--------------------------------------------------------------------------------*/
/* CEC Function Control Register 3                                                */

union cecc3_t {
  struct {
    unsigned char CTXDEN    :1;
    unsigned char CRXDEN    :1;
    unsigned char CREGCLR   :1;
    unsigned char CEOMI     :1;
    unsigned char bit4      :1;
    unsigned char bit5      :1;
    unsigned char bit6      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define CECC3       (*(volatile union cecc3_t      *)(0x0352))

/*--------------------------------------------------------------------------------*/
/* CEC Function Control Register 4                                                */

union cecc4_t {
  struct {
    unsigned char CRISE0    :1;
    unsigned char CRISE1    :1;
    unsigned char CRISE2    :1;
    unsigned char CABTEN    :1;
    unsigned char CFALL0    :1;
    unsigned char CFALL1    :1;
    unsigned char CREGFLG   :1;
    unsigned char CABTWEN   :1;
  } BIT;
  unsigned char BYTE;
};

#define CECC4       (*(volatile union cecc4_t      *)(0x0353))

/*--------------------------------------------------------------------------------*/
/* CEC Flag Register                                                              */

union cecflg_t {
  struct {
    unsigned char CRFLG     :1;
    unsigned char CTFLG     :1;
    unsigned char CRERRFLG  :1;
    unsigned char CTABTFLG  :1;
    unsigned char CTNACKFLG :1;
    unsigned char CRD8FLG   :1;
    unsigned char CTD8FLG   :1;
    unsigned char CRSTFLG   :1;
  } BIT;
  unsigned char BYTE;
};

#define CECFLG      (*(volatile union cecflg_t     *)(0x0354))

/*--------------------------------------------------------------------------------*/
/* CEC Interrupt Source Select Register                                           */

union cisel_t {
  struct {
    unsigned char CRISEL0   :1;
    unsigned char CRISEL1   :1;
    unsigned char CRISEL2   :1;
    unsigned char CRISELM   :1;
    unsigned char CTISEL0   :1;
    unsigned char CTISEL1   :1;
    unsigned char CTISEL2   :1;
    unsigned char CRISELS   :1;
  } BIT;
  unsigned char BYTE;
};

#define CISEL       (*(volatile union cisel_t      *)(0x0355))

/*--------------------------------------------------------------------------------*/
/* CEC Transmit Buffer Register 1                                                 */

#define CCTB1       (*(volatile union register8_t  *)(0x0356))

/*--------------------------------------------------------------------------------*/
/* CEC Transmit Buffer Register 2                                                 */

union cctb2_t {
  struct {
    unsigned char CCTBE     :1;
    unsigned char CCTBA     :1;
    unsigned char bit2      :1;
    unsigned char bit3      :1;
    unsigned char bit4      :1;
    unsigned char bit5      :1;
    unsigned char bit6      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define CCTB2       (*(volatile union cctb2_t      *)(0x0357))

/*--------------------------------------------------------------------------------*/
/* CEC Receive Buffer Register 1                                                  */

#define CCRB1       (*(volatile union register8_t  *)(0x0358))

/*--------------------------------------------------------------------------------*/
/* CEC Receive Buffer Register 2                                                  */

union ccrb2_t {
  struct {
    unsigned char CCRBE     :1;
    unsigned char CCRBAO    :1;
    unsigned char CCRBAI    :1;
    unsigned char bit3      :1;
    unsigned char bit4      :1;
    unsigned char bit5      :1;
    unsigned char bit6      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define CCRB2       (*(volatile union ccrb2_t      *)(0x0359))

/*--------------------------------------------------------------------------------*/
/* CEC Receive Follower Address Set Register 1                                    */

union cradri1_t {
  struct {
    unsigned char CRADRI10  :1;
    unsigned char CRADRI11  :1;
    unsigned char CRADRI12  :1;
    unsigned char CRADRI13  :1;
    unsigned char CRADRI14  :1;
    unsigned char CRADRI15  :1;
    unsigned char CRADRI16  :1;
    unsigned char CRADRI17  :1;
  } BIT;
  unsigned char BYTE;
};

#define CRADRI1     (*(volatile union cradri1_t    *)(0x035A))

/*--------------------------------------------------------------------------------*/
/* CEC Receive Follower Address Set Register 2                                    */

union cradri2_t {
  struct {
    unsigned char CRADRI20  :1;
    unsigned char CRADRI21  :1;
    unsigned char CRADRI22  :1;
    unsigned char CRADRI23  :1;
    unsigned char CRADRI24  :1;
    unsigned char CRADRI25  :1;
    unsigned char CRADRI26  :1;
    unsigned char CRADRI27  :1;
  } BIT;
  unsigned char BYTE;
};

#define CRADRI2     (*(volatile union cradri2_t    *)(0x035B))

/*--------------------------------------------------------------------------------*/
/* Pull-Up Control Register 0                                                     */

union pur0_t {
  struct {
    unsigned char PU00      :1;
    unsigned char PU01      :1;
    unsigned char PU02      :1;
    unsigned char PU03      :1;
    unsigned char PU04      :1;
    unsigned char PU05      :1;
    unsigned char PU06      :1;
    unsigned char PU07      :1;
  } BIT;
  unsigned char BYTE;
};

#define PUR0        (*(volatile union pur0_t       *)(0x0360))

/*--------------------------------------------------------------------------------*/
/* Pull-Up Control Register 1                                                     */

union pur1_t {
  struct {
    unsigned char PU10      :1;
    unsigned char PU11      :1;
    unsigned char PU12      :1;
    unsigned char PU13      :1;
    unsigned char PU14      :1;
    unsigned char PU15      :1;
    unsigned char PU16      :1;
    unsigned char PU17      :1;
  } BIT;
  unsigned char BYTE;
};

#define PUR1        (*(volatile union pur1_t       *)(0x0361))

/*--------------------------------------------------------------------------------*/
/* Pull-Up Control Register 2                                                     */

union pur2_t {
  struct {
    unsigned char PU20      :1;
    unsigned char PU21      :1;
    unsigned char PU22      :1;
    unsigned char PU23      :1;
    unsigned char PU24      :1;
    unsigned char PU25      :1;
    unsigned char bit6      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define PUR2        (*(volatile union pur2_t       *)(0x0362))

/*--------------------------------------------------------------------------------*/
/* Pull-Up Control Register 3                                                     */

union pur3_t {
  struct {
    unsigned char PU30      :1;
    unsigned char PU31      :1;
    unsigned char PU32      :1;
    unsigned char PU33      :1;
    unsigned char PU34      :1;
    unsigned char PU35      :1;
    unsigned char PU36      :1;
    unsigned char PU37      :1;
  } BIT;
  unsigned char BYTE;
};

#define PUR3        (*(volatile union pur3_t       *)(0x0363))

/*--------------------------------------------------------------------------------*/
/* Port Control Register                                                          */

union pcr_t {
  struct {
    unsigned char PCR0      :1;
    unsigned char bit1      :1;
    unsigned char bit2      :1;
    unsigned char bit3      :1;
    unsigned char PCR4      :1;
    unsigned char PCR5      :1;
    unsigned char PCR6      :1;
    unsigned char PCR7      :1;
  } BIT;
  unsigned char BYTE;
};

#define PCR         (*(volatile union pcr_t        *)(0x0366))

/*--------------------------------------------------------------------------------*/
/* NMI/SD Digital Filter Register                                                 */

union nmidf_t {
  struct {
    unsigned char NMIDF0    :1;
    unsigned char NMIDF1    :1;
    unsigned char NMIDF2    :1;
    unsigned char bit3      :1;
    unsigned char bit4      :1;
    unsigned char bit5      :1;
    unsigned char bit6      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define NMIDF       (*(volatile union nmidf_t      *)(0x0369))

/*--------------------------------------------------------------------------------*/
/* PWM Control Register 0                                                         */

union pwmcon0_t {
  struct {
    unsigned char PWMSEL0   :1;
    unsigned char PWMSEL1   :1;
    unsigned char bit2      :1;
    unsigned char bit3      :1;
    unsigned char bit4      :1;
    unsigned char bit5      :1;
    unsigned char PWMCLK0   :1;
    unsigned char PWMCLK1   :1;
  } BIT;
  unsigned char BYTE;
};

#define PWMCON0     (*(volatile union pwmcon0_t    *)(0x0370))

/*--------------------------------------------------------------------------------*/
/* PWM0 Prescaler                                                                 */

#define PWMPRE0     (*(volatile union register8_t  *)(0x0372))

/*--------------------------------------------------------------------------------*/
/* PWM0 Register                                                                  */

#define PWMREG0     (*(volatile union register8_t  *)(0x0373))

/*--------------------------------------------------------------------------------*/
/* PWM1 Prescaler                                                                 */

#define PWMPRE1     (*(volatile union register8_t  *)(0x0374))

/*--------------------------------------------------------------------------------*/
/* PWM1 Register                                                                  */

#define PWMREG1     (*(volatile union register8_t  *)(0x0375))

/*--------------------------------------------------------------------------------*/
/* PWM Control Register 1                                                         */

union pwmcon1_t {
  struct {
    unsigned char PWMEN0    :1;
    unsigned char PWMEN1    :1;
    unsigned char PWMPORT0  :1;
    unsigned char PWMPORT1  :1;
    unsigned char bit4      :1;
    unsigned char bit5      :1;
    unsigned char bit6      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define PWMCON1     (*(volatile union pwmcon1_t    *)(0x0376))

/*--------------------------------------------------------------------------------*/
/* Count Source Protection Mode Register                                          */

union cspr_t {
  struct {
    unsigned char bit0      :1;
    unsigned char bit1      :1;
    unsigned char bit2      :1;
    unsigned char bit3      :1;
    unsigned char bit4      :1;
    unsigned char bit5      :1;
    unsigned char bit6      :1;
    unsigned char CSPRO     :1;
  } BIT;
  unsigned char BYTE;
};

#define CSPR        (*(volatile union cspr_t       *)(0x037C))

/*--------------------------------------------------------------------------------*/
/* Watchdog Timer Refresh Register                                                */

#define WDTR        (*(volatile union register8_t  *)(0x037D))

/*--------------------------------------------------------------------------------*/
/* Watchdog Timer Start Register                                                  */

#define WDTS        (*(volatile union register8_t  *)(0x037E))

/*--------------------------------------------------------------------------------*/
/* Watchdog Timer Control Register                                                */

union wdc_t {
  struct {
    unsigned char WDC0      :1;
    unsigned char WDC1      :1;
    unsigned char WDC2      :1;
    unsigned char WDC3      :1;
    unsigned char WDC4      :1;
    unsigned char bit5      :1;
    unsigned char bit6      :1;
    unsigned char WDC7      :1;
  } BIT;
  unsigned char BYTE;
};

#define WDC         (*(volatile union wdc_t        *)(0x037F))

/*--------------------------------------------------------------------------------*/
/* DMA2 Source Select Register                                                    */

union dm2sl_t {
  struct {
    unsigned char DSEL0     :1;
    unsigned char DSEL1     :1;
    unsigned char DSEL2     :1;
    unsigned char DSEL3     :1;
    unsigned char DSEL4     :1;
    unsigned char bit5      :1;
    unsigned char DMS       :1;
    unsigned char DSR       :1;
  } BIT;
  unsigned char BYTE;
};

#define DM2SL       (*(volatile union dm2sl_t      *)(0x0390))

/*--------------------------------------------------------------------------------*/
/* DMA3 Source Select Register                                                    */

union dm3sl_t {
  struct {
    unsigned char DSEL0     :1;
    unsigned char DSEL1     :1;
    unsigned char DSEL2     :1;
    unsigned char DSEL3     :1;
    unsigned char DSEL4     :1;
    unsigned char bit5      :1;
    unsigned char DMS       :1;
    unsigned char DSR       :1;
  } BIT;
  unsigned char BYTE;
};

#define DM3SL       (*(volatile union dm3sl_t      *)(0x0392))

/*--------------------------------------------------------------------------------*/
/* DMA0 Source Select Register                                                    */

union dm0sl_t {
  struct {
    unsigned char DSEL0     :1;
    unsigned char DSEL1     :1;
    unsigned char DSEL2     :1;
    unsigned char DSEL3     :1;
    unsigned char DSEL4     :1;
    unsigned char bit5      :1;
    unsigned char DMS       :1;
    unsigned char DSR       :1;
  } BIT;
  unsigned char BYTE;
};

#define DM0SL       (*(volatile union dm0sl_t      *)(0x0398))

/*--------------------------------------------------------------------------------*/
/* DMA1 Source Select Register                                                    */

union dm1sl_t {
  struct {
    unsigned char DSEL0     :1;
    unsigned char DSEL1     :1;
    unsigned char DSEL2     :1;
    unsigned char DSEL3     :1;
    unsigned char DSEL4     :1;
    unsigned char bit5      :1;
    unsigned char DMS       :1;
    unsigned char DSR       :1;
  } BIT;
  unsigned char BYTE;
};

#define DM1SL       (*(volatile union dm1sl_t      *)(0x039A))

/*--------------------------------------------------------------------------------*/
/* Open-Circuit Detection Assist Function Register                                */

union ainrst_t {
  struct {
    unsigned char bit0      :1;
    unsigned char bit1      :1;
    unsigned char bit2      :1;
    unsigned char bit3      :1;
    unsigned char AINRST0   :1;
    unsigned char AINRST1   :1;
    unsigned char bit6      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define AINRST      (*(volatile union ainrst_t     *)(0x03A2))

/*--------------------------------------------------------------------------------*/
/* SFR Snoop Address Register                                                     */

union crcsar_t {
  struct {
    unsigned char CRCSAR0   :1;
    unsigned char CRCSAR1   :1;
    unsigned char CRCSAR2   :1;
    unsigned char CRCSAR3   :1;
    unsigned char CRCSAR4   :1;
    unsigned char CRCSAR5   :1;
    unsigned char CRCSAR6   :1;
    unsigned char CRCSAR7   :1;
    unsigned char CRCSAR8   :1;
    unsigned char CRCSAR9   :1;
    unsigned char bit10     :1;
    unsigned char bit11     :1;
    unsigned char bit12     :1;
    unsigned char bit13     :1;
    unsigned char CRCSR     :1;
    unsigned char CRCSW     :1;
  } BIT;
  struct {
    unsigned char BYTE0;
    unsigned char BYTE1;
  } BYTES;
  unsigned short WORD;
};

#define CRCSAR      (*(volatile union crcsar_t     *)(0x03B4))

/*--------------------------------------------------------------------------------*/
/* CRC Data Register                                                              */

#define CRCD        (*(volatile union register16_t *)(0x03BC))

/*--------------------------------------------------------------------------------*/
/* CRC Input Register                                                             */

#define CRCIN       (*(volatile union register8_t  *)(0x03BE))

/*--------------------------------------------------------------------------------*/
/* CRC Mode Register                                                              */

union crcmr_t {
  struct {
    unsigned char CRCPS     :1;
    unsigned char bit1      :1;
    unsigned char bit2      :1;
    unsigned char bit3      :1;
    unsigned char bit4      :1;
    unsigned char bit5      :1;
    unsigned char bit6      :1;
    unsigned char CRCMS     :1;
  } BIT;
  unsigned char BYTE;
};

#define CRCMR       (*(volatile union crcmr_t      *)(0x03B6))

/*--------------------------------------------------------------------------------*/
/* A/D Register 0                                                                 */

#define AD0         (*(volatile union register16_t *)(0x03C0))

/*--------------------------------------------------------------------------------*/
/* A/D Register 1                                                                 */

#define AD1         (*(volatile union register16_t *)(0x03C2))

/*--------------------------------------------------------------------------------*/
/* A/D Register 2                                                                 */

#define AD2         (*(volatile union register16_t *)(0x03C4))

/*--------------------------------------------------------------------------------*/
/* A/D Register 3                                                                 */

#define AD3         (*(volatile union register16_t *)(0x03C6))

/*--------------------------------------------------------------------------------*/
/* A/D Register 4                                                                 */

#define AD4         (*(volatile union register16_t *)(0x03C8))

/*--------------------------------------------------------------------------------*/
/* A/D Register 5                                                                 */

#define AD5         (*(volatile union register16_t *)(0x03CA))

/*--------------------------------------------------------------------------------*/
/* A/D Register 6                                                                 */

#define AD6         (*(volatile union register16_t *)(0x03CC))

/*--------------------------------------------------------------------------------*/
/* A/D Register 7                                                                 */

#define AD7         (*(volatile union register16_t *)(0x03CE))

/*--------------------------------------------------------------------------------*/
/* A/D Control Register 2                                                         */

union adcon2_t {
  struct {
    unsigned char bit0      :1;
    unsigned char ADGSEL0   :1;
    unsigned char ADGSEL1   :1;
    unsigned char bit3      :1;
    unsigned char CKS2      :1;
    unsigned char bit5      :1;
    unsigned char bit6      :1;
    unsigned char CKS3      :1;
  } BIT;
  unsigned char BYTE;
};

#define ADCON2      (*(volatile union adcon2_t     *)(0x03D4))

/*--------------------------------------------------------------------------------*/
/* A/D Control Register 0                                                         */

union adcon0_t {
  struct {
    unsigned char CH0       :1;
    unsigned char CH1       :1;
    unsigned char CH2       :1;
    unsigned char MD0       :1;
    unsigned char MD1       :1;
    unsigned char TRG       :1;
    unsigned char ADST      :1;
    unsigned char CKS0      :1;
  } BIT;
  unsigned char BYTE;
};

#define ADCON0      (*(volatile union adcon0_t     *)(0x03D6))

/*--------------------------------------------------------------------------------*/
/* A/D Control Register 1                                                         */

union adcon1_t {
  struct {
    unsigned char SCAN0     :1;
    unsigned char SCAN1     :1;
    unsigned char MD2       :1;
    unsigned char bit3      :1;
    unsigned char CKS1      :1;
    unsigned char ADSTBY    :1;
    unsigned char ADEX0     :1;
    unsigned char ADEX1     :1;
  } BIT;
  unsigned char BYTE;
};

#define ADCON1      (*(volatile union adcon1_t     *)(0x03D7))

/*--------------------------------------------------------------------------------*/
/* D/A0 Register                                                                  */

#define DA0         (*(volatile union register8_t  *)(0x03D8))

/*--------------------------------------------------------------------------------*/
/* D/A1 Register                                                                  */

#define DA1         (*(volatile union register8_t  *)(0x03DA))

/*--------------------------------------------------------------------------------*/
/* D/A Control Register                                                           */

union dacon_t {
  struct {
    unsigned char DA0E      :1;
    unsigned char DA1E      :1;
    unsigned char bit2      :1;
    unsigned char bit3      :1;
    unsigned char bit4      :1;
    unsigned char bit5      :1;
    unsigned char bit6      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define DACON       (*(volatile union dacon_t      *)(0x03DC))

/*--------------------------------------------------------------------------------*/
/* Port P0 Register                                                               */

union p0_t {
  struct {
    unsigned char P0_0      :1;
    unsigned char P0_1      :1;
    unsigned char P0_2      :1;
    unsigned char P0_3      :1;
    unsigned char P0_4      :1;
    unsigned char P0_5      :1;
    unsigned char P0_6      :1;
    unsigned char P0_7      :1;
  } BIT;
  unsigned char BYTE;
};

#define P0          (*(volatile union p0_t         *)(0x03E0))

/*--------------------------------------------------------------------------------*/
/* Port P1 Register                                                               */

union p1_t {
  struct {
    unsigned char P1_0      :1;
    unsigned char P1_1      :1;
    unsigned char P1_2      :1;
    unsigned char P1_3      :1;
    unsigned char P1_4      :1;
    unsigned char P1_5      :1;
    unsigned char P1_6      :1;
    unsigned char P1_7      :1;
  } BIT;
  unsigned char BYTE;
};

#define P1          (*(volatile union p1_t         *)(0x03E1))

/*--------------------------------------------------------------------------------*/
/* Port P0 Direction Register                                                     */

union pd0_t {
  struct {
    unsigned char PD0_0     :1;
    unsigned char PD0_1     :1;
    unsigned char PD0_2     :1;
    unsigned char PD0_3     :1;
    unsigned char PD0_4     :1;
    unsigned char PD0_5     :1;
    unsigned char PD0_6     :1;
    unsigned char PD0_7     :1;
  } BIT;
  unsigned char BYTE;
};

#define PD0         (*(volatile union pd0_t        *)(0x03E2))

/*--------------------------------------------------------------------------------*/
/* Port P1 Direction Register                                                     */

union pd1_t {
  struct {
    unsigned char PD1_0     :1;
    unsigned char PD1_1     :1;
    unsigned char PD1_2     :1;
    unsigned char PD1_3     :1;
    unsigned char PD1_4     :1;
    unsigned char PD1_5     :1;
    unsigned char PD1_6     :1;
    unsigned char PD1_7     :1;
  } BIT;
  unsigned char BYTE;
};

#define PD1         (*(volatile union pd1_t        *)(0x03E3))

/*--------------------------------------------------------------------------------*/
/* Port P2 Register                                                               */

union p2_t {
  struct {
    unsigned char P2_0      :1;
    unsigned char P2_1      :1;
    unsigned char P2_2      :1;
    unsigned char P2_3      :1;
    unsigned char P2_4      :1;
    unsigned char P2_5      :1;
    unsigned char P2_6      :1;
    unsigned char P2_7      :1;
  } BIT;
  unsigned char BYTE;
};

#define P2          (*(volatile union p2_t         *)(0x03E4))

/*--------------------------------------------------------------------------------*/
/* Port P3 Register                                                               */

union p3_t {
  struct {
    unsigned char P3_0      :1;
    unsigned char P3_1      :1;
    unsigned char P3_2      :1;
    unsigned char P3_3      :1;
    unsigned char P3_4      :1;
    unsigned char P3_5      :1;
    unsigned char P3_6      :1;
    unsigned char P3_7      :1;
  } BIT;
  unsigned char BYTE;
};

#define P3          (*(volatile union p3_t         *)(0x03E5))

/*--------------------------------------------------------------------------------*/
/* Port P2 Direction Register                                                     */

union pd2_t {
  struct {
    unsigned char PD2_0     :1;
    unsigned char PD2_1     :1;
    unsigned char PD2_2     :1;
    unsigned char PD2_3     :1;
    unsigned char PD2_4     :1;
    unsigned char PD2_5     :1;
    unsigned char PD2_6     :1;
    unsigned char PD2_7     :1;
  } BIT;
  unsigned char BYTE;
};

#define PD2         (*(volatile union pd2_t        *)(0x03E6))

/*--------------------------------------------------------------------------------*/
/* Port P3 Direction Register                                                     */

union pd3_t {
  struct {
    unsigned char PD3_0     :1;
    unsigned char PD3_1     :1;
    unsigned char PD3_2     :1;
    unsigned char PD3_3     :1;
    unsigned char PD3_4     :1;
    unsigned char PD3_5     :1;
    unsigned char PD3_6     :1;
    unsigned char PD3_7     :1;
  } BIT;
  unsigned char BYTE;
};

#define PD3         (*(volatile union pd3_t        *)(0x03E7))

/*--------------------------------------------------------------------------------*/
/* Port P4 Register                                                               */

union p4_t {
  struct {
    unsigned char P4_0      :1;
    unsigned char P4_1      :1;
    unsigned char P4_2      :1;
    unsigned char P4_3      :1;
    unsigned char P4_4      :1;
    unsigned char P4_5      :1;
    unsigned char P4_6      :1;
    unsigned char P4_7      :1;
  } BIT;
  unsigned char BYTE;
};

#define P4          (*(volatile union p4_t         *)(0x03E8))

/*--------------------------------------------------------------------------------*/
/* Port P5 Register                                                               */

union p5_t {
  struct {
    unsigned char P5_0      :1;
    unsigned char P5_1      :1;
    unsigned char P5_2      :1;
    unsigned char P5_3      :1;
    unsigned char P5_4      :1;
    unsigned char P5_5      :1;
    unsigned char P5_6      :1;
    unsigned char P5_7      :1;
  } BIT;
  unsigned char BYTE;
};

#define P5          (*(volatile union p5_t         *)(0x03E9))

/*--------------------------------------------------------------------------------*/
/* Port P4 Direction Register                                                     */

union pd4_t {
  struct {
    unsigned char PD4_0     :1;
    unsigned char PD4_1     :1;
    unsigned char PD4_2     :1;
    unsigned char PD4_3     :1;
    unsigned char PD4_4     :1;
    unsigned char PD4_5     :1;
    unsigned char PD4_6     :1;
    unsigned char PD4_7     :1;
  } BIT;
  unsigned char BYTE;
};

#define PD4         (*(volatile union pd4_t        *)(0x03EA))

/*--------------------------------------------------------------------------------*/
/* Port P5 Direction Register                                                     */

union pd5_t {
  struct {
    unsigned char PD5_0     :1;
    unsigned char PD5_1     :1;
    unsigned char PD5_2     :1;
    unsigned char PD5_3     :1;
    unsigned char PD5_4     :1;
    unsigned char PD5_5     :1;
    unsigned char PD5_6     :1;
    unsigned char PD5_7     :1;
  } BIT;
  unsigned char BYTE;
};

#define PD5         (*(volatile union pd5_t        *)(0x03EB))

/*--------------------------------------------------------------------------------*/
/* Port P6 Register                                                               */

union p6_t {
  struct {
    unsigned char P6_0      :1;
    unsigned char P6_1      :1;
    unsigned char P6_2      :1;
    unsigned char P6_3      :1;
    unsigned char P6_4      :1;
    unsigned char P6_5      :1;
    unsigned char P6_6      :1;
    unsigned char P6_7      :1;
  } BIT;
  unsigned char BYTE;
};

#define P6          (*(volatile union p6_t         *)(0x03EC))

/*--------------------------------------------------------------------------------*/
/* Port P7 Register                                                               */

union p7_t {
  struct {
    unsigned char P7_0      :1;
    unsigned char P7_1      :1;
    unsigned char P7_2      :1;
    unsigned char P7_3      :1;
    unsigned char P7_4      :1;
    unsigned char P7_5      :1;
    unsigned char P7_6      :1;
    unsigned char P7_7      :1;
  } BIT;
  unsigned char BYTE;
};

#define P7          (*(volatile union p7_t         *)(0x03ED))

/*--------------------------------------------------------------------------------*/
/* Port P6 Direction Register                                                     */

union pd6_t {
  struct {
    unsigned char PD6_0     :1;
    unsigned char PD6_1     :1;
    unsigned char PD6_2     :1;
    unsigned char PD6_3     :1;
    unsigned char PD6_4     :1;
    unsigned char PD6_5     :1;
    unsigned char PD6_6     :1;
    unsigned char PD6_7     :1;
  } BIT;
  unsigned char BYTE;
};

#define PD6         (*(volatile union pd6_t        *)(0x03EE))

/*--------------------------------------------------------------------------------*/
/* Port P7 Direction Register                                                     */

union pd7_t {
  struct {
    unsigned char PD7_0     :1;
    unsigned char PD7_1     :1;
    unsigned char PD7_2     :1;
    unsigned char PD7_3     :1;
    unsigned char PD7_4     :1;
    unsigned char PD7_5     :1;
    unsigned char PD7_6     :1;
    unsigned char PD7_7     :1;
  } BIT;
  unsigned char BYTE;
};

#define PD7         (*(volatile union pd7_t        *)(0x03EF))

/*--------------------------------------------------------------------------------*/
/* Port P8 Register                                                               */

union p8_t {
  struct {
    unsigned char P8_0      :1;
    unsigned char P8_1      :1;
    unsigned char P8_2      :1;
    unsigned char P8_3      :1;
    unsigned char P8_4      :1;
    unsigned char P8_5      :1;
    unsigned char P8_6      :1;
    unsigned char P8_7      :1;
  } BIT;
  unsigned char BYTE;
};

#define P8          (*(volatile union p8_t         *)(0x03F0))

/*--------------------------------------------------------------------------------*/
/* Port P9 Register                                                               */

union p9_t {
  struct {
    unsigned char P9_0      :1;
    unsigned char P9_1      :1;
    unsigned char P9_2      :1;
    unsigned char P9_3      :1;
    unsigned char P9_4      :1;
    unsigned char P9_5      :1;
    unsigned char P9_6      :1;
    unsigned char P9_7      :1;
  } BIT;
  unsigned char BYTE;
};

#define P9          (*(volatile union p9_t         *)(0x03F1))

/*--------------------------------------------------------------------------------*/
/* Port P8 Direction Register                                                     */

union pd8_t {
  struct {
    unsigned char PD8_0     :1;
    unsigned char PD8_1     :1;
    unsigned char PD8_2     :1;
    unsigned char PD8_3     :1;
    unsigned char PD8_4     :1;
    unsigned char PD8_5     :1;
    unsigned char PD8_6     :1;
    unsigned char PD8_7     :1;
  } BIT;
  unsigned char BYTE;
};

#define PD8         (*(volatile union pd8_t        *)(0x03F2))

/*--------------------------------------------------------------------------------*/
/* Port P9 Direction Register                                                     */

union pd9_t {
  struct {
    unsigned char PD9_0     :1;
    unsigned char PD9_1     :1;
    unsigned char PD9_2     :1;
    unsigned char PD9_3     :1;
    unsigned char PD9_4     :1;
    unsigned char PD9_5     :1;
    unsigned char PD9_6     :1;
    unsigned char PD9_7     :1;
  } BIT;
  unsigned char BYTE;
};

#define PD9         (*(volatile union pd9_t        *)(0x03F3))

/*--------------------------------------------------------------------------------*/
/* Port P10 Register                                                              */

union p10_t {
  struct {
    unsigned char P10_0     :1;
    unsigned char P10_1     :1;
    unsigned char P10_2     :1;
    unsigned char P10_3     :1;
    unsigned char P10_4     :1;
    unsigned char P10_5     :1;
    unsigned char P10_6     :1;
    unsigned char P10_7     :1;
  } BIT;
  unsigned char BYTE;
};

#define P10         (*(volatile union p10_t        *)(0x03F4))

/*--------------------------------------------------------------------------------*/
/* Port P11 Register                                                              */

union p11_t {
  struct {
    unsigned char P11_0     :1;
    unsigned char P11_1     :1;
    unsigned char P11_2     :1;
    unsigned char P11_3     :1;
    unsigned char P11_4     :1;
    unsigned char P11_5     :1;
    unsigned char P11_6     :1;
    unsigned char P11_7     :1;
  } BIT;
  unsigned char BYTE;
};

#define P11         (*(volatile union p11_t        *)(0x03F5))

/*--------------------------------------------------------------------------------*/
/* Port P10 Direction Register                                                    */

union pd10_t {
  struct {
    unsigned char PD10_0    :1;
    unsigned char PD10_1    :1;
    unsigned char PD10_2    :1;
    unsigned char PD10_3    :1;
    unsigned char PD10_4    :1;
    unsigned char PD10_5    :1;
    unsigned char PD10_6    :1;
    unsigned char PD10_7    :1;
  } BIT;
  unsigned char BYTE;
};

#define PD10        (*(volatile union pd10_t       *)(0x03F6))

/*--------------------------------------------------------------------------------*/
/* Port P11 Direction Register                                                    */

union pd11_t {
  struct {
    unsigned char PD11_0    :1;
    unsigned char PD11_1    :1;
    unsigned char PD11_2    :1;
    unsigned char PD11_3    :1;
    unsigned char PD11_4    :1;
    unsigned char PD11_5    :1;
    unsigned char PD11_6    :1;
    unsigned char PD11_7    :1;
  } BIT;
  unsigned char BYTE;
};

#define PD11        (*(volatile union pd11_t       *)(0x03F7))

/*--------------------------------------------------------------------------------*/
/* Port P12 Register                                                              */

union p12_t {
  struct {
    unsigned char P12_0     :1;
    unsigned char P12_1     :1;
    unsigned char P12_2     :1;
    unsigned char P12_3     :1;
    unsigned char P12_4     :1;
    unsigned char P12_5     :1;
    unsigned char P12_6     :1;
    unsigned char P12_7     :1;
  } BIT;
  unsigned char BYTE;
};

#define P12         (*(volatile union p12_t        *)(0x03F8))

/*--------------------------------------------------------------------------------*/
/* Port P13 Register                                                              */

union p13_t {
  struct {
    unsigned char P13_0     :1;
    unsigned char P13_1     :1;
    unsigned char P13_2     :1;
    unsigned char P13_3     :1;
    unsigned char P13_4     :1;
    unsigned char P13_5     :1;
    unsigned char P13_6     :1;
    unsigned char P13_7     :1;
  } BIT;
  unsigned char BYTE;
};

#define P13         (*(volatile union p13_t        *)(0x03F9))

/*--------------------------------------------------------------------------------*/
/* Port P12 Direction Register                                                    */

union pd12_t {
  struct {
    unsigned char PD12_0    :1;
    unsigned char PD12_1    :1;
    unsigned char PD12_2    :1;
    unsigned char PD12_3    :1;
    unsigned char PD12_4    :1;
    unsigned char PD12_5    :1;
    unsigned char PD12_6    :1;
    unsigned char PD12_7    :1;
  } BIT;
  unsigned char BYTE;
};

#define PD12        (*(volatile union pd12_t       *)(0x03FA))

/*--------------------------------------------------------------------------------*/
/* Port P13 Direction Register                                                    */

union pd13_t {
  struct {
    unsigned char PD13_0    :1;
    unsigned char PD13_1    :1;
    unsigned char PD13_2    :1;
    unsigned char PD13_3    :1;
    unsigned char PD13_4    :1;
    unsigned char PD13_5    :1;
    unsigned char PD13_6    :1;
    unsigned char PD13_7    :1;
  } BIT;
  unsigned char BYTE;
};

#define PD13        (*(volatile union pd13_t       *)(0x03FB))

/*--------------------------------------------------------------------------------*/
/* Port P14 Register                                                              */

union p14_t {
  struct {
    unsigned char P14_0     :1;
    unsigned char P14_1     :1;
    unsigned char bit2      :1;
    unsigned char bit3      :1;
    unsigned char bit4      :1;
    unsigned char bit5      :1;
    unsigned char bit6      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define P14         (*(volatile union p14_t        *)(0x03FC))

/*--------------------------------------------------------------------------------*/
/* Port P14 Direction Register                                                    */

union pd14_t {
  struct {
    unsigned char PD14_0    :1;
    unsigned char PD14_1    :1;
    unsigned char bit2      :1;
    unsigned char bit3      :1;
    unsigned char bit4      :1;
    unsigned char bit5      :1;
    unsigned char bit6      :1;
    unsigned char bit7      :1;
  } BIT;
  unsigned char BYTE;
};

#define PD14        (*(volatile union pd14_t       *)(0x03FE))

/*--------------------------------------------------------------------------------*/
/* PMC0 Header Pattern Set Register (Min)                                         */

#define PMC0HDPMIN  (*(volatile union register16_t *)(0xD080))

/*--------------------------------------------------------------------------------*/
/* PMC0 Header Pattern Set Register (Max)                                         */

#define PMC0HDPMAX  (*(volatile union register16_t *)(0xD082))

/*--------------------------------------------------------------------------------*/
/* PMC0 Data 0 Pattern Set Register (Min)                                         */

#define PMC0D0PMIN  (*(volatile union register8_t  *)(0xD084))

/*--------------------------------------------------------------------------------*/
/* PMC0 Data 0 Pattern Set Register (Max)                                         */

#define PMC0D0PMAX  (*(volatile union register8_t  *)(0xD085))

/*--------------------------------------------------------------------------------*/
/* PMC0 Data 1 Pattern Set Register (Min)                                         */

#define PMC0D1PMIN  (*(volatile union register8_t  *)(0xD086))

/*--------------------------------------------------------------------------------*/
/* PMC0 Data 1 Pattern Set Register (Max)                                         */

#define PMC0D1PMAX  (*(volatile union register8_t  *)(0xD087))

/*--------------------------------------------------------------------------------*/
/* PMC0 Measurements Register                                                     */

#define PMC0TIM     (*(volatile union register16_t *)(0xD088))

/*--------------------------------------------------------------------------------*/
/* PMC0 Counter Value Register                                                    */

#define PMC0BC      (*(volatile union register16_t *)(0xD08A))

/*--------------------------------------------------------------------------------*/
/* PMC0 Receive Data Store Register 0                                             */

#define PMC0DAT0    (*(volatile union register8_t  *)(0xD08C))

/*--------------------------------------------------------------------------------*/
/* PMC0 Receive Data Store Register 1                                             */

#define PMC0DAT1    (*(volatile union register8_t  *)(0xD08D))

/*--------------------------------------------------------------------------------*/
/* PMC0 Receive Data Store Register 2                                             */

#define PMC0DAT2    (*(volatile union register8_t  *)(0xD08E))

/*--------------------------------------------------------------------------------*/
/* PMC0 Receive Data Store Register 3                                             */

#define PMC0DAT3    (*(volatile union register8_t  *)(0xD08F))

/*--------------------------------------------------------------------------------*/
/* PMC0 Receive Data Store Register 4                                             */

#define PMC0DAT4    (*(volatile union register8_t  *)(0xD090))

/*--------------------------------------------------------------------------------*/
/* PMC0 Receive Data Store Register 5                                             */

#define PMC0DAT5    (*(volatile union register8_t  *)(0xD091))

/*--------------------------------------------------------------------------------*/
/* PMC0 Receive Bit Count Register                                                */

#define PMC0RBIT    (*(volatile union register8_t  *)(0xD092))

/*--------------------------------------------------------------------------------*/
/* PMC1 Header Pattern Set Register (Min)                                         */

#define PMC1HDPMIN  (*(volatile union register16_t *)(0xD094))

/*--------------------------------------------------------------------------------*/
/* PMC1 Header Pattern Set Register (Max)                                         */

#define PMC1HDPMAX  (*(volatile union register16_t *)(0xD096))

/*--------------------------------------------------------------------------------*/
/* PMC1 Data 0 Pattern Set Register (Min)                                         */

#define PMC1D0PMIN  (*(volatile union register8_t  *)(0xD098))

/*--------------------------------------------------------------------------------*/
/* PMC1 Data 0 Pattern Set Register (Max)                                         */

#define PMC1D0PMAX  (*(volatile union register8_t  *)(0xD099))

/*--------------------------------------------------------------------------------*/
/* PMC1 Data 1 Pattern Set Register (Min)                                         */

#define PMC1D1PMIN  (*(volatile union register8_t  *)(0xD09A))

/*--------------------------------------------------------------------------------*/
/* PMC1 Data 1 Pattern Set Register (Max)                                         */

#define PMC1D1PMAX  (*(volatile union register8_t  *)(0xD09B))

/*--------------------------------------------------------------------------------*/
/* PMC1 Measurements Register                                                     */

#define PMC1TIM     (*(volatile union register16_t *)(0xD09C))

/*--------------------------------------------------------------------------------*/
/* PMC1 Counter Value Register                                                    */

#define PMC1BC      (*(volatile union register16_t *)(0xD09E))

/*--------------------------------------------------------------------------------*/

#endif /* __IOM16C65_H__ */
