/*
 * Copyright (c) 2004-2006, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


/**
 * @author Vlado Handziski <handzisk@tkn.tu-berlin.de>
 * @author Philipp Huppertz <huppertz@tkn.tu-berlin.de>
 */

#ifndef _H_Msp430Usart_h
#define _H_Msp430Usart_h

#define MSP430_HPLUSART0_RESOURCE "Msp430Usart0.Resource"
#define MSP430_SPI0_BUS "Msp430Spi0.Resource"
#define MSP430_UARTO_BUS "Msp430Uart0.Resource"
#define MSP430_I2C0_BUS "Msp430I2C0.Resource"

#define MSP430_HPLUSART1_RESOURCE "Msp430Usart1.Resource"
#define MSP430_SPI1_BUS "Msp430Spi1.Resource"
#define MSP430_UART1_BUS "Msp430Uart1.Resource"

typedef enum
{
  USART_NONE = 0,
  USART_UART = 1,
  USART_UART_TX = 2,
  USART_UART_RX = 3,
  USART_SPI = 4,
  USART_I2C = 5
} msp430_usartmode_t;

typedef struct {
  unsigned int swrst: 1;    //Software reset (0=operational; 1=reset)
  unsigned int mm: 1;       //Multiprocessor mode (0=idle-line protocol; 1=address-bit protocol)
  unsigned int sync: 1;     //Synchronous mode (0=UART; 1=SPI/I2C)
  unsigned int listen: 1;   //Listen enable (0=disabled; 1=enabled, feed tx back to receiver)
  unsigned int clen: 1;     //Character length (0=7-bit data; 1=8-bit data)
  unsigned int spb: 1;      //Stop bits (0=one stop bit; 1=two stop bits)
  unsigned int pev: 1;      //Parity select (0=odd; 1=even)
  unsigned int pena: 1;     //Parity enable (0=disabled; 1=enabled)
} __attribute__ ((packed)) msp430_uctl_t ;

typedef struct {
  unsigned int txept:1;      //Transmitter empty (0=busy; 1=TX buffer empty or SWRST=1)
  unsigned int stc:1;       //Slave transmit (0=4-pin SPI && STE enabled; 1=3-pin SPI && STE disabled)
  unsigned int txwake: 1;   //Transmiter wake (0=next char is data; 1=next char is address)
  unsigned int urxse: 1;    //Receive start-edge detection (0=disabled; 1=enabled)
  unsigned int ssel: 2;     //Clock source (00=UCLKI; 01=ACLK; 10=SMCLK; 11=SMCLK)
  unsigned int ckpl: 1;     //Clock polarity (0=normal; 1=inverted)
  unsigned int ckph:1;      //Clock phase (0=normal; 1=half-cycle delayed)
} __attribute__ ((packed)) msp430_utctl_t;

typedef struct {
  unsigned int rxerr: 1;    //Receive error (0=no errors; 1=error detected)
  unsigned int rxwake: 1;   //Receive wake-up (0=received data; 1=received an address)
  unsigned int urxwie: 1;   //Wake-up interrupt-enable (0=all characters set URXIFGx; 1=only address sets URXIFGx)
  unsigned int urxeie: 1;   //Erroneous-character receive (0=rejected; 1=recieved and URXIFGx set)
  unsigned int brk:1;       //Break detect (0=no break; 1=break occured)
  unsigned int oe:1;        //Overrun error (0=no error; 1=overrun error)
  unsigned int pe:1;        //Parity error (0=no error; 1=parity error)
  unsigned int fe:1;        //Framing error (0=no error; 1=low stop bit)
} __attribute__ ((packed)) msp430_urctl_t;

DEFINE_UNION_CAST(uctl2int,uint8_t,msp430_uctl_t)
DEFINE_UNION_CAST(int2uctl,msp430_uctl_t,uint8_t)

DEFINE_UNION_CAST(utctl2int,uint8_t,msp430_utctl_t)
DEFINE_UNION_CAST(int2utctl,msp430_utctl_t,uint8_t)

DEFINE_UNION_CAST(urctl2int,uint8_t,msp430_urctl_t)
DEFINE_UNION_CAST(int2urctl,msp430_urctl_t,uint8_t)

typedef struct {
  unsigned int ubr: 16;     //Clock division factor (>=0x0002)
  
  unsigned int :1;
  unsigned int mm: 1;       //Master mode (0=slave; 1=master)
  unsigned int :1;
  unsigned int listen: 1;   //Listen enable (0=disabled; 1=enabled, feed tx back to receiver)
  unsigned int clen: 1;     //Character length (0=7-bit data; 1=8-bit data)
  unsigned int: 3;
  
  unsigned int:1;
  unsigned int stc: 1;      //Slave transmit (0=4-pin SPI && STE enabled; 1=3-pin SPI && STE disabled)
  unsigned int:2;
  unsigned int ssel: 2;     //Clock source (00=external UCLK [slave]; 01=ACLK [master]; 10=SMCLK [master] 11=SMCLK [master]); 
  unsigned int ckpl: 1;     //Clock polarity (0=inactive is low && data at rising edge; 1=inverted)
  unsigned int ckph: 1;     //Clock phase (0=normal; 1=half-cycle delayed)
  unsigned int :0;
} msp430_spi_config_t;

