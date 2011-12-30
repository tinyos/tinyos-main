/*
 * Copyright (c) 2010-2011 Eric B. Decker
 * Copyright (c) 2009-2010 DEXMA SENSORS SL
 * All rights reserved.
 *
 * Copyright (c) 2004-2006, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 *
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 *
 * - Neither the name of the copyright holders nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * @author Vlado Handziski <handzisk@tkn.tu-berlin.de>
 * @author Philipp Huppertz <huppertz@tkn.tu-berlin.de>
 * @author Xavier Orduna <xorduna@dexmatech.com>
 * @author Eric B. Decker <cire831@gmail.com>
 * @author Jordi Soucheiron <jsoucheiron@dexmatech.com>
 *
 * Support the x2 version of the USCI for the TI MSPx2xx (see TI MSP430x2xx
 * Users guide slau144e).
 */

#ifndef _H_MSP430USCI_H
#define _H_MSP430USCI_H

/*
 * The MSP430X architecture at least the msp430f2618 family
 * has a total of four ports that can be used independently
 * usciA0, A1 (uart, spi) and usciB0, B1 (i2c, spi only).
 *
 * We set the resources up so multiple use of a given port
 * can be arbritrated.
 *
 * UART0 -> usciA0	SPI2 -> usciA0
 * UART1 -> usciA1	SPI3 -> usciA1
 * SPI0  -> usciB0	I2C0
 * SPI1  -> usciB1	I2C1
 *
 * spi2,3 are mapped to usciA0,A1 because the typical
 * configuration is to use dual uarts and dual spis
 * so the less used configuration maps as 2 and 3.
 */

//USCI A0, A1: UART, SPI
#define MSP430_HPLUSCIA0_RESOURCE "Msp430UsciA0.Resource"
#define MSP430_HPLUSCIA1_RESOURCE "Msp430UsciA1.Resource"
#define MSP430_UART0_BUS          MSP430_HPLUSCIA0_RESOURCE
#define MSP430_UART1_BUS          MSP430_HPLUSCIA1_RESOURCE
#define MSP430_SPI2_BUS           MSP430_HPLUSCIA0_RESOURCE
#define MSP430_SPI3_BUS           MSP430_HPLUSCIA1_RESOURCE

//USCI B0, B1: SPI,  I2C
#define MSP430_HPLUSCIB0_RESOURCE "Msp430UsciB0.Resource"
#define MSP430_HPLUSCIB1_RESOURCE "Msp430UsciB1.Resource"
#define MSP430_SPI0_BUS		  MSP430_HPLUSCIB0_RESOURCE
#define MSP430_SPI1_BUS		  MSP430_HPLUSCIB1_RESOURCE
#define MSP430_I2C0_BUS		  MSP430_HPLUSCIB0_RESOURCE
#define MSP430_I2C1_BUS		  MSP430_HPLUSCIB1_RESOURCE

typedef enum {
  USCI_NONE = 0,
  USCI_UART = 1,
  USCI_SPI = 2,
  USCI_I2C = 3
} msp430_uscimode_t;


/************************************************************************************************************
 *
 * UART mode definitions
 *
 */

/*
 * UCAxCTL0, UART control 0, uart mode
 */

typedef struct {
  unsigned int ucsync : 1;   // Synchronous mode enable (0=Asynchronous; 1:Synchronous)
  unsigned int ucmode : 2;   // USCI Mode (00=UART Mode; 01=Idle-Line; 10=Addres-Bit; 11=UART Mode, auto baud rate detection)
  unsigned int ucspb  : 1;   // Stop bit select. Number of stop bits (0=One stop bit; 1=Two stop bits)
  unsigned int uc7bit : 1;   // Charactaer lenght, (0=8-bit data; 1=7-bit data)
  unsigned int ucmsb  : 1;   // endian.  Direction of the rx and tx shift (0=LSB first, 1=MSB first)
  unsigned int ucpar  : 1;   // Parity Select (0=odd parity; 1=Even parity)
  unsigned int ucpen  : 1;   // Parity enable (0=Parity disable; 1=Parity enabled)
} __attribute__ ((packed)) msp430_uctl0_t ;


/*
 * UCAxCTL1, UART control 1, uart mode
 */

