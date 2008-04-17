/*
 * Copyright (c) 2008 Stanford University.
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
 * - Neither the name of the Stanford University nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
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
 * @author Kevin Klues <klueska@cs.stanford.edu>
 */

module HplMsp430InterruptSigP
{
   provides {
    interface HplMsp430InterruptSig as SIGNAL_ADC_VECTOR;
    interface HplMsp430InterruptSig as SIGNAL_DACDMA_VECTOR;
    interface HplMsp430InterruptSig as SIGNAL_NMI_VECTOR;
    interface HplMsp430InterruptSig as SIGNAL_PORT1_VECTOR;
    interface HplMsp430InterruptSig as SIGNAL_PORT2_VECTOR;
    interface HplMsp430InterruptSig as SIGNAL_TIMERA0_VECTOR;
    interface HplMsp430InterruptSig as SIGNAL_TIMERA1_VECTOR;
    interface HplMsp430InterruptSig as SIGNAL_TIMERB0_VECTOR;
    interface HplMsp430InterruptSig as SIGNAL_TIMERB1_VECTOR;
    interface HplMsp430InterruptSig as SIGNAL_UART0RX_VECTOR;
    interface HplMsp430InterruptSig as SIGNAL_UART0TX_VECTOR;
    interface HplMsp430InterruptSig as SIGNAL_UART1RX_VECTOR;
    interface HplMsp430InterruptSig as SIGNAL_UART1TX_VECTOR;
  }
}
implementation {
  #define MSP430_INTERRUPT_HANDLER(NAME) 								\
    default async event void SIGNAL_##NAME.fired() {}					\
    TOSH_SIGNAL(NAME) {													\
      signal SIGNAL_##NAME.fired();										\
    }

  MSP430_INTERRUPT_HANDLER(ADC_VECTOR)
  MSP430_INTERRUPT_HANDLER(DACDMA_VECTOR)
  MSP430_INTERRUPT_HANDLER(NMI_VECTOR)
  MSP430_INTERRUPT_HANDLER(PORT1_VECTOR)
  MSP430_INTERRUPT_HANDLER(PORT2_VECTOR)
  MSP430_INTERRUPT_HANDLER(TIMERA0_VECTOR)
  MSP430_INTERRUPT_HANDLER(TIMERA1_VECTOR)
  MSP430_INTERRUPT_HANDLER(TIMERB0_VECTOR)
  MSP430_INTERRUPT_HANDLER(TIMERB1_VECTOR)
  MSP430_INTERRUPT_HANDLER(UART0RX_VECTOR)
  MSP430_INTERRUPT_HANDLER(UART0TX_VECTOR)
  MSP430_INTERRUPT_HANDLER(UART1RX_VECTOR)
  MSP430_INTERRUPT_HANDLER(UART1TX_VECTOR)
}
