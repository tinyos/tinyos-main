/**
 * Copyright (c) 2009 The Regents of the University of California.
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
 * @author Thomas Schmid
 */

#include "sam3snvichardware.h"

configuration HplNVICC
{
    provides
    {
        interface HplNVICCntl;
		interface Init;

        interface HplNVICInterruptCntl as SUPCInterrupt;   // SUPPLY CONTROLLER
        interface HplNVICInterruptCntl as RSTCInterrupt;   // RESET CONTROLLER
        interface HplNVICInterruptCntl as RTCInterrupt;    // REAL TIME CLOCK
        interface HplNVICInterruptCntl as RTTInterrupt;    // REAL TIME TIMER
        interface HplNVICInterruptCntl as WDGInterrupt;    // WATCHDOG TIMER
        interface HplNVICInterruptCntl as PMCInterrupt;    // PMC
        interface HplNVICInterruptCntl as EFC0Interrupt;   // EFC
        interface HplNVICInterruptCntl as RES0Interrupt;   // Reserved
        interface HplNVICInterruptCntl as UART0Interrupt;  // UART0
        interface HplNVICInterruptCntl as UART1Interrupt;  // UART1
        interface HplNVICInterruptCntl as SMCInterrupt;    // SMC
        interface HplNVICInterruptCntl as PIOAInterrupt;   // PARALLEL I/O CONTROLLER A
        interface HplNVICInterruptCntl as PIOBInterrupt;   // PARALLEL I/O CONTROLLER B
        interface HplNVICInterruptCntl as PIOCInterrupt;   // PARALLEL I/O CONTROLLER C
        interface HplNVICInterruptCntl as USART0Interrupt; // USART0
        interface HplNVICInterruptCntl as USART1Interrupt; // USART1
        interface HplNVICInterruptCntl as RES1Interrupt;   // Reserved
        interface HplNVICInterruptCntl as RES2Interrupt;   // Reserved
        interface HplNVICInterruptCntl as HSMCIInterrupt;  // HIGH SPEED MULTIMEDIA CARD INTERFACE
        interface HplNVICInterruptCntl as TWI0Interrupt;   // TWO WIRE INTERFACE 0
        interface HplNVICInterruptCntl as TWI1Interrupt;   // TWO WIRE INTERFACE 1
        interface HplNVICInterruptCntl as SPIInterrupt;    // SERIAL PERIPHERAL INTERFACE
        interface HplNVICInterruptCntl as SSCInterrupt;    // SYNCHRONOUS SERIAL CONTROLLER
        interface HplNVICInterruptCntl as TC0Interrupt;    // TIMER/COUNTER 0
        interface HplNVICInterruptCntl as TC1Interrupt;    // TIMER/COUNTER 1
        interface HplNVICInterruptCntl as TC2Interrupt;    // TIMER/COUNTER 2
        interface HplNVICInterruptCntl as TC3Interrupt;    // TIMER/COUNTER 3
        interface HplNVICInterruptCntl as TC4Interrupt;    // TIMER/COUNTER 4
        interface HplNVICInterruptCntl as TC5Interrupt;    // TIMER/COUNTER 5
        interface HplNVICInterruptCntl as ADCInterrupt;    // ANALOG-TO-DIGITAL CONVERTER
        interface HplNVICInterruptCntl as DACCInterrupt;   // DIGITAL-TO-ANALOG CONVERTE
        interface HplNVICInterruptCntl as PWMInterrupt;    // PULSE WIDTH MODULATION
        interface HplNVICInterruptCntl as CRCCUInterrupt;  // CRC CALCULATION UNIT
        interface HplNVICInterruptCntl as ACCInterrupt;    // ANALOG COMPARATOR
        interface HplNVICInterruptCntl as UDPInterrupt;    // USB DEVICE PORT
    }
}