typedef struct {
  unsigned int ucswrst  : 1;  //Software reset enable (0=disabled; 1=enabled)
  unsigned int uctxbrk  : 1;  //Transmit break. (0 = no brk; 1 = tx break next frame
  unsigned int uctxaddr : 1;  //Transmit address. (0=next frame transmitted is data; 1=next frame transmitted is an address)
  unsigned int ucdorm   : 1;  //Dormant.  (0 = not dormant; 1 = Dormant, only some chars will set UCAxRXIFG)
  unsigned int ucbrkie  : 1;  //rx break interrupt -enable, 1 = enabled
  unsigned int ucrxeie  : 1;  //rx error interrupt-enable
  unsigned int ucssel   : 2;  //USCI clock source select: (00=UCKL; 01=ACLK; 10=SMCLK; 11=SMCLK
} __attribute__ ((packed)) msp430_uctl1_t ;


//converts from typedefstructs to uint8_t
DEFINE_UNION_CAST(uctl02int,uint8_t,msp430_uctl0_t)
DEFINE_UNION_CAST(int2uctl0,msp430_uctl0_t,uint8_t)
DEFINE_UNION_CAST(uctl12int,uint8_t,msp430_uctl1_t)
DEFINE_UNION_CAST(int2uctl1,msp430_uctl1_t,uint8_t)


/*
 * The usci/uart baud rate mechanism is significantly different
 * than the msp430 usart uart.  See section 15.3.9 of the TI
 * MSP430x2xx Family User's Guide, slau144e for details.
 *
 * For 32768Hz and 1048576Hz, we use UCOS16=0.
 * For higher cpu dco speeds we use oversampling, UCOS16=1.
 */

typedef enum {
  UBR_32KHZ_1200=0x001B,    UMCTL_32KHZ_1200=0x04,
  UBR_32KHZ_2400=0x000D,    UMCTL_32KHZ_2400=0x0c,
  UBR_32KHZ_4800=0x0006,    UMCTL_32KHZ_4800=0x0e,
  UBR_32KHZ_9600=0x0003,    UMCTL_32KHZ_9600=0x06,  

  UBR_1048MHZ_9600=0x006D,   UMCTL_1048MHZ_9600=0x04,
  UBR_1048MHZ_19200=0x0036,  UMCTL_1048MHZ_19200=0x0a,
  UBR_1048MHZ_38400=0x001B,  UMCTL_1048MHZ_38400=0x04,
  UBR_1048MHZ_57600=0x0012,  UMCTL_1048MHZ_57600=0x0c,
  UBR_1048MHZ_115200=0x0009, UMCTL_1048MHZ_115200=0x02,
  UBR_1048MHZ_128000=0x0008, UMCTL_1048MHZ_128000=0x02,
  UBR_1048MHZ_256000=0x0004, UMCTL_1048MHZ_230400=0x02,

  /* 1MHz = 1000000 Hz, 4MHz 4000000, 8MHz 8000000
   * 16MHz 16000000.   use UCOS16 for oversampling,
   * use both UCBRF and UCBRS.
   *
   * Settings for 1MHz, 8Mhz, and 16MHz are taken from
   * a table on page 15-22 of slau144e.
   */
  UBR_1MHZ_9600=0x6,       UMCTL_1MHZ_9600=0x81,
  UBR_1MHZ_19200=0x3,      UMCTL_1MHZ_19200=0x41,
  UBR_1MHZ_57600=0x1,      UMCTL_1MHZ_57600=0x0F,

  UBR_8MHZ_4800=0x68,      UMCTL_8MHZ_4800=0x31,
  UBR_8MHZ_9600=0x34,      UMCTL_8MHZ_9600=0x11,
  UBR_8MHZ_19200=0x1A,     UMCTL_8MHZ_19200=0x11,
  UBR_8MHZ_38400=0x0D,     UMCTL_8MHZ_38400=0x01,
  UBR_8MHZ_57600=0x08,     UMCTL_8MHZ_57600=0xB1,
  UBR_8MHZ_115200=0x04,    UMCTL_8MHZ_115200=0x3B,
  UBR_8MHZ_230400=0x02,    UMCTL_8MHZ_230400=0x27,

  UBR_16MHZ_4800=0xD0,     UMCTL_16MHZ_4800=0x51,
  UBR_16MHZ_9600=0x68,     UMCTL_16MHZ_9600=0x31,
  UBR_16MHZ_19200=0x34,    UMCTL_16MHZ_19200=0x11,
  UBR_16MHZ_38400=0x1A,    UMCTL_16MHZ_38400=0x11,
  UBR_16MHZ_57600=0x11,    UMCTL_16MHZ_57600=0x61,
  UBR_16MHZ_115200=0x8,    UMCTL_16MHZ_115200=0xB1,
  UBR_16MHZ_230400=0x4,    UMCTL_16MHZ_230400=0x3B,
} msp430_uart_rate_t;


