/*
 * Copyright (c) 2009 Communication Group and Eislab at
 * Lulea University of Technology
 *
 * Contact: Laurynas Riliskis, LTU
 * Mail: laurynas.riliskis@ltu.se
 * All rights reserved.
 *
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
 * - Neither the name of Communication Group at Lulea University of Technology
 *   nor the names of its contributors may be used to endorse or promote
 *    products derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL STANFORD
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/*
 * Copyright (c) 2006 Arch Rock Corporation
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
 * - Neither the name of the Arch Rock Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * ARCH ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */
/**
 * @author Alec Woo <awoo@archrock.com>
 * @author Jonathan Hui <jhui@archrock.com>
 */

/*
 * Copyright (c) 2004-2005 Crossbow Technology, Inc.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of Crossbow Technology nor the names of
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
 */
/** 
 * @author Martin Turon <mturon@xbow.com>
 * @author David Gay
 */


/**
 * Generic HPL module for a Uart(0-2) port on the M16c/60 MCU.
 * When used in I2C mode the rx/tx interrupts are generated on
 * acks and nacks.
 *
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 */
 
#include "M16c60Uart.h"
 
generic module HplM16c60UartP(uint8_t uartNr,
                              uint16_t tx_addr,
                              uint16_t rx_addr,
                              uint16_t brg_addr,
                              uint16_t mode_addr,
                              uint16_t smode_addr,
                              uint16_t smode2_addr,
                              uint16_t smode3_addr,
                              uint16_t smode4_addr,
                              uint16_t ctrl0_addr,
                              uint16_t ctrl1_addr,
                              uint16_t txInterrupt_addr,
                              uint16_t rxInterrupt_addr,
                              uint16_t bcnic_addr)
{
  provides interface HplM16c60Uart as HplUart;
  
  uses interface GeneralIO as TxIO;
  uses interface GeneralIO as RxIO;
  uses interface HplM16c60UartInterrupt as Irq;
  uses interface StopModeControl;

}
implementation
{
#define txBuf (*TCAST(volatile uint16_t* ONE, tx_addr))
#define rxBuf (*TCAST(volatile uint8_t* ONE, rx_addr))
#define txInterrupt (*TCAST(volatile uint8_t* ONE, txInterrupt_addr))
#define rxInterrupt (*TCAST(volatile uint8_t* ONE, rxInterrupt_addr))
#define bcnic (*TCAST(volatile uint8_t* ONE, bcnic_addr))
#define brg (*TCAST(volatile uint8_t* ONE, brg_addr))
#define mode (*TCAST(volatile uint8_t* ONE, mode_addr))
#define smode (*TCAST(volatile uint8_t* ONE, smode_addr))
#define smode2 (*TCAST(volatile uint8_t* ONE, smode2_addr))
#define smode3 (*TCAST(volatile uint8_t* ONE, smode3_addr))
#define smode4 (*TCAST(volatile uint8_t* ONE, smode4_addr))
#define ctrl0 (*TCAST(volatile uint8_t* ONE, ctrl0_addr))
#define ctrl1 (*TCAST(volatile uint8_t* ONE, ctrl1_addr))

  async command void HplUart.setMode(m16c60_uart_mode set_mode)
  {
    mode &= ~(0x7);
    smode = 0;
    smode2 = 0;
    smode3 = 0;
    smode4 = 0;
    switch(set_mode)
    {
      case M16C60_UART_MODE_UART_8BITS:
        SET_BIT(mode, 0);
        SET_BIT(mode, 2);
        break;
      case M16C60_UART_MODE_SPI0:
        SET_BIT(smode3, 1);
        ctrl0 = 0x90;
        SET_BIT(mode, 0);
        break;
      case M16C60_UART_MODE_SPI1:
        ctrl0 = 0xD0;
        SET_BIT(mode, 0); 
        break;
      case M16C60_UART_MODE_SPI2:
        SET_BIT(smode3, 1);
        ctrl0 = 0xD0;
        SET_BIT(mode, 0); 
        break;
      case M16C60_UART_MODE_SPI3:
        ctrl0 = 0x90;
        SET_BIT(mode, 0); 
        break;
      case M16C60_UART_MODE_I2C:
        call TxIO.makeInput();
        call RxIO.makeInput();
        bcnic = 0;
        txInterrupt = 0;
        rxInterrupt = 0;
        call HplUart.disableCTSRTS();
        SET_BIT(ctrl0, 5);
        CLR_BIT(ctrl0, 6);
        SET_BIT(ctrl0, 7);
        SET_BIT(smode, 0);
        SET_BIT(smode2, 1);
        SET_BIT(smode4, 4);
        SET_BIT(smode4, 5);
        SET_BIT(mode, 1);
        break;
      case M16C60_UART_MODE_OFF:
        call StopModeControl.allowStopMode(true);
        return;
        break;
    }
    call StopModeControl.allowStopMode(false);
  }

  async command void HplUart.setSpeed(uint8_t speed)
  {
    brg = speed;
  }
  
  async command uint8_t HplUart.getSpeed()
  {
    return brg;
  }

  async command void HplUart.setCountSource(m16c60_uart_count_source source)
  {
    ctrl0 &= (~0x3);
    ctrl0 |= source;
  }
  
  async command void HplUart.setParity(uart_parity_t parity)
  {
    switch (parity)
    {
      case TOS_UART_PARITY_NONE:
        CLR_BIT(mode, 6);
        break;
      case TOS_UART_PARITY_EVEN:
        SET_BIT(mode, 6);
        SET_BIT(mode, 5);
        break;
      case TOS_UART_PARITY_ODD:
        SET_BIT(mode, 6);
        CLR_BIT(mode, 5);
        break;
      default:
        break;
    }
  }
  
  async command uart_parity_t HplUart.getParity()
  {
    if (READ_BIT(mode, 6) && READ_BIT(mode, 5))
    {
      return TOS_UART_PARITY_EVEN;
    }
    else if (READ_BIT(mode, 6))
    {
      return TOS_UART_PARITY_ODD;
    }
    else
    {
      return TOS_UART_PARITY_NONE;
    }
  }
  
  async command void HplUart.setStopBits(uart_stop_bits_t stop_bits)
  {
    switch (stop_bits)
    {
      case TOS_UART_STOP_BITS_1:
        CLR_BIT(mode, 4);
        break;
      case TOS_UART_STOP_BITS_2:
        SET_BIT(mode, 4);
        break;
      default:
        break;
    }
  }
  
  async command uart_stop_bits_t HplUart.getStopBits()
  {
    if (READ_BIT(mode, 4))
    {
      return TOS_UART_STOP_BITS_2;
    }
    else
    {
      return TOS_UART_STOP_BITS_1;
    }
  }

  async command void HplUart.enableCTSRTS()
  {
    CLR_BIT(ctrl0, 4);
  }

  async command void HplUart.disableCTSRTS()
  {
    SET_BIT(ctrl0, 4);
  }

  async command void HplUart.enableTx()
  {
    call TxIO.makeOutput();
    SET_BIT(ctrl1, 0);
  }

  async command void HplUart.disableTx()
  {
    while (!READ_BIT(ctrl0, 3)); // If transmitting, wait for it to finish
    call TxIO.makeInput();
    CLR_BIT(ctrl1, 0);
  }
  
  async command bool HplUart.isTxEnabled()
  {
    return READ_BIT(ctrl1, 0);
  }

  async command void HplUart.enableRx()
  {
    call RxIO.makeInput();
    SET_BIT(ctrl1, 2);
  }

  async command void HplUart.disableRx()
  {
    CLR_BIT(ctrl1, 2);
  }

  async command bool HplUart.isRxEnabled()
  {
    return READ_BIT(ctrl1, 2);
  }
  
  async command void HplUart.enableTxInterrupt()
  {
    atomic
    {
      clear_interrupt(txInterrupt_addr);
      SET_BIT(ctrl1, 1);
      CLR_BIT(UCON.BYTE, uartNr);
      SET_BIT(txInterrupt, 0);
    }
  }
  
  async command void HplUart.disableTxInterrupt()
  {
    CLR_BIT(txInterrupt, 0);
  }
  
  async command void HplUart.enableRxInterrupt()
  { 
    atomic
    {
      clear_interrupt(rxInterrupt_addr);
      SET_BIT(rxInterrupt, 0);
    }
  }

  async command void HplUart.disableRxInterrupt()
  {
    CLR_BIT(rxInterrupt, 0);
  }
  
  async command bool HplUart.isTxEmpty()
  {
    return READ_BIT(ctrl1, 1);
  }

  async command bool HplUart.isRxEmpty()
  {
    return !READ_BIT(ctrl1, 3);
  }
  
  async command uint8_t HplUart.rx()
  {
    return rxBuf;
  }

  async command void HplUart.tx(uint8_t data)
  {
    txBuf = data;
  }
  
  async event void Irq.rx() 
  {
    signal HplUart.rxDone();
  }
  
  async event void Irq.tx()
  {
    signal HplUart.txDone();
  }
  
  // TODO(henrik) Add a event for the BCNIC interrupt. This makes it
  //              possible to generate start and stops async.
  async command void HplUart.i2cStart()
  {
    smode4 = 0x09; // Generate start.
    while (!READ_BIT(bcnic, 3));
    clear_interrupt(bcnic_addr);
    smode3 = 0x02; // Drive SCL low between byte transfers.
    smode4 = 0x00; // Enable output on SDA pin.
  }

  async command void HplUart.i2cStop()
  {
    smode4 = 0x0C; // Generate stop.
    while (!READ_BIT(bcnic, 3));
    clear_interrupt(bcnic_addr);
    smode3 = 0x00; // Let SCL float while bus is idle.
    smode4 = 0x30; // Let SDA float while bus is idle.
  }
 
  void clearInterrupts()
  {
    clear_interrupt(txInterrupt_addr);
    clear_interrupt(rxInterrupt_addr);
  }

  async command void HplUart.i2cTx(uint8_t byte)
  {
    clearInterrupts();
    U2TB.WORD = 0x0100 | (uint16_t)byte; // Bit 8 must be high for the slave
                           // to be able to ack.
  }

  async command bool HplUart.i2cWaitTx()
  {
    while(!READ_BIT(rxInterrupt, 3) && !READ_BIT(txInterrupt, 3));

    if (READ_BIT(rxInterrupt, 3))
    {
      clearInterrupts();
      return true;
    }
    else
    {
      clearInterrupts();
      return false;
    }
  }

  async command void HplUart.i2cStartRx(bool nack)
  {
    if (nack)
    {
      txBuf = 0x01FF;
    }
    else
    {
      txBuf = 0x00FF;
    }
  }

  async command uint8_t HplUart.i2cWaitRx()
  {
    while(!READ_BIT(rxInterrupt, 3) && !READ_BIT(txInterrupt, 3));
    clearInterrupts();
    return rxBuf;
  }

  default async event void HplUart.txDone() {} 
  default async event void HplUart.rxDone() {}
}
