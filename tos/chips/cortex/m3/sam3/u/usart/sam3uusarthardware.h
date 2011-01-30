/*
 * Copyright (c) 2009 Johns Hopkins University.
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
 * 12 bit ADC register definitions.
 *
 * @author JeongGil Ko
 */

#ifndef _SAM3UUSARTHARDWARE_H
#define _SAM3UUSARTHARDWARE_H

typedef union
{
  uint32_t flat;
  struct
  {
    uint8_t reserved0     :  2; 
    uint8_t rstrx         :  1; 
    uint8_t rsttx         :  1;
    uint8_t rxen          :  1;
    uint8_t rxdis         :  1;
    uint8_t txen          :  1;
    uint8_t txdis         :  1;
    uint8_t rststa        :  1; 
    uint8_t sttbrk        :  1;
    uint8_t stpbrk        :  1;
    uint8_t sttto         :  1;
    uint8_t senda         :  1;
    uint8_t rstit         :  1;
    uint8_t rstnack       :  1; 
    uint8_t retto         :  1;
    uint8_t reserved1     :  2; 
    uint8_t rtsen_fcs     :  1;
    uint8_t rtsdis_rcs    :  1;
    uint8_t reserved2     :  4;
    uint8_t reserved3     :  8;
  } __attribute__((__packed__)) bits;
} usart_cr_t;
/*
typedef union
{
  uint32_t flat;
  struct
  {
    uint8_t usart_mode    :  4; 
    uint8_t usclks        :  2;
    uint8_t chrl          :  2; 
    uint8_t sync_cpha     :  1;
    uint8_t par           :  3; 
    uint8_t nb_stop       :  2;
    uint8_t chmode        :  2;
    uint8_t msbf_cpol     :  1;
    uint8_t mode9         :  1;
    uint8_t clko          :  1;
    uint8_t over          :  1;
    uint8_t inack         :  1;
    uint8_t dsnack        :  1;
    uint8_t var_sync      :  1;
    uint8_t invdata       :  1;
    uint8_t max_iteration :  3;
    uint8_t reserved0     :  1;
    uint8_t filter        :  1;
    uint8_t man           :  1;
    uint8_t modsync       :  1;
    uint8_t onebit        :  1;
  } __attribute__((__packed__)) bits;
} usart_mr_t;
*/
typedef union
{
  uint32_t flat;
  struct
  {
    uint8_t usart_mode    :  4; 
    uint8_t usclks        :  2;
    uint8_t chrl          :  2; 
    uint8_t sync_cpha     :  1;
    uint8_t par           :  3; 
    uint8_t nb_stop       :  2;
    uint8_t chmode        :  2;
    uint8_t msbf_cpol     :  1;
    uint8_t mode9         :  1;
    uint8_t clko          :  1;
    uint8_t over          :  1;
    uint8_t inack         :  1;
    uint8_t dsnack        :  1;
    uint8_t var_sync      :  1;
    uint8_t invdata       :  1;
    uint8_t max_iteration :  3;
    uint8_t reserved0     :  1;
    uint8_t filter        :  1;
    uint8_t man           :  1;
    uint8_t modsync       :  1;
    uint8_t onebit        :  1;
  } __attribute__((__packed__)) bits;
} usart_mr_t;

typedef union
{
  uint32_t flat;
  struct
  {
    uint8_t rxrdy         :  1;
    uint8_t txrdy         :  1;
    uint8_t rxbrk         :  1;
    uint8_t endrx         :  1;
    uint8_t endtx         :  1;
    uint8_t ovre          :  1;
    uint8_t frame         :  1;
    uint8_t pare          :  1;
    uint8_t timeout       :  1;
    uint8_t txempty       :  1;
    uint8_t iter_unre     :  1;
    uint8_t txbufe        :  1;
    uint8_t rxbuff        :  1;
    uint8_t nack          :  1;
    uint8_t reserved0     :  2;
    uint8_t reserved1     :  3;
    uint8_t ctsic         :  1;
    uint8_t reserved2     :  4;
    uint8_t mane          :  1;
    uint8_t reserved3     :  7;
  } __attribute__((__packed__)) bits;
} usart_ier_t;

