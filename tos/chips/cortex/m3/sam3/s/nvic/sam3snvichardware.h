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

#ifndef SAM3SNVICHARDWARE_H
#define SAM3SNVICHARDWARE_H

#include "nvichardware.h"
#include "sam3shardware.h"

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
 IRQn_SUPC                  = AT91C_ID_SUPC  , // SUPPLY CONTROLLER
 IRQn_RSTC                  = AT91C_ID_RSTC  , // RESET CONTROLLER
 IRQn_RTC                   = AT91C_ID_RTC   , // REAL TIME CLOCK
 IRQn_RTT                   = AT91C_ID_RTT   , // REAL TIME TIMER
 IRQn_WDG                   = AT91C_ID_WDG   , // WATCHDOG TIMER
 IRQn_PMC                   = AT91C_ID_PMC   , // PMC
 IRQn_EFC0                  = AT91C_ID_EFC0  , // EFC
 IRQn_RES0                  = AT91C_ID_RES0  , // Reserved
 IRQn_UART0                 = AT91C_ID_UART0 , // UART0
 IRQn_UART1                 = AT91C_ID_UART1 , // UART1
 IRQn_SMC                   = AT91C_ID_SMC   , // SMC
 IRQn_PIOA                  = AT91C_ID_PIOA  , // PARALLEL I/O CONTROLLER A
 IRQn_PIOB                  = AT91C_ID_PIOB  , // PARALLEL I/O CONTROLLER B
 IRQn_PIOC                  = AT91C_ID_PIOC  , // PARALLEL I/O CONTROLLER C
 IRQn_USART0                = AT91C_ID_USART0, // USART0
 IRQn_USART1                = AT91C_ID_USART1, // USART1
 IRQn_RES1                  = AT91C_ID_RES1  , // Reserved
 IRQn_RES2                  = AT91C_ID_RES2  , // Reserved
 IRQn_HSMCI                 = AT91C_ID_HSMCI , // HIGH SPEED MULTIMEDIA CARD INTERFACE
 IRQn_TWI0                  = AT91C_ID_TWI0  , // TWO WIRE INTERFACE 0
 IRQn_TWI1                  = AT91C_ID_TWI1  , // TWO WIRE INTERFACE 1
 IRQn_SPI                   = AT91C_ID_SPI   , // SERIAL PERIPHERAL INTERFACE
 IRQn_SSC                   = AT91C_ID_SSC   , // SYNCHRONOUS SERIAL CONTROLLER
 IRQn_TC0                   = AT91C_ID_TC0   , // TIMER/COUNTER 0
 IRQn_TC1                   = AT91C_ID_TC1   , // TIMER/COUNTER 1
 IRQn_TC2                   = AT91C_ID_TC2   , // TIMER/COUNTER 2
 IRQn_TC3                   = AT91C_ID_TC3   , // TIMER/COUNTER 3
 IRQn_TC4                   = AT91C_ID_TC4   , // TIMER/COUNTER 4
 IRQn_TC5                   = AT91C_ID_TC5   , // TIMER/COUNTER 5
 IRQn_ADC                   = AT91C_ID_ADC   , // ANALOG-TO-DIGITAL CONVERTER
 IRQn_DACC                  = AT91C_ID_DACC  , // DIGITAL-TO-ANALOG CONVERTE
 IRQn_PWM                   = AT91C_ID_PWM   , // PULSE WIDTH MODULATION
 IRQn_CRCCU                 = AT91C_ID_CRCCU , // CRC CALCULATION UNIT
 IRQn_ACC                   = AT91C_ID_ACC   , // ANALOG COMPARATOR
 IRQn_UDP                   = AT91C_ID_UDP    // USB DEVICE PORT
} irqn_t;

#endif // SAM3SNVICHARDWARE_H
