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
 *
 * @author Martin Turon <mturon@xbow.com>
 * @author David Gay
 */

/**
 * The M16c/62p uart ports.
 *
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 */
configuration HplM16c62pUartC
{
  provides
  {
    interface AsyncStdControl as Uart0TxControl;
    interface AsyncStdControl as Uart0RxControl;
    interface HplM16c62pUart as HplUart0;
    
    interface AsyncStdControl as Uart1TxControl;
    interface AsyncStdControl as Uart1RxControl;
    interface HplM16c62pUart as HplUart1;

    interface AsyncStdControl as Uart2TxControl;
    interface AsyncStdControl as Uart2RxControl;
    interface HplM16c62pUart as HplUart2;
  }
}
implementation
{
  components
      HplM16c62pGeneralIOC as IOs,
      HplM16c62pUartInterruptP as Irqs,
      new HplM16c62pUartP(0,
                          (uint16_t)&U0TB.BYTE.U0TBL,
                          (uint16_t)&U0RB.BYTE.U0RBL,
                          (uint16_t)&U0BRG,
                          (uint16_t)&U0MR.BYTE,
                          (uint16_t)&U0C0.BYTE,
                          (uint16_t)&U0C1.BYTE,
                          (uint16_t)&S0TIC.BYTE,
                          (uint16_t)&S0RIC.BYTE) as HplUart0P,
      new HplM16c62pUartP(1,
                          (uint16_t)&U1TB.BYTE.U1TBL,
                          (uint16_t)&U1RB.BYTE.U1RBL,
                          (uint16_t)&U1BRG,
                          (uint16_t)&U1MR.BYTE,
                          (uint16_t)&U1C0.BYTE,
                          (uint16_t)&U1C1.BYTE,
                          (uint16_t)&S1TIC.BYTE,
                          (uint16_t)&S1RIC.BYTE) as HplUart1P,
      new HplM16c62pUartP(2,
                          (uint16_t)&U2TB.BYTE.U2TBL,
                          (uint16_t)&U2RB.BYTE.U2RBL,
                          (uint16_t)&U2BRG,
                          (uint16_t)&U2MR.BYTE,
                          (uint16_t)&U2C0.BYTE,
                          (uint16_t)&U2C1.BYTE,
                          (uint16_t)&S2TIC.BYTE,
                          (uint16_t)&S2RIC.BYTE) as HplUart2P;

  components new StopModeControlC() as Uart0StopModeControl,
             new StopModeControlC() as Uart1StopModeControl,
             new StopModeControlC() as Uart2StopModeControl;
  
  Uart0TxControl = HplUart0P.UartTxControl;
  Uart0RxControl = HplUart0P.UartRxControl;
  HplUart0 = HplUart0P.HplUart;
  HplUart0P.TxIO -> IOs.PortP63;
  HplUart0P.RxIO -> IOs.PortP62;
  HplUart0P.Irq -> Irqs.Uart0;
  HplUart0P.StopModeControl -> Uart0StopModeControl;

  Uart1TxControl = HplUart1P.UartTxControl;
  Uart1RxControl = HplUart1P.UartRxControl;
  HplUart1 = HplUart1P.HplUart;
  HplUart1P.TxIO -> IOs.PortP67;
  HplUart1P.RxIO -> IOs.PortP66;
  HplUart1P.Irq -> Irqs.Uart1;
  HplUart1P.StopModeControl -> Uart1StopModeControl;
  
  Uart2TxControl = HplUart2P.UartTxControl;
  Uart2RxControl = HplUart2P.UartRxControl;
  HplUart2 = HplUart2P.HplUart;
  HplUart2P.TxIO -> IOs.PortP70;
  HplUart2P.RxIO -> IOs.PortP71;
  HplUart2P.Irq -> Irqs.Uart2;
  HplUart2P.StopModeControl -> Uart2StopModeControl;
  
}