typedef struct {
  unsigned int ubr: 16;		// Baud rate (use enum msp430_uart_rate_t for predefined rates)
  unsigned int umctl: 8;	// Modulation (use enum msp430_uart_rate_t for predefined rates)

  /* start of ctl0 */
  unsigned int : 1;		// ucsync, should be 0 for uart
  unsigned int ucmode: 2;       // mode: 00 - uart, 01 - Idle, 10 - addr bit, 11 - auto baud.
  unsigned int ucspb: 1;	// stop: 0 - one, 1 - two
  unsigned int uc7bit: 1;	// 7 or 8 bit
  unsigned int : 1;		// msb or lsb first, 0 says lsb, uart should be 0
  unsigned int ucpar: 1;	// par, 0 odd, 1 even
  unsigned int ucpen: 1;	// par enable, 0 disabled

  /* start of ctl1 */
  unsigned int : 5;		// not specified, defaults to 0.
  unsigned int ucrxeie: 1;	// rx err int enable
  unsigned int ucssel: 2;	// clock select, 00 uclk, 01 aclk, 10/11 smclk
  
  /* ume, not a control register, backward compatible with usart?
   * should be okay to nuke.  Is this actually used?
   */
  unsigned int utxe:1;			// 1:enable tx module
  unsigned int urxe:1;			// 1:enable rx module
} msp430_uart_config_t;

typedef struct {
  uint16_t ubr;
  uint8_t  umctl;
  uint8_t  uctl0;
  uint8_t  uctl1;
  uint8_t  ume;
} msp430_uart_registers_t;

typedef union {
  msp430_uart_config_t    uartConfig;
  msp430_uart_registers_t uartRegisters;
} msp430_uart_union_config_t;


const msp430_uart_union_config_t msp430_uart_default_config = { {
  ubr     :	UBR_8MHZ_115200,
  umctl   :	UMCTL_8MHZ_115200,
  ucmode  :	0,			// uart
  ucspb   :	0,			// one stop
  uc7bit  :	0,			// 8 bit
  ucpar   :	0,			// odd parity (but no parity)
  ucpen   :	0,			// parity disabled
  ucrxeie :	0,			// err int off
  ucssel  :	2,			// smclk
  utxe    :	1,			// enable tx
  urxe    :	1,			// enable rx
} };


/************************************************************************************************************
 *
 * SPI mode definitions
 *
 */

typedef struct {
  unsigned int ubr    : 16;	// Clock division factor (> = 1)

  /* ctl0 */
  unsigned int        : 1;	// ucsync, forced to 1 by initilization code.
  unsigned int ucmode : 2;	// 00 3pin spi, 01 4pin ste ah, 10 ste al, 11 i2c
  unsigned int ucmst  : 1;	// 0 slave, 1 master
  unsigned int uc7bit : 1;	// 0 8 bit, 1 7 bit.
  unsigned int ucmsb  : 1;	// 0 lsb first, 1 msb first
  unsigned int ucckpl : 1;	// 0 inactive low, 1 inactive high
  unsigned int ucckph : 1;	// 0 tx rising uclk, captured falling
				// 1 captured rising, sent falling edge.
  /* ctl1 */
  unsigned int        : 1;	// ucswrst, forced to 1 on init
  unsigned int        : 5;	// unused.
  unsigned int ucssel : 2;	// BRCLK src, 00 NA, 01 ACLK, 10/11 SMCLK
} msp430_spi_config_t;


typedef struct {
  uint16_t ubr;
  uint8_t  uctl0;
  uint8_t  uctl1;
} msp430_spi_registers_t;

typedef union {
  msp430_spi_config_t spiConfig;
  msp430_spi_registers_t spiRegisters;
} msp430_spi_union_config_t;