typedef struct {
  uint16_t ubr;
  uint8_t uctl;
  uint8_t utctl;
} msp430_spi_registers_t;

typedef union {
  msp430_spi_config_t spiConfig;
  msp430_spi_registers_t spiRegisters;
} msp430_spi_union_config_t;

msp430_spi_union_config_t msp430_spi_default_config = { 
  {
    ubr : 0x0002, 
    ssel : 0x02, 
    clen : 1, 
    listen : 0, 
    mm : 1, 
    ckph : 1, 
    ckpl : 0, 
    stc : 1
  } 
};
    
    
    
/**
  The calculations were performed using the msp-uart.pl script:
  msp-uart.pl -- calculates the uart registers for MSP430

  Copyright (C) 2002 - Pedro Zorzenon Neto - pzn dot debian dot org
 **/
typedef enum {
  //32KHZ = 32,768 Hz, 1MHZ = 1,048,576 Hz
  UBR_32KHZ_1200=0x001B,    UMCTL_32KHZ_1200=0x94,
  UBR_32KHZ_1800=0x0012,    UMCTL_32KHZ_1800=0x84,
  UBR_32KHZ_2400=0x000D,    UMCTL_32KHZ_2400=0x6D,
  UBR_32KHZ_4800=0x0006,    UMCTL_32KHZ_4800=0x77,
  UBR_32KHZ_9600=0x0003,    UMCTL_32KHZ_9600=0x29,  // (Warning: triggers MSP430 errata US14)

  UBR_1MHZ_1200=0x0369,   UMCTL_1MHZ_1200=0x7B,
  UBR_1MHZ_1800=0x0246,   UMCTL_1MHZ_1800=0x55,
  UBR_1MHZ_2400=0x01B4,   UMCTL_1MHZ_2400=0xDF,
  UBR_1MHZ_4800=0x00DA,   UMCTL_1MHZ_4800=0xAA,
  UBR_1MHZ_9600=0x006D,   UMCTL_1MHZ_9600=0x44,
  UBR_1MHZ_19200=0x0036,  UMCTL_1MHZ_19200=0xB5,
  UBR_1MHZ_38400=0x001B,  UMCTL_1MHZ_38400=0x94,
  UBR_1MHZ_57600=0x0012,  UMCTL_1MHZ_57600=0x84,
  UBR_1MHZ_76800=0x000D,  UMCTL_1MHZ_76800=0x6D,
  UBR_1MHZ_115200=0x0009, UMCTL_1MHZ_115200=0x10,
  UBR_1MHZ_230400=0x0004, UMCTL_1MHZ_230400=0x55,
} msp430_uart_rate_t;

typedef struct {
  unsigned int ubr:16;      //Baud rate (use enum msp430_uart_rate_t for predefined rates)
  
  unsigned int umctl: 8;    //Modulation (use enum msp430_uart_rate_t for predefined rates)
  
  unsigned int :1;
  unsigned int mm: 1;       //Multiprocessor mode (0=idle-line protocol; 1=address-bit protocol)
  unsigned int :1;
  unsigned int listen: 1;   //Listen enable (0=disabled; 1=enabled, feed tx back to receiver)
  unsigned int clen: 1;     //Character length (0=7-bit data; 1=8-bit data)
  unsigned int spb: 1;      //Stop bits (0=one stop bit; 1=two stop bits)
  unsigned int pev: 1;      //Parity select (0=odd; 1=even)
  unsigned int pena: 1;     //Parity enable (0=disabled; 1=enabled)
  unsigned int :0;
  
  unsigned int :3;
  unsigned int urxse: 1;    //Receive start-edge detection (0=disabled; 1=enabled)
  unsigned int ssel: 2;     //Clock source (00=UCLKI; 01=ACLK; 10=SMCLK; 11=SMCLK)
  unsigned int ckpl: 1;     //Clock polarity (0=normal; 1=inverted)
  unsigned int :1;
  
  unsigned int :2;
  unsigned int urxwie: 1;   //Wake-up interrupt-enable (0=all characters set URXIFGx; 1=only address sets URXIFGx)
  unsigned int urxeie: 1;   //Erroneous-character receive (0=rejected; 1=recieved and URXIFGx set)
  unsigned int :4;
  unsigned int :0;
  
  unsigned int utxe:1;			// 1:enable tx module
  unsigned int urxe:1;			// 1:enable rx module
} msp430_uart_config_t;

typedef struct {
  uint16_t ubr;
  uint8_t umctl;
  uint8_t uctl;
  uint8_t utctl;
  uint8_t urctl;
  uint8_t ume;
} msp430_uart_registers_t;

typedef union {
  msp430_uart_config_t uartConfig;
  msp430_uart_registers_t uartRegisters;
} msp430_uart_union_config_t;
    
