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
 * @author JeongGil Ko
 */

configuration HplSam3uPdcC {
  provides interface HplSam3Pdc as UartPdcControl;
  provides interface HplSam3Pdc as Usart0PdcControl;
  provides interface HplSam3Pdc as Usart1PdcControl;
  provides interface HplSam3Pdc as Usart2PdcControl;
  provides interface HplSam3Pdc as Usart3PdcControl;
  provides interface HplSam3Pdc as Twi0PdcControl;
  provides interface HplSam3Pdc as Twi1PdcControl;
  provides interface HplSam3Pdc as PwmPdcControl;
}

implementation {

  enum {
    UART_BASE = 0x400E0600,
    USART0_BASE = 0x40090000,
    USART1_BASE = 0x40094000,
    USART2_BASE = 0x40098000,
    USART3_BASE = 0x4009C000,
    TWI0_BASE = 0x40084000,
    TWI1_BASE = 0x40088000,
    PWM_BASE = 0x4008C000
  };

  components new HplSam3PdcP(UART_BASE) as UartPdc;
  components new HplSam3PdcP(USART0_BASE) as Usart0Pdc;
  components new HplSam3PdcP(USART1_BASE) as Usart1Pdc;
  components new HplSam3PdcP(USART2_BASE) as Usart2Pdc;
  components new HplSam3PdcP(USART3_BASE) as Usart3Pdc;
  components new HplSam3PdcP(TWI0_BASE) as Twi0Pdc;
  components new HplSam3PdcP(TWI1_BASE) as Twi1Pdc;
  components new HplSam3PdcP(PWM_BASE) as PwmPdc;

  UartPdcControl = UartPdc;
  Usart0PdcControl = Usart0Pdc;
  Usart1PdcControl = Usart1Pdc;
  Usart2PdcControl = Usart2Pdc;
  Usart3PdcControl = Usart3Pdc;
  Twi0PdcControl = Twi0Pdc;
  Twi1PdcControl = Twi1Pdc;
  PwmPdcControl = PwmPdc;
}
