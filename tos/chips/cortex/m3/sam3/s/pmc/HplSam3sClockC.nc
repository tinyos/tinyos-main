/**
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
 * This is the main configuration for the low-layer clock module.
 *
 * @author Thomas Schmid
 */

configuration HplSam3sClockC
{
    provides
    {
        interface HplSam3Clock;

        interface HplSam3PeripheralClockCntl as RTCCntl;
        interface HplSam3PeripheralClockCntl as RTTCntl;
        interface HplSam3PeripheralClockCntl as WDGCntl;
        interface HplSam3PeripheralClockCntl as PMCCntl;
        interface HplSam3PeripheralClockCntl as EFC0Cntl;
        interface HplSam3PeripheralClockCntl as RES0Cntl;
        interface HplSam3PeripheralClockCntl as UART0Cntl;
        interface HplSam3PeripheralClockCntl as UART1Cntl;
        interface HplSam3PeripheralClockCntl as SMCCntl;
        interface HplSam3PeripheralClockCntl as PIOACntl;
        interface HplSam3PeripheralClockCntl as PIOBCntl;
        interface HplSam3PeripheralClockCntl as PIOCCntl;
        interface HplSam3PeripheralClockCntl as USART0Cntl;
        interface HplSam3PeripheralClockCntl as USART1Cntl;
        interface HplSam3PeripheralClockCntl as RES1Cntl;
        interface HplSam3PeripheralClockCntl as RES2Cntl;
        interface HplSam3PeripheralClockCntl as HSMCICntl;
        interface HplSam3PeripheralClockCntl as TWI0Cntl;
        interface HplSam3PeripheralClockCntl as TWI1Cntl;
        interface HplSam3PeripheralClockCntl as SPICntl;
        interface HplSam3PeripheralClockCntl as SSCCntl;
        interface HplSam3PeripheralClockCntl as TC0Cntl;
        interface HplSam3PeripheralClockCntl as TC1Cntl;
        interface HplSam3PeripheralClockCntl as TC2Cntl;
        interface HplSam3PeripheralClockCntl as TC3Cntl;
        interface HplSam3PeripheralClockCntl as TC4Cntl;
        interface HplSam3PeripheralClockCntl as TC5Cntl;
        interface HplSam3PeripheralClockCntl as ADCCntl;
        interface HplSam3PeripheralClockCntl as DACCCntl;
        interface HplSam3PeripheralClockCntl as PWMCntl;
        interface HplSam3PeripheralClockCntl as CRCCUCntl;
        interface HplSam3PeripheralClockCntl as ACCCntl;
        interface HplSam3PeripheralClockCntl as UDPCntl;
    }
}
implementation
{
#define PMC_PC_BASE  0x400e0410
#define PMC_PC1_BASE 0x400e0500

    components HplSam3sClockP,
               new HplSam3PeripheralClockP(AT91C_ID_RTC   ,PMC_PC_BASE ) as RTC, 
               new HplSam3PeripheralClockP(AT91C_ID_RTT   ,PMC_PC_BASE ) as RTT, 
               new HplSam3PeripheralClockP(AT91C_ID_WDG   ,PMC_PC_BASE ) as WDG, 
               new HplSam3PeripheralClockP(AT91C_ID_PMC   ,PMC_PC_BASE ) as PMC, 
               new HplSam3PeripheralClockP(AT91C_ID_EFC0  ,PMC_PC_BASE ) as EFC0, 
               new HplSam3PeripheralClockP(AT91C_ID_RES0  ,PMC_PC_BASE ) as RES0, 
               new HplSam3PeripheralClockP(AT91C_ID_UART0 ,PMC_PC_BASE ) as UART0, 
               new HplSam3PeripheralClockP(AT91C_ID_UART1 ,PMC_PC_BASE ) as UART1, 
               new HplSam3PeripheralClockP(AT91C_ID_SMC   ,PMC_PC_BASE ) as SMC, 
               new HplSam3PeripheralClockP(AT91C_ID_PIOA  ,PMC_PC_BASE ) as PIOA, 
               new HplSam3PeripheralClockP(AT91C_ID_PIOB  ,PMC_PC_BASE ) as PIOB, 
               new HplSam3PeripheralClockP(AT91C_ID_PIOC  ,PMC_PC_BASE ) as PIOC, 
               new HplSam3PeripheralClockP(AT91C_ID_USART0,PMC_PC_BASE ) as USART0, 
               new HplSam3PeripheralClockP(AT91C_ID_USART1,PMC_PC_BASE ) as USART1, 
               new HplSam3PeripheralClockP(AT91C_ID_RES1  ,PMC_PC_BASE ) as RES1, 
               new HplSam3PeripheralClockP(AT91C_ID_RES2  ,PMC_PC_BASE ) as RES2, 
               new HplSam3PeripheralClockP(AT91C_ID_HSMCI ,PMC_PC_BASE ) as HSMCI, 
               new HplSam3PeripheralClockP(AT91C_ID_TWI0  ,PMC_PC_BASE ) as TWI0, 
               new HplSam3PeripheralClockP(AT91C_ID_TWI1  ,PMC_PC_BASE ) as TWI1, 
               new HplSam3PeripheralClockP(AT91C_ID_SPI   ,PMC_PC_BASE ) as SPI, 
               new HplSam3PeripheralClockP(AT91C_ID_SSC   ,PMC_PC_BASE ) as SSC, 
               new HplSam3PeripheralClockP(AT91C_ID_TC0   ,PMC_PC_BASE ) as TC0, 
               new HplSam3PeripheralClockP(AT91C_ID_TC1   ,PMC_PC_BASE ) as TC1, 
               new HplSam3PeripheralClockP(AT91C_ID_TC2   ,PMC_PC_BASE ) as TC2, 
               new HplSam3PeripheralClockP(AT91C_ID_TC3   ,PMC_PC_BASE ) as TC3, 
               new HplSam3PeripheralClockP(AT91C_ID_TC4   ,PMC_PC_BASE ) as TC4, 
               new HplSam3PeripheralClockP(AT91C_ID_TC5   ,PMC_PC_BASE ) as TC5, 
               new HplSam3PeripheralClockP(AT91C_ID_ADC   ,PMC_PC_BASE ) as ADC, 
               new HplSam3PeripheralClockP(AT91C_ID_DACC  ,PMC_PC_BASE ) as DACC, 
               new HplSam3PeripheralClockP(AT91C_ID_PWM   ,PMC_PC_BASE ) as PWM, 
               new HplSam3PeripheralClockP(AT91C_ID_CRCCU ,PMC_PC1_BASE) as CRCCU, 
               new HplSam3PeripheralClockP(AT91C_ID_ACC   ,PMC_PC1_BASE) as ACC, 
               new HplSam3PeripheralClockP(AT91C_ID_UDP   ,PMC_PC1_BASE) as UDP; 

    HplSam3Clock = HplSam3sClockP;

    RTCCntl    = RTC.Cntl;
    RTTCntl    = RTT.Cntl;
    WDGCntl    = WDG.Cntl;
    PMCCntl    = PMC.Cntl;
    EFC0Cntl   = EFC0.Cntl;
    RES0Cntl   = RES0.Cntl;
    UART0Cntl  = UART0.Cntl;
    UART1Cntl  = UART1.Cntl;
    SMCCntl    = SMC.Cntl;
    PIOACntl   = PIOA.Cntl;
    PIOBCntl   = PIOB.Cntl;
    PIOCCntl   = PIOC.Cntl;
    USART0Cntl = USART0.Cntl;
    USART1Cntl = USART1.Cntl;
    RES1Cntl   = RES1.Cntl;
    RES2Cntl   = RES2.Cntl;
    HSMCICntl  = HSMCI.Cntl;
    TWI0Cntl   = TWI0.Cntl;
    TWI1Cntl   = TWI1.Cntl;
    SPICntl    = SPI.Cntl;
    SSCCntl    = SSC.Cntl;
    TC0Cntl    = TC0.Cntl;
    TC1Cntl    = TC1.Cntl;
    TC2Cntl    = TC2.Cntl;
    TC3Cntl    = TC3.Cntl;
    TC4Cntl    = TC4.Cntl;
    TC5Cntl    = TC5.Cntl;
    ADCCntl    = ADC.Cntl;
    DACCCntl   = DACC.Cntl;
    PWMCntl    = PWM.Cntl;
    CRCCUCntl  = CRCCU.Cntl;
    ACCCntl    = ACC.Cntl;
    UDPCntl    = UDP.Cntl;

    components McuSleepC;
    McuSleepC.HplSam3Clock -> HplSam3sClockP;
}