typedef union
{
  uint32_t flat;
  struct
  {
    uint8_t rxrdy         :  1;
    uint8_t txrdy         :  1;
    uint8_t rxbrk         :  1;
    uint8_t endrx         :  1;
    uint8_t endtx         :  1;
    uint8_t ovre          :  1;
    uint8_t frame         :  1;
    uint8_t pare          :  1;
    uint8_t timeout       :  1;
    uint8_t txempty       :  1;
    uint8_t iter_unre     :  1;
    uint8_t txbufe        :  1;
    uint8_t rxbuff        :  1;
    uint8_t nack          :  1;
    uint8_t reserved0     :  2;
    uint8_t reserved1     :  3;
    uint8_t ctsic         :  1;
    uint8_t reserved2     :  4;
    uint8_t mane          :  1;
    uint8_t reserved3     :  7;
  } __attribute__((__packed__)) bits;
} usart_idr_t;

typedef union
{
  uint32_t flat;
  struct
  {
    uint8_t rxrdy         :  1;
    uint8_t txrdy         :  1;
    uint8_t rxbrk         :  1;
    uint8_t endrx         :  1;
    uint8_t endtx         :  1;
    uint8_t ovre          :  1;
    uint8_t frame         :  1;
    uint8_t pare          :  1;
    uint8_t timeout       :  1;
    uint8_t txempty       :  1;
    uint8_t iter_unre     :  1;
    uint8_t txbufe        :  1;
    uint8_t rxbuff        :  1;
    uint8_t nack          :  1;
    uint8_t reserved0     :  2;
    uint8_t reserved1     :  3;
    uint8_t ctsic         :  1;
    uint8_t reserved2     :  4;
    uint8_t mane          :  1;
    uint8_t reserved3     :  7;
  } __attribute__((__packed__)) bits;
} usart_imr_t;

typedef union
{
  uint32_t flat;
  struct
  {
    uint8_t rxrdy         :  1;
    uint8_t txrdy         :  1;
    uint8_t rxbrk         :  1;
    uint8_t endrx         :  1;
    uint8_t endtx         :  1;
    uint8_t ovre          :  1;
    uint8_t frame         :  1;
    uint8_t pare          :  1;
    uint8_t timeout       :  1;
    uint8_t txempty       :  1;
    uint8_t iter_unre     :  1;
    uint8_t txbufe        :  1;
    uint8_t rxbuff        :  1;
    uint8_t nack          :  1;
    uint8_t reserved0     :  2;
    uint8_t reserved1     :  3;
    uint8_t ctsic         :  1;
    uint8_t reserved2     :  4;
    uint8_t manerr        :  1;
    uint8_t reserved3     :  7;
  } __attribute__((__packed__)) bits;
} usart_csr_t;

typedef union
{
  uint32_t flat;
  struct
  {
    uint16_t rxchr        :  9;
    uint16_t reserved0    :  6;
    uint16_t rxsynh       :  1;
    uint16_t reserved1    : 16;
  } __attribute__((__packed__)) bits;
} usart_rhr_t;


typedef union
{
  uint32_t flat;
  struct
  {
    uint16_t txchr        :  9;
    uint16_t reserved0    :  6;
    uint16_t txsynh       :  1;
    uint16_t reserved1    : 16;
  } __attribute__((__packed__)) bits;
} usart_thr_t;

typedef union
{
  uint32_t flat;
  struct
  {
    uint16_t cd           : 16;
    uint8_t fp            :  1;
    uint8_t reserved0     :  7;
    uint8_t reserved1     :  8;
  } __attribute__((__packed__)) bits;
} usart_brgr_t;

typedef union
{
  uint32_t flat;
  struct
  {
    uint16_t to           : 16;
    uint16_t reserved0    : 16;
  } __attribute__((__packed__)) bits;
} usart_rtor_t;

typedef union
{
  uint32_t flat;
  struct
  {
    uint8_t tg            :  8;
    uint8_t reserved0     :  8;
    uint16_t reserved1    : 16;
  } __attribute__((__packed__)) bits;
} usart_ttgr_t;

typedef union
{
  uint32_t flat;
  struct
  {
    uint16_t fi_di_ratio  : 11;
    uint16_t reserved0    :  5;
    uint16_t reserved1    : 16;
  } __attribute__((__packed__)) bits;
} usart_fidi_t;

typedef union
{
  uint32_t flat;
  struct
  {
    uint8_t nb_errors     :  8;
    uint8_t reserved0     :  8;
    uint16_t reserved1    : 16;
  } __attribute__((__packed__)) bits;
} usart_ner_t;

