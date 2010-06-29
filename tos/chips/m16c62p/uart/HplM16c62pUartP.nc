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
 * Generic HPL module for a Uart port on the M16c/62p MCU.
 *
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 */
 
#include "M16c62pUart.h"
 
generic module HplM16c62pUartP(uint8_t uartNr,
                               uint16_t tx_addr,
                               uint16_t rx_addr,
                               uint16_t brg_addr,
                               uint16_t mode_addr,
                               uint16_t ctrl0_addr,
                               uint16_t ctrl1_addr,
                               uint16_t txInterrupt_addr,
                               uint16_t rxInterrupt_addr)
{
  provides interface AsyncStdControl as UartTxControl;
  provides interface AsyncStdControl as UartRxControl;
  provides interface HplM16c62pUart as HplUart;
  
  uses interface GeneralIO as TxIO;
  uses interface GeneralIO as RxIO;
  uses interface HplM16c62pUartInterrupt as Irq;
  uses interface StopModeControl;

}
implementation
{
#define txBuf (*TCAST(volatile uint8_t* ONE, tx_addr))
#define rxBuf (*TCAST(volatile uint8_t* ONE, rx_addr))
#define txInterrupt (*TCAST(volatile uint8_t* ONE, txInterrupt_addr))
#define rxInterrupt (*TCAST(volatile uint8_t* ONE, rxInterrupt_addr))
#define brg (*TCAST(volatile uint8_t* ONE, brg_addr))
#define mode (*TCAST(volatile uint8_t* ONE, mode_addr))
#define ctrl0 (*TCAST(volatile uint8_t* ONE, ctrl0_addr))
#define ctrl1 (*TCAST(volatile uint8_t* ONE, ctrl1_addr))

  enum {
    ON,
    OFF
  };

  uint8_t state = OFF;
  uart_speed_t current_speed = TOS_UART_57600;
  
  async command void HplUart.on()
  {
    // Set 8 bit transfer
    SET_BIT(mode, 0);
    SET_BIT(mode, 2);
    
    //no cts/rts.
    SET_BIT(ctrl0, 4);
    atomic switch (current_speed)
    {
      case TOS_UART_1200:
        SET_BIT(ctrl0, 0);
        CLR_BIT(ctrl0, 1);
        break;
      case TOS_UART_9600:
      case TOS_UART_57600:
        CLR_BIT(ctrl0, 0);
        CLR_BIT(ctrl0, 1);
        break;
      default:
        break;
    }
    call StopModeControl.allowStopMode(false);
    atomic state = ON;
  }
  
  async command void HplUart.off()
  {
    CLR_BIT(mode, 0);
    CLR_BIT(mode, 2);
    call StopModeControl.allowStopMode(true);
    atomic state = OFF;
  }


  async command error_t HplUart.setSpeed(uart_speed_t speed)
  {
    atomic if (state != OFF)
    {
      return FAIL;
    }
    
    switch (speed)
    {
      // TODO(henrik) These values are based on a mcu that runs on MAIN_CRYSTAL_SPEED and doesn't
      //              consider if the PLL is on which they should.
      case TOS_UART_1200:
        brg = (uint8_t)(((MAIN_CRYSTAL_SPEED * 1000000.0 / (128.0 * 1200.0))+ 0.5) - 1.0);
        break;
      case TOS_UART_9600:
      	brg = (uint8_t)(((MAIN_CRYSTAL_SPEED * 1000000.0 / (16.0 * 9600.0))+ 0.5) - 1.0);
      	break;
      case TOS_UART_57600:
        brg = (uint8_t)(((MAIN_CRYSTAL_SPEED * 1000000.0 / (16.0 * 57600.0))+ 0.5) - 1.0);
        break;
      default:
        break;
    }
    atomic current_speed = speed;
    return SUCCESS;
  }
  
  async command uart_speed_t HplUart.getSpeed()
  {
    atomic return current_speed;
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
    

  async command error_t UartTxControl.start()
  {
    call TxIO.makeOutput();
    SET_BIT(ctrl1, 0);
    return SUCCESS;
  }

  async command error_t UartTxControl.stop()
  {
    call TxIO.makeInput();
    CLR_BIT(ctrl1, 0);
    return SUCCESS;
  }

  async command error_t UartRxControl.start()
  {
    call RxIO.makeInput();
    SET_BIT(ctrl1, 2);
    return SUCCESS;
  }

  async command error_t UartRxControl.stop()
  {
    CLR_BIT(ctrl1, 2);
    return SUCCESS;
  }
  
  async command error_t HplUart.enableTxInterrupt()
  {
    atomic
    {
      clear_interrupt(txInterrupt_addr);
      SET_BIT(ctrl1, 1);
      CLR_BIT(UCON.BYTE, uartNr);
      SET_BIT(txInterrupt, 0);
    }
    return SUCCESS;
  }
  
  async command error_t HplUart.disableTxInterrupt()
  {
    CLR_BIT(txInterrupt, 0);
    return SUCCESS;
  }
  
  async command error_t HplUart.enableRxInterrupt()
  { 
    atomic
    {
      clear_interrupt(rxInterrupt_addr);
      SET_BIT(rxInterrupt, 0);
    }
    return SUCCESS;
  }

  async command error_t HplUart.disableRxInterrupt()
  {
    CLR_BIT(rxInterrupt, 0);
    return SUCCESS;
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
    if (!call HplUart.isRxEmpty()) {
      signal HplUart.rxDone(call HplUart.rx());
    }
  }
  
  async event void Irq.tx()
  {
    signal HplUart.txDone();
  }
  
  default async event void HplUart.txDone() {} 
  default async event void HplUart.rxDone(uint8_t data) {}
}
