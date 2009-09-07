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
/** 
 * @author Martin Turon <mturon@xbow.com>
 * @author David Gay
 */


/**
 * Generic HPL module for a Uart port on the M16c/62p MCU.
 *
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 */
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
  provides interface Init as UartInit;
  provides interface StdControl as UartTxControl;
  provides interface StdControl as UartRxControl;
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

  command error_t UartInit.init()
  {
    // Divide the mainclock get baudrate.
    brg = (uint8_t)(((MAIN_CRYSTAL_SPEED * 1000000.0 / (16.0 * 57600.0))+ 0.5) - 1.0);
    mode = BIT0 | BIT2;  // Set 8 bit transfer length, 1 stop bit, no parity.
    ctrl0 = BIT4;        // set f1, no cts/rts.
 
    return SUCCESS;
  }

  command error_t UartTxControl.start()
  {
    call TxIO.makeOutput();
    SET_BIT(ctrl1, 0);
    call StopModeControl.allowStopMode(false);
    return SUCCESS;
  }

  command error_t UartTxControl.stop()
  {
    call TxIO.makeInput();
    CLR_BIT(ctrl1, 0);
    call StopModeControl.allowStopMode(true);
    return SUCCESS;
  }

  command error_t UartRxControl.start()
  {
    SET_BIT(ctrl1, 2);
    return SUCCESS;
  }

  command error_t UartRxControl.stop()
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