implementation
{
    components HplNVICCntlP,
        new HplNVICInterruptP(AT91C_ID_SUPC)   as SUPC  , 
        new HplNVICInterruptP(AT91C_ID_RSTC)   as RSTC  , 
        new HplNVICInterruptP(AT91C_ID_RTC)    as RTC   , 
        new HplNVICInterruptP(AT91C_ID_RTT)    as RTT   , 
        new HplNVICInterruptP(AT91C_ID_WDG)    as WDG   , 
        new HplNVICInterruptP(AT91C_ID_PMC)    as PMC   , 
        new HplNVICInterruptP(AT91C_ID_EFC0)   as EFC0  , 
        new HplNVICInterruptP(AT91C_ID_RES0)   as RES0  , 
        new HplNVICInterruptP(AT91C_ID_UART0)  as UART0 , 
        new HplNVICInterruptP(AT91C_ID_UART1)  as UART1 , 
        new HplNVICInterruptP(AT91C_ID_SMC)    as SMC   , 
        new HplNVICInterruptP(AT91C_ID_PIOA)   as PIOA  , 
        new HplNVICInterruptP(AT91C_ID_PIOB)   as PIOB  , 
        new HplNVICInterruptP(AT91C_ID_PIOC)   as PIOC  , 
        new HplNVICInterruptP(AT91C_ID_USART0) as USART0, 
        new HplNVICInterruptP(AT91C_ID_USART1) as USART1, 
        new HplNVICInterruptP(AT91C_ID_RES1)   as RES1  , 
        new HplNVICInterruptP(AT91C_ID_RES2)   as RES2  , 
        new HplNVICInterruptP(AT91C_ID_HSMCI)  as HSMCI , 
        new HplNVICInterruptP(AT91C_ID_TWI0)   as TWI0  , 
        new HplNVICInterruptP(AT91C_ID_TWI1)   as TWI1  , 
        new HplNVICInterruptP(AT91C_ID_SPI)    as SPI   , 
        new HplNVICInterruptP(AT91C_ID_SSC)    as SSC   , 
        new HplNVICInterruptP(AT91C_ID_TC0)    as TC0   , 
        new HplNVICInterruptP(AT91C_ID_TC1)    as TC1   , 
        new HplNVICInterruptP(AT91C_ID_TC2)    as TC2   , 
        new HplNVICInterruptP(AT91C_ID_TC3)    as TC3   , 
        new HplNVICInterruptP(AT91C_ID_TC4)    as TC4   , 
        new HplNVICInterruptP(AT91C_ID_TC5)    as TC5   , 
        new HplNVICInterruptP(AT91C_ID_ADC)    as ADC   , 
        new HplNVICInterruptP(AT91C_ID_DACC)   as DACC  , 
        new HplNVICInterruptP(AT91C_ID_PWM)    as PWM   , 
        new HplNVICInterruptP(AT91C_ID_CRCCU)  as CRCCU , 
        new HplNVICInterruptP(AT91C_ID_ACC)    as ACC   , 
        new HplNVICInterruptP(AT91C_ID_UDP)    as UDP   ;


    HplNVICCntl = HplNVICCntlP;
    Init = HplNVICCntlP;

    SUPCInterrupt   = SUPC.Cntl;
    RSTCInterrupt   = RSTC.Cntl;
    RTCInterrupt    = RTC.Cntl;
    RTTInterrupt    = RTT.Cntl;
    WDGInterrupt    = WDG.Cntl;
    PMCInterrupt    = PMC.Cntl;
    EFC0Interrupt   = EFC0.Cntl;
    RES0Interrupt   = RES0.Cntl;
    UART0Interrupt  = UART0.Cntl;
    UART1Interrupt  = UART1.Cntl;
    SMCInterrupt    = SMC.Cntl;
    PIOAInterrupt   = PIOA.Cntl;
    PIOBInterrupt   = PIOB.Cntl;
    PIOCInterrupt   = PIOC.Cntl;
    USART0Interrupt = USART0.Cntl;
    USART1Interrupt = USART1.Cntl;
    RES1Interrupt   = RES1.Cntl;
    RES2Interrupt   = RES2.Cntl;
    HSMCIInterrupt  = HSMCI.Cntl;
    TWI0Interrupt   = TWI0.Cntl;
    TWI1Interrupt   = TWI1.Cntl;
    SPIInterrupt    = SPI.Cntl;
    SSCInterrupt    = SSC.Cntl;
    TC0Interrupt    = TC0.Cntl;
    TC1Interrupt    = TC1.Cntl;
    TC2Interrupt    = TC2.Cntl;
    TC3Interrupt    = TC3.Cntl;
    TC4Interrupt    = TC4.Cntl;
    TC5Interrupt    = TC5.Cntl;
    ADCInterrupt    = ADC.Cntl;
    DACCInterrupt   = DACC.Cntl;
    PWMInterrupt    = PWM.Cntl;
    CRCCUInterrupt  = CRCCU.Cntl;
    ACCInterrupt    = ACC.Cntl;
    UDPInterrupt    = UDP.Cntl;
}
