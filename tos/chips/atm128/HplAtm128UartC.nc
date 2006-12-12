/// $Id: HplAtm128UartC.nc,v 1.5 2006-12-12 18:23:03 vlahan Exp $

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
  
}