const msp430_spi_union_config_t msp430_spi_default_config = { {
  ubr		: 2,			/* smclk/2   */
  ucmode	: 0,			/* 3 pin, no ste */
  ucmst		: 1,			/* master */
  uc7bit	: 0,			/* 8 bit */
  ucmsb		: 1,			/* msb first, compatible with msp430 usart */
  ucckpl	: 0,			/* inactive state low */
  ucckph	: 1,			/* data captured on rising, changed falling */
  ucssel	: 2,			/* smclk */
} };
    
    
/************************************************************************************************************
 *
 * I2C mode definitions
 *
 */

typedef struct {
  unsigned int         : 1;	// Sync mode enable, 1 = sync, must be 1 for i2c
  unsigned int ucmode  : 2;	// 11 for i2c
  unsigned int ucmst   : 1;	// 0 slave, 1 master
  unsigned int         : 1;	// unused
  unsigned int ucmm    : 1;	// multi master mode
  unsigned int ucsla10 : 1;	// slave addr 7 or 10 bit
  unsigned int uca10   : 1;	// own addr   7 or 10 bit
} __attribute__ ((packed)) msp430_i2cctl0_t ;


DEFINE_UNION_CAST(i2cctl02int,uint8_t,msp430_i2cctl0_t)
DEFINE_UNION_CAST(int2i2cctl0,msp430_i2cctl0_t,uint8_t)


typedef struct {
  unsigned int ucswrst  : 1;	// Software reset (1 = reset)
  unsigned int uctxstt  : 1;	// Transmit start in master.
  unsigned int uctxstp  : 1;	// Transmit stop in master.
  unsigned int uctxnack : 1;	// transmit nack
  unsigned int uctr     : 1;	// 0 rx, 1 tx
  unsigned int          : 1;	// unused
  unsigned int ucssel   : 2;	// USCI clock source: (00 UCLKI; 01 ACLK; 10/11 SMCLK
} __attribute__ ((packed)) msp430_i2cctl1_t ;


typedef struct {
  uint16_t ubr    : 16;			/* baud rate divisor */

  /* ctl0 */
  uint8_t         : 1;			/* ucsync, forced to 1 by init code */
  uint8_t ucmode  : 2;			/* mode, must be 3 for i2c */
  uint8_t ucmst   : 1;			/* master if 1 */
  uint8_t         : 1;			/* unused */
  uint8_t ucmm    : 1;			/* mult-master mode */
  uint8_t ucsla10 : 1;			/* slave addr 10 bits vs. 7 */
  uint8_t uca10   : 1;			/* own addressing mode 10 bits vs. 7 */

  /* ctl1 */
  uint8_t         : 1;			/* software reset */
  uint8_t         : 1;			/* gen tx start */
  uint8_t         : 1;			/* gen tx stop */
  uint8_t         : 1;			/* gen nack */
  uint8_t uctr    : 1;			/* tx/rx mode, 1 = tx */
  uint8_t         : 1;			/* unused */
  uint8_t ucssel  : 2;			/* clock src, 00 uclk, 01 aclk, 10/11 smclk */

  /* own addr */
  uint16_t i2coa  : 10;			/* own address */
  uint8_t         : 5;			/* unused */
  uint8_t ucgcen  : 1;			/* general call response enable */
} msp430_i2c_config_t;
    
typedef struct {
  uint16_t ubr;				/* 16 bit baud rate */
  uint8_t  uctl0;			/* control word 0 */
  uint8_t  uctl1;			/* control word 1 */
  uint16_t ui2coa;			/* own address, ucgcen */
} msp430_i2c_registers_t;

typedef union {
  msp430_i2c_config_t i2cConfig;
  msp430_i2c_registers_t i2cRegisters;
} msp430_i2c_union_config_t;


const msp430_i2c_union_config_t msp430_i2c_default_config = { {
    ubr     : 2,			/* smclk/2 */
    ucmode  : 3,			/* i2c mode */
    ucmst   : 1,			/* master */
    ucmm    : 0,			/* single master */
    ucsla10 : 1,			/* 10 bit slave */
    uca10   : 1,			/* 10 bit us */
    uctr    : 1,			/* tx mode to start */
    ucssel  : 2,			/* smclk */
    i2coa   : 1,			/* our address is 1 */
    ucgcen  : 1,			/* respond to general call */
  } };

#endif	/* _H_MSP430USCI_H */
