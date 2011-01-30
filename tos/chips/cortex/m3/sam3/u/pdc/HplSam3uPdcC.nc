/*
* Copyright (c) 2009 Johns Hopkins University.
* All rights reserved.
*
* Permission to use, copy, modify, and distribute this software and its
* documentation for any purpose, without fee, and without written
* agreement is hereby granted, provided that the above copyright
* notice, the (updated) modification history and the author appear in
* all copies of this source code.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS  `AS IS'
* AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED  TO, THE
* IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR  PURPOSE
* ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR  CONTRIBUTORS
* BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
* CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, LOSS OF USE,  DATA,
* OR PROFITS) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
* CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR  OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
* THE POSSIBILITY OF SUCH DAMAGE.
*/

/**
 * @author JeongGil Ko
 */

configuration HplSam3uPdcC {
  provides interface HplSam3uPdc as UartPdcControl;
  provides interface HplSam3uPdc as Usart0PdcControl;
  provides interface HplSam3uPdc as Usart1PdcControl;
  provides interface HplSam3uPdc as Usart2PdcControl;
  provides interface HplSam3uPdc as Usart3PdcControl;
  provides interface HplSam3uPdc as Twi0PdcControl;
  provides interface HplSam3uPdc as Twi1PdcControl;
  provides interface HplSam3uPdc as PwmPdcControl;
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

  components new HplSam3uPdcP(UART_BASE) as UartPdc;
  components new HplSam3uPdcP(USART0_BASE) as Usart0Pdc;
  components new HplSam3uPdcP(USART1_BASE) as Usart1Pdc;
  components new HplSam3uPdcP(USART2_BASE) as Usart2Pdc;
  components new HplSam3uPdcP(USART3_BASE) as Usart3Pdc;
  components new HplSam3uPdcP(TWI0_BASE) as Twi0Pdc;
  components new HplSam3uPdcP(TWI1_BASE) as Twi1Pdc;
  components new HplSam3uPdcP(PWM_BASE) as PwmPdc;

  UartPdcControl = UartPdc;
  Usart0PdcControl = Usart0Pdc;
  Usart1PdcControl = Usart1Pdc;
  Usart2PdcControl = Usart2Pdc;
  Usart3PdcControl = Usart3Pdc;
  Twi0PdcControl = Twi0Pdc;
  Twi1PdcControl = Twi1Pdc;
  PwmPdcControl = PwmPdc;
}
