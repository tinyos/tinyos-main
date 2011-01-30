/*
 * Copyright (c) 2011 University of Utah.
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
 * - Neither the name of the copyright holder nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * COPYRIGHT HOLDER OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 *
 *
 * @author Thomas Schmid
 */

#ifndef SAM3UNVICHARDWARE_H
#define SAM3UNVICHARDWARE_H

#include "nvichardware.h"
#include "sam3uhardware.h"

/// Interrupt sources
typedef enum irqn
{
/******  Cortex-M3 Processor Exceptions Numbers ***************************************************/
  NonMaskableInt_IRQn         = -14,    /*!< 2 Non Maskable Interrupt                             */
  MemoryManagement_IRQn       = -12,    /*!< 4 Cortex-M3 Memory Management Interrupt              */
  BusFault_IRQn               = -11,    /*!< 5 Cortex-M3 Bus Fault Interrupt                      */
  UsageFault_IRQn             = -10,    /*!< 6 Cortex-M3 Usage Fault Interrupt                    */
  SVCall_IRQn                 = -5,     /*!< 11 Cortex-M3 SV Call Interrupt                       */
  DebugMonitor_IRQn           = -4,     /*!< 12 Cortex-M3 Debug Monitor Interrupt                 */
  PendSV_IRQn                 = -2,     /*!< 14 Cortex-M3 Pend SV Interrupt                       */
  SysTick_IRQn                = -1,     /*!< 15 Cortex-M3 System Tick Interrupt                   */

/******  AT91SAM3U4 specific Interrupt Numbers *********************************************************/
 IROn_SUPC                = AT91C_ID_SUPC , // SUPPLY CONTROLLER
 IROn_RSTC                = AT91C_ID_RSTC , // RESET CONTROLLER
 IROn_RTC                 = AT91C_ID_RTC  , // REAL TIME CLOCK
 IROn_RTT                 = AT91C_ID_RTT  , // REAL TIME TIMER
 IROn_WDG                 = AT91C_ID_WDG  , // WATCHDOG TIMER
 IROn_PMC                 = AT91C_ID_PMC  , // PMC
 IROn_EFC0                = AT91C_ID_EFC0 , // EFC0
 IROn_EFC1                = AT91C_ID_EFC1 , // EFC1
 IROn_DBGU                = AT91C_ID_DBGU , // DBGU
 IROn_HSMC4               = AT91C_ID_HSMC4, // HSMC4
 IROn_PIOA                = AT91C_ID_PIOA , // Parallel IO Controller A
 IROn_PIOB                = AT91C_ID_PIOB , // Parallel IO Controller B
 IROn_PIOC                = AT91C_ID_PIOC , // Parallel IO Controller C
 IROn_US0                 = AT91C_ID_US0  , // USART 0
 IROn_US1                 = AT91C_ID_US1  , // USART 1
 IROn_US2                 = AT91C_ID_US2  , // USART 2
 IROn_US3                 = AT91C_ID_US3  , // USART 3
 IROn_MCI0                = AT91C_ID_MCI0 , // Multimedia Card Interface
 IROn_TWI0                = AT91C_ID_TWI0 , // TWI 0
 IROn_TWI1                = AT91C_ID_TWI1 , // TWI 1
 IROn_SPI0                = AT91C_ID_SPI0 , // Serial Peripheral Interface
 IROn_SSC0                = AT91C_ID_SSC0 , // Serial Synchronous Controller 0
 IROn_TC0                 = AT91C_ID_TC0  , // Timer Counter 0
 IROn_TC1                 = AT91C_ID_TC1  , // Timer Counter 1
 IROn_TC2                 = AT91C_ID_TC2  , // Timer Counter 2
 IROn_PWMC                = AT91C_ID_PWMC , // Pulse Width Modulation Controller
 IROn_ADCC0               = AT91C_ID_ADC12B, // ADC controller0
 IROn_ADCC1               = AT91C_ID_ADC, // ADC controller1
 IROn_HDMA                = AT91C_ID_HDMA , // HDMA
 IROn_UDPHS               = AT91C_ID_UDPHS // USB Device High Speed
} irqn_t;

#endif // SAM3UNVICHARDWARE_H
