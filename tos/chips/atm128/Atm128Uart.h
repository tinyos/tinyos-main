// $Id: Atm128Uart.h,v 1.5 2009-09-14 00:25:59 scipio Exp $

/*
 * Copyright (c) 2004-2005 Crossbow Technology, Inc.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL CROSSBOW TECHNOLOGY OR ANY OF ITS LICENSORS BE LIABLE TO 
 * ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL 
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF CROSSBOW OR ITS LICENSOR HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH 
 * DAMAGE. 
 *
 * CROSSBOW TECHNOLOGY AND ITS LICENSORS SPECIFICALLY DISCLAIM ALL WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY 
 * AND FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE PROVIDED HEREUNDER IS 
 * ON AN "AS IS" BASIS, AND NEITHER CROSSBOW NOR ANY LICENSOR HAS ANY 
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR 
 * MODIFICATIONS.
 */

// @author Martin Turon <mturon@xbow.com>

#ifndef _H_Atm128Uart_h
#define _H_Atm128Uart_h

//====================== UART Bus ==================================

typedef uint8_t Atm128_UDR0_t;  //!< USART0 I/O Data Register
typedef uint8_t Atm128_UDR1_t;  //!< USART1 I/O Data Register

/* UART Status Register */
typedef union {
  struct Atm128_UCSRA_t {
    uint8_t mpcm : 1;  //!< UART Multiprocessor Communication Mode
    uint8_t u2x  : 1;  //!< UART Double Transmission Speed 
    uint8_t upe  : 1;  //!< UART Parity Error
    uint8_t dor  : 1;  //!< UART Data Overrun
    uint8_t fe   : 1;  //!< UART Frame Error
    uint8_t udre : 1;  //!< USART Data Register Empty
    uint8_t txc  : 1;  //!< USART Transfer Complete
    uint8_t rxc  : 1;  //!< USART Receive Complete
  } bits;
  uint8_t flat;
} Atm128UartStatus_t;

typedef Atm128UartStatus_t Atm128_UCSR0A_t;  //!< UART 0 Status Register
typedef Atm128UartStatus_t Atm128_UCSR1A_t;  //!< UART 1 Status Register

/* UART Control Register */
typedef union {
  struct Atm128_UCSRB_t {
    uint8_t txb8  : 1;  //!< UART Transmit Data Bit 8
    uint8_t rxb8  : 1;  //!< UART Receive Data Bit 8
    uint8_t ucsz2 : 1;  //!< UART Character Size (Bit 2)
    uint8_t txen  : 1;  //!< UART Transmitter Enable
    uint8_t rxen  : 1;  //!< UART Receiver Enable
    uint8_t udrie : 1;  //!< USART Data Register Enable
    uint8_t txcie : 1;  //!< UART TX Complete Interrupt Enable
    uint8_t rxcie : 1;  //!< UART RX Complete Interrupt Enable 
  } bits;
  uint8_t flat;
} Atm128UartControl_t;

typedef Atm128UartControl_t Atm128_UCSR0B_t;  //!< UART 0 Control Register
typedef Atm128UartControl_t Atm128_UCSR1B_t;  //!< UART 1 Control Register

enum {
  ATM128_UART_DATA_SIZE_5_BITS = 0,
  ATM128_UART_DATA_SIZE_6_BITS = 1,
  ATM128_UART_DATA_SIZE_7_BITS = 2,
  ATM128_UART_DATA_SIZE_8_BITS = 3,
};

/* UART Control Register */
typedef union {
  uint8_t flat;
  struct Atm128_UCSRC_t {
    uint8_t ucpol : 1;  //!< UART Clock Polarity
    uint8_t ucsz  : 2;  //!< UART Character Size (Bits 0 and 1)
    uint8_t usbs  : 1;  //!< UART Stop Bit Select
    uint8_t upm   : 2;  //!< UART Parity Mode
    uint8_t umsel : 1;  //!< USART Mode Select
    uint8_t rsvd  : 1;  //!< Reserved
  } bits;
} Atm128UartMode_t;

typedef Atm128UartMode_t Atm128_UCSR0C_t;  //!< UART 0 Mode Register
typedef Atm128UartMode_t Atm128_UCSR1C_t;  //!< UART 1 Mode Register

/*
 * ATmega1128 UART baud register settings:
 *      ATM128_<baudRate>_BAUD_<cpuSpeed>
 */
enum {
  ATM128_19200_BAUD_4MHZ  = 12,
  ATM128_38400_BAUD_4MHZ  = 6,
  ATM128_57600_BAUD_4MHZ  = 3,

  ATM128_19200_BAUD_4MHZ_2X  = 25,
  ATM128_38400_BAUD_4MHZ_2X  = 12,
  ATM128_57600_BAUD_4MHZ_2X  = 8,

  ATM128_19200_BAUD_7MHZ  = 23,
  ATM128_38400_BAUD_7MHZ  = 11,
  ATM128_57600_BAUD_7MHZ  = 7,

  ATM128_19200_BAUD_7MHZ_2X  = 47,
  ATM128_38400_BAUD_7MHZ_2X  = 23,
  ATM128_57600_BAUD_7MHZ_2X  = 15,

  ATM128_19200_BAUD_8MHZ  = 25,
  ATM128_38400_BAUD_8MHZ  = 12,
  ATM128_57600_BAUD_8MHZ  = 8,

  ATM128_19200_BAUD_8MHZ_2X  = 51,
  ATM128_38400_BAUD_8MHZ_2X  = 34,
  ATM128_57600_BAUD_8MHZ_2X  = 11,
};

typedef uint8_t Atm128_UBRR0L_t;  //!< UART 0 Baud Register (Low)
typedef uint8_t Atm128_UBRR0H_t;  //!< UART 0 Baud Register (High)

typedef uint8_t Atm128_UBRR1L_t;  //!< UART 1 Baud Register (Low)
typedef uint8_t Atm128_UBRR1H_t;  //!< UART 1 Baud Register (High)

typedef uint8_t uart_parity_t;
typedef uint8_t uart_speed_t;
typedef uint8_t uart_duplex_t;

enum {
  TOS_UART_PARITY_NONE = 0,
  TOS_UART_PARITY_EVEN = 1,
  TOS_UART_PARITY_ODD  = 2,
};

enum {
  TOS_UART_19200  = 0,
  TOS_UART_38400  = 1,
  TOS_UART_57600  = 2,
};

enum {
  TOS_UART_OFF    = 0,
  TOS_UART_RONLY  = 1,
  TOS_UART_TONLY  = 2,
  TOS_UART_DUPLEX = 3,
};

#endif //_H_Atm128UART_h