typedef union
{
  uint32_t flat;
  struct
  {
    uint8_t irda_filter   :  8;
    uint8_t reserved0     :  8;
    uint16_t reserved1    : 16;
  } __attribute__((__packed__)) bits;
} usart_if_t;

typedef union
{
  uint32_t flat;
  struct
  {
    uint8_t tx_pl         :  4;
    uint8_t reserved0     :  4;
    uint8_t tx_pp         :  2;
    uint8_t reserved1     :  2;
    uint8_t tx_mpol       :  1;
    uint8_t reserved2     :  3;
    uint8_t rx_pl         :  4;
    uint8_t reserved3     :  4;
    uint8_t rx_pp         :  2;
    uint8_t reserved4     :  2;
    uint8_t rx_mpol       :  1;
    uint8_t allwaysone    :  1;
    uint8_t drift         :  1;
    uint8_t reserved5     :  1;
  } __attribute__((__packed__)) bits;
} usart_man_t;

typedef union
{
  uint32_t flat;
  struct
  {
    uint32_t wpen         :  1;
    uint32_t reserved0    :  7;
    uint32_t wpkey        : 24;
  } __attribute__((__packed__)) bits;
} usart_wpmr_t;

typedef union
{
  uint32_t flat;
  struct
  {
    uint8_t wpvs          :  1;
    uint8_t reserved0     :  7;
    uint16_t wpvsrc       : 16;
    uint8_t reserved1     :  8;
  } __attribute__((__packed__)) bits;
} usart_wpsr_t;

typedef union
{
  uint32_t flat;
  struct
  {
    uint16_t version      : 12;
    uint16_t reserved0    :  4;
    uint16_t mfn          :  3;
    uint16_t reserved1    : 13;
  } __attribute__((__packed__)) bits;
} usart_version_t;

typedef struct usart {
  volatile usart_cr_t cr;
  volatile usart_mr_t mr;
  volatile usart_ier_t ier;
  volatile usart_idr_t idr;
  volatile usart_imr_t imr;
  volatile usart_csr_t csr;
  volatile usart_rhr_t rhr;
  volatile usart_thr_t thr;
  volatile usart_brgr_t brgr;
  volatile usart_rtor_t rtor;
  volatile usart_ttgr_t ttgr;
  uint32_t reserved0[5];
  volatile usart_fidi_t fidi;
  volatile usart_ner_t ner;
  uint32_t reserved1;
  volatile usart_if_t us_if;
  volatile usart_man_t man;
  volatile usart_wpmr_t wpmr;
  volatile usart_wpsr_t wpsr;
  uint32_t reserved2[40];
  volatile usart_version_t version;
} usart_t;

volatile usart_t* USART0 = (volatile usart_t *) 0x40090000;
volatile usart_t* USART1 = (volatile usart_t *) 0x40094000;
volatile usart_t* USART2 = (volatile usart_t *) 0x40098000;
volatile usart_t* USART3 = (volatile usart_t *) 0x4009C000;


