/*
 * Copyright (c) 2010 University of Utah.
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
 * - Neither the name of copyright holder nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * Definitions specific to the SAM3S MCU.
 *
 * @author Thomas Schmid
 */

#ifndef SAM3S_HARDWARE_H
#define SAM3S_HARDWARE_H

#include <cortexm_nesc.h>

// The Sam3s has more I/O Muxing than the Sam3u.
#define CHIP_SAM3_HAS_PERIPHERAL_CD 1

// Peripheral ID definitions for the SAM3S
//  Defined in AT91 ARM Cortex-M3 based Microcontrollers, SAM3S Series, Preliminary, p. 34
#define AT91C_ID_SUPC   ( 0) // SUPPLY CONTROLLER
#define AT91C_ID_RSTC   ( 1) // RESET CONTROLLER
#define AT91C_ID_RTC    ( 2) // REAL TIME CLOCK
#define AT91C_ID_RTT    ( 3) // REAL TIME TIMER
#define AT91C_ID_WDG    ( 4) // WATCHDOG TIMER
#define AT91C_ID_PMC    ( 5) // PMC
#define AT91C_ID_EFC0   ( 6) // EFC
#define AT91C_ID_RES0   ( 7) // Reserved
#define AT91C_ID_UART0  ( 8) // UART0
#define AT91C_ID_UART1  ( 9) // UART1
#define AT91C_ID_SMC    (10) // SMC
#define AT91C_ID_PIOA   (11) // PARALLEL I/O CONTROLLER A
#define AT91C_ID_PIOB   (12) // PARALLEL I/O CONTROLLER B
#define AT91C_ID_PIOC   (13) // PARALLEL I/O CONTROLLER C
#define AT91C_ID_USART0 (14) // USART0
#define AT91C_ID_USART1 (15) // USART1
#define AT91C_ID_RES1   (16) // Reserved
#define AT91C_ID_RES2   (17) // Reserved
#define AT91C_ID_HSMCI  (18) // HIGH SPEED MULTIMEDIA CARD INTERFACE
#define AT91C_ID_TWI0   (19) // TWO WIRE INTERFACE 0
#define AT91C_ID_TWI1   (20) // TWO WIRE INTERFACE 1
#define AT91C_ID_SPI    (21) // SERIAL PERIPHERAL INTERFACE
#define AT91C_ID_SSC    (22) // SYNCHRONOUS SERIAL CONTROLLER
#define AT91C_ID_TC0    (23) // TIMER/COUNTER 0
#define AT91C_ID_TC1    (24) // TIMER/COUNTER 1
#define AT91C_ID_TC2    (25) // TIMER/COUNTER 2
#define AT91C_ID_TC3    (26) // TIMER/COUNTER 3
#define AT91C_ID_TC4    (27) // TIMER/COUNTER 4
#define AT91C_ID_TC5    (28) // TIMER/COUNTER 5
#define AT91C_ID_ADC    (29) // ANALOG-TO-DIGITAL CONVERTER
#define AT91C_ID_DACC   (30) // DIGITAL-TO-ANALOG CONVERTE
#define AT91C_ID_PWM    (31) // PULSE WIDTH MODULATION
#define AT91C_ID_CRCCU  (32) // CRC CALCULATION UNIT
#define AT91C_ID_ACC    (33) // ANALOG COMPARATOR
#define AT91C_ID_UDP    (34) // USB DEVICE PORT

#define SAM3S_PERIPHERALA (0x400e0e00)
#define SAM3S_PERIPHERALB (0x400e1000)
#define SAM3S_PERIPHERALC (0x400e1200)

#define TOSH_ASSIGN_PIN(name, port, bit) \
static inline void TOSH_SET_##name##_PIN() \
  {*((volatile uint32_t *) (SAM3S_PERIPHERAL##port + 0x030)) = (1 << bit);} \
static inline void TOSH_CLR_##name##_PIN() \
  {*((volatile uint32_t *) (SAM3S_PERIPHERAL##port + 0x034)) = (1 << bit);} \
static inline int TOSH_READ_##name##_PIN() \
  { \
    /* Read bit from Output Status Register */ \
    uint32_t currentport = *((volatile uint32_t *) (SAM3S_PERIPHERAL##port + 0x018)); \
    uint32_t currentpin = (currentport & (1 << bit)) >> bit; \
    bool isInput = ((currentpin & 1) == 0); \
    if (isInput == 1) { \
            /* Read bit from Pin Data Status Register */ \
            currentport = *((volatile uint32_t *) (SAM3S_PERIPHERAL##port + 0x03c)); \
            currentpin = (currentport & (1 << bit)) >> bit; \
            return ((currentpin & 1) == 1); \
    } else { \
            /* Read bit from Output Data Status Register */ \
            currentport = *((volatile uint32_t *) (SAM3S_PERIPHERAL##port + 0x038)); \
            currentpin = (currentport & (1 << bit)) >> bit; \
            return ((currentpin & 1) == 1); \
    } \
  } \
static inline void TOSH_MAKE_##name##_OUTPUT() \
  {*((volatile uint32_t *) (SAM3S_PERIPHERAL##port + 0x010)) = (1 << bit);} \
static inline void TOSH_MAKE_##name##_INPUT() \
  {*((volatile uint32_t *) (SAM3S_PERIPHERAL##port + 0x014)) = (1 << bit);}

#define TOSH_ASSIGN_OUTPUT_ONLY_PIN(name, port, bit) \
static inline void TOSH_SET_##name##_PIN() \
  {*((volatile uint32_t *) (SAM3S_PERIPHERAL##port + 0x030)) = (1 << bit);} \
static inline void TOSH_CLR_##name##_PIN() \
  {*((volatile uint32_t *) (SAM3S_PERIPHERAL##port + 0x034)) = (1 << bit);} \
static inline void TOSH_MAKE_##name##_OUTPUT() \
  {*((volatile uint32_t *) (SAM3S_PERIPHERAL##port + 0x010)) = (1 << bit);} \

#define TOSH_ALIAS_OUTPUT_ONLY_PIN(alias, connector)\
static inline void TOSH_SET_##alias##_PIN() {TOSH_SET_##connector##_PIN();} \
static inline void TOSH_CLR_##alias##_PIN() {TOSH_CLR_##connector##_PIN();} \
static inline void TOSH_MAKE_##alias##_OUTPUT() {} \

#define TOSH_ALIAS_PIN(alias, connector) \
static inline void TOSH_SET_##alias##_PIN() {TOSH_SET_##connector##_PIN();} \
static inline void TOSH_CLR_##alias##_PIN() {TOSH_CLR_##connector##_PIN();} \
static inline char TOSH_READ_##alias##_PIN() {return TOSH_READ_##connector##_PIN();} \
static inline void TOSH_MAKE_##alias##_OUTPUT() {TOSH_MAKE_##connector##_OUTPUT();} \

#endif // SAM3S_HARDWARE_H
