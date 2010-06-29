/// $Id: HplAtm128UartC.nc,v 1.2 2010-06-29 22:07:51 scipio Exp $

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

/// 

#include <Atm128Uart.h>

/**
 * HPL for the Atmega 128 serial ports.
 *
 * @author Martin Turon <mturon@xbow.com>
 * @author David Gay
 */
configuration HplAtm128UartC
{
  provides {
    interface StdControl as Uart0TxControl;
    interface StdControl as Uart0RxControl;
    interface HplAtm128Uart as HplUart0;
    
    interface StdControl as Uart1TxControl;
    interface StdControl as Uart1RxControl;
    interface HplAtm128Uart as HplUart1;
  }
}
implementation
{
  components HplAtm128UartP, PlatformC, McuSleepC;
  
  Uart0TxControl = HplAtm128UartP.Uart0TxControl;
  Uart0RxControl = HplAtm128UartP.Uart0RxControl;
  HplUart0 = HplAtm128UartP.HplUart0;
  
  Uart1TxControl = HplAtm128UartP.Uart1TxControl;
  Uart1RxControl = HplAtm128UartP.Uart1RxControl;
  HplUart1 = HplAtm128UartP.HplUart1;
  
  HplAtm128UartP.Atm128Calibrate -> PlatformC;
  HplAtm128UartP.McuPowerState -> McuSleepC;
  
  components MainC;
  MainC.SoftwareInit -> HplAtm128UartP.Uart0Init;
  MainC.SoftwareInit -> HplAtm128UartP.Uart1Init;
  
  components PlatformInterruptC;
  HplAtm128UartP.PlatformInterrupt -> PlatformInterruptC;
}