#define AT91C_US_USMODE       (0xF <<  0) // (USART) Usart mode
#define         AT91C_US_USMODE_NORMAL               (0x0) // (USART) Normal
#define         AT91C_US_USMODE_RS485                (0x1) // (USART) RS485
#define         AT91C_US_USMODE_HWHSH                (0x2) // (USART) Hardware Handshaking
#define         AT91C_US_USMODE_MODEM                (0x3) // (USART) Modem
#define         AT91C_US_USMODE_ISO7816_0            (0x4) // (USART) ISO7816 protocol: T = 0
#define         AT91C_US_USMODE_ISO7816_1            (0x6) // (USART) ISO7816 protocol: T = 1
#define         AT91C_US_USMODE_IRDA                 (0x8) // (USART) IrDA
#define         AT91C_US_USMODE_SWHSH                (0xC) // (USART) Software Handshaking
#define AT91C_US_CLKS         (0x3 <<  4) // (USART) Clock Selection (Baud Rate generator Input Clock
#define         AT91C_US_CLKS_CLOCK                (0x0 <<  4) // (USART) Clock
#define         AT91C_US_CLKS_FDIV1                (0x1 <<  4) // (USART) fdiv1
#define         AT91C_US_CLKS_SLOW                 (0x2 <<  4) // (USART) slow_clock (ARM)
#define         AT91C_US_CLKS_EXT                  (0x3 <<  4) // (USART) External (SCK)
#define AT91C_US_CHRL         (0x3 <<  6) // (USART) Clock Selection (Baud Rate generator Input Clock
#define         AT91C_US_CHRL_5_BITS               (0x0 <<  6) // (USART) Character Length: 5 bits
#define         AT91C_US_CHRL_6_BITS               (0x1 <<  6) // (USART) Character Length: 6 bits
#define         AT91C_US_CHRL_7_BITS               (0x2 <<  6) // (USART) Character Length: 7 bits
#define         AT91C_US_CHRL_8_BITS               (0x3 <<  6) // (USART) Character Length: 8 bits
#define AT91C_US_SYNC         (0x1 <<  8) // (USART) Synchronous Mode Select
#define AT91C_US_ASYNC         (0x0 <<  8) // (USART) Asynchronous Mode Select
#define AT91C_US_PAR          (0x7 <<  9) // (USART) Parity type
#define         AT91C_US_PAR_EVEN                 (0x0 <<  9) // (USART) Even Parity
#define         AT91C_US_PAR_ODD                  (0x1 <<  9) // (USART) Odd Parity
#define         AT91C_US_PAR_SPACE                (0x2 <<  9) // (USART) Parity forced to 0 (Space)
#define         AT91C_US_PAR_MARK                 (0x3 <<  9) // (USART) Parity forced to 1 (Mark)
#define         AT91C_US_PAR_NONE                 (0x4 <<  9) // (USART) No Parity
#define         AT91C_US_PAR_MULTI_DROP           (0x6 <<  9) // (USART) Multi-drop mode
#define AT91C_US_NBSTOP       (0x3 << 12) // (USART) Number of Stop bits
#define         AT91C_US_NBSTOP_1_BIT                (0x0 << 12) // (USART) 1 stop bit
#define         AT91C_US_NBSTOP_15_BIT               (0x1 << 12) // (USART) Asynchronous (SYNC=0) 2 stop bits Synchronous (SYNC=1) 2 stop bits
#define         AT91C_US_NBSTOP_2_BIT                (0x2 << 12) // (USART) 2 stop bits
#define AT91C_US_CHMODE       (0x3 << 14) // (USART) Channel Mode
#define         AT91C_US_CHMODE_NORMAL               (0x0 << 14) // (USART) Normal Mode: The USART channel operates as an RX/TX USART.
#define         AT91C_US_CHMODE_AUTO                 (0x1 << 14) // (USART) Automatic Echo: Receiver Data Input is connected to the TXD pin.
#define         AT91C_US_CHMODE_LOCAL                (0x2 << 14) // (USART) Local Loopback: Transmitter Output Signal is connected to Receiver Input Signal.
#define         AT91C_US_CHMODE_REMOTE               (0x3 << 14) // (USART) Remote Loopback: RXD pin is internally connected to TXD pin.
#define AT91C_US_MSBF         (0x1 << 16) // (USART) Bit Order
#define AT91C_US_MODE9        (0x1 << 17) // (USART) 9-bit Character length
#define AT91C_US_CKLO         (0x1 << 18) // (USART) Clock Output Select
#define AT91C_US_OVER         (0x1 << 19) // (USART) Over Sampling Mode
#define AT91C_US_INACK        (0x1 << 20) // (USART) Inhibit Non Acknowledge
#define AT91C_US_DSNACK       (0x1 << 21) // (USART) Disable Successive NACK
#define AT91C_US_VAR_SYNC     (0x1 << 22) // (USART) Variable synchronization of command/data sync Start Frame Delimiter
#define AT91C_US_MAX_ITER     (0x1 << 24) // (USART) Number of Repetitions
#define AT91C_US_FILTER       (0x1 << 28) // (USART) Receive Line Filter
#define AT91C_US_MANMODE      (0x1 << 29) // (USART) Manchester Encoder/Decoder Enable
#define AT91C_US_MODSYNC      (0x1 << 30) // (USART) Manchester Synchronization mode
#define AT91C_US_ONEBIT       (0x1 << 31) // (USART) Start Frame Delimiter selector

#endif // _SAM3UUSARTHARDWARE_H
