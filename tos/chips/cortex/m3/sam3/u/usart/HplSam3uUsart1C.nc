/*
 * Copyright (c) 2011 University of Utah
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

configuration HplSam3uUsart1C{
  provides interface HplSam3uUsartControl;
}
implementation{
  components HplSam3uUsart1P as UsartP;
  HplSam3uUsartControl = UsartP.Usart;


  components HplSam3uGeneralIOC, HplSam3uClockC, HplNVICC;

  UsartP.USART_CTS1 -> HplSam3uGeneralIOC.HplPioA23;
  UsartP.USART_RTS1 -> HplSam3uGeneralIOC.HplPioA22;
  UsartP.USART_RXD1 -> HplSam3uGeneralIOC.HplPioA21;
  UsartP.USART_SCK1 -> HplSam3uGeneralIOC.HplPioA24;
  UsartP.USART_TXD1 -> HplSam3uGeneralIOC.HplPioA20;

  UsartP.USARTClockControl1 -> HplSam3uClockC.US1PPCntl;
  UsartP.USARTInterrupt1 -> HplNVICC.US1Interrupt;

  UsartP.ClockConfig -> HplSam3uClockC;

  components McuSleepC;
  UsartP.Usart1InterruptWrapper -> McuSleepC;

  components LedsC;
  UsartP.Leds -> LedsC;
}