msp430_uart_union_config_t msp430_uart_default_config = { 
  {
    utxe : 1, 
    urxe : 1, 
    ubr : UBR_1MHZ_57600, 
    umctl : UMCTL_1MHZ_57600, 
    ssel : 0x02, 
    pena : 0, 
    pev : 0, 
    spb : 0, 
    clen : 1, 
    listen : 0, 
    mm : 0, 
    ckpl : 0, 
    urxse : 0, 
    urxeie : 1, 
    urxwie : 0,
    utxe : 1,
    urxe : 1
  } 
};



typedef struct {
  unsigned int i2cstt: 1; // I2CSTT Bit 0 START bit. (0=No action; 1=Send START condition)
  unsigned int i2cstp: 1; // I2CSTP Bit 1 STOP bit. (0=No action; 1=Send STOP condition)
  unsigned int i2cstb: 1; // I2CSTB Bit 2 Start byte. (0=No action; 1=Send START condition and start byte (01h))
  unsigned int i2cctrx: 1; //I2CTRX Bit 3 I2C transmit. (0=Receive mode; 1=Transmit mode) pin.
  unsigned int i2cssel: 2; // I2C clock source select. (00=No clock; 01=ACLK; 10=SMCLK; 11=SMCLK)
  unsigned int i2ccrm: 1;  // I2C repeat mode 
  unsigned int i2cword: 1; // I2C word mode. Selects byte(=0) or word(=1) mode for the I2C data register.
} __attribute__ ((packed)) msp430_i2ctctl_t;

DEFINE_UNION_CAST(i2ctctl2int,uint8_t,msp430_i2ctctl_t)
DEFINE_UNION_CAST(int2i2ctctl,msp430_i2ctctl_t,uint8_t)

typedef struct {
  unsigned int :1;
  unsigned int mst: 1;      //Master mode (0=slave; 1=master)
  unsigned int :1;
  unsigned int listen: 1;   //Listen enable (0=disabled; 1=enabled, feed tx back to receiver)
  unsigned int xa: 1;       //Extended addressing (0=7-bit addressing; 1=8-bit addressing)
  unsigned int :1;
  unsigned int txdmaen: 1;  //DMA to TX (0=disabled; 1=enabled)
  unsigned int rxdmaen: 1;  //RX to DMA (0=disabled; 1=enabled)
    
  unsigned int :4;
  unsigned int i2cssel: 2;  //Clock source (00=disabled; 01=ACLK; 10=SMCLK; 11=SMCLK)
  unsigned int i2crm: 1;    //Repeat mode (0=use I2CNDAT; 1=count in software)
  unsigned int i2cword: 1;  //Word mode (0=byte mode; 1=word mode)
  
  unsigned int i2cpsc: 8;   //Clock prescaler (values >0x04 not recomended)
  
  unsigned int i2csclh: 8;  //High period (high period=[value+2]*i2cpsc; can not be lower than 5*i2cpsc)
  
  unsigned int i2cscll: 8;  //Low period (low period=[value+2]*i2cpsc; can not be lower than 5*i2cpsc)
  
  unsigned int i2coa : 10;  // Own address register.
  unsigned int :6;
} msp430_i2c_config_t;
    
typedef struct {
  uint8_t uctl;
  uint8_t i2ctctl;
  uint8_t i2cpsc;
  uint8_t i2csclh;
  uint8_t i2cscll;
  uint16_t i2coa;
} msp430_i2c_registers_t;

typedef union {
  msp430_i2c_config_t i2cConfig;
  msp430_i2c_registers_t i2cRegisters;
} msp430_i2c_union_config_t;

msp430_i2c_union_config_t msp430_i2c_default_config = { 
  {
    rxdmaen : 0, 
    txdmaen : 0, 
    xa : 0, 
    listen : 0, 
    mst : 1,
    i2cword : 0, 
    i2crm : 1, 
    i2cssel : 0x2, 
    i2cpsc : 0, 
    i2csclh : 0x3, 
    i2cscll : 0x3,
    i2coa : 0,
  } 
};

typedef uint8_t uart_speed_t;
typedef uint8_t uart_parity_t;
typedef uint8_t uart_duplex_t;

enum {
  TOS_UART_1200   = 0,
  TOS_UART_1800   = 1,
  TOS_UART_2400   = 2,
  TOS_UART_4800   = 3,
  TOS_UART_9600   = 4,
  TOS_UART_19200  = 5,
  TOS_UART_38400  = 6,
  TOS_UART_57600  = 7,
  TOS_UART_76800  = 8,
  TOS_UART_115200 = 9,
  TOS_UART_230400 = 10
};

enum {
  TOS_UART_OFF,
  TOS_UART_RONLY,
  TOS_UART_TONLY,
  TOS_UART_DUPLEX
};

enum {
  TOS_UART_PARITY_NONE,
  TOS_UART_PARITY_EVEN,
  TOS_UART_PARITY_ODD
};

#endif//_H_Msp430Usart_h
