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

/**
 * All uart interrupt vector handlers.
 * These are wired in HplM16c60UartC.
 *
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 */

module HplM16c60UartInterruptP
{
  provides interface HplM16c60UartInterrupt as Uart0;
  provides interface HplM16c60UartInterrupt as Uart1;
  provides interface HplM16c60UartInterrupt as Uart2;
  
#ifdef THREADS
  uses interface PlatformInterrupt;
#define POST_AMBLE() call PlatformInterrupt.postAmble()
#else 
#define POST_AMBLE()
#endif 
}
implementation
{
  default async event void Uart0.tx() { } 
  M16C_INTERRUPT_HANDLER(M16C_UART0_NACK)
  {
    signal Uart0.tx();
    POST_AMBLE();
  }

  default async event void Uart0.rx() { } 
  M16C_INTERRUPT_HANDLER(M16C_UART0_ACK)
  {
    signal Uart0.rx();
    POST_AMBLE();
  }


  default async event void Uart1.tx() { } 
  M16C_INTERRUPT_HANDLER(M16C_UART1_NACK)
  {
    signal Uart1.tx();
    POST_AMBLE();
  }

  default async event void Uart1.rx() { } 
  M16C_INTERRUPT_HANDLER(M16C_UART1_ACK)
  {
    signal Uart1.rx();
    POST_AMBLE();
  }


  default async event void Uart2.tx() { } 
  M16C_INTERRUPT_HANDLER(M16C_UART2_NACK)
  {
    signal Uart2.tx();
    POST_AMBLE();
  }

  default async event void Uart2.rx() { } 
  M16C_INTERRUPT_HANDLER(M16C_UART2_ACK)
  {
    signal Uart2.rx();
    POST_AMBLE();
  }
}
