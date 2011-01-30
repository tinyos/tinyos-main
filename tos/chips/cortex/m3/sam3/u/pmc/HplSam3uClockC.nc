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
 * This is the main configuration for the low-layer clock module.
 *
 * @author Thomas Schmid
 */

configuration HplSam3uClockC
{
    provides
    {
        interface HplSam3Clock;

        interface HplSam3PeripheralClockCntl as RTCPCCntl   ;
        interface HplSam3PeripheralClockCntl as RTTPPCntl   ;
        interface HplSam3PeripheralClockCntl as WDGPPCntl   ;
        interface HplSam3PeripheralClockCntl as PMCPPCntl   ;
        interface HplSam3PeripheralClockCntl as EFC0PPCntl  ;
        interface HplSam3PeripheralClockCntl as EFC1PPCntl  ;
        interface HplSam3PeripheralClockCntl as DBGUPPCntl  ;
        interface HplSam3PeripheralClockCntl as HSMC4PPCntl ;
        interface HplSam3PeripheralClockCntl as PIOAPPCntl  ;
        interface HplSam3PeripheralClockCntl as PIOBPPCntl  ;
        interface HplSam3PeripheralClockCntl as PIOCPPCntl  ;
        interface HplSam3PeripheralClockCntl as US0PPCntl   ;
        interface HplSam3PeripheralClockCntl as US1PPCntl   ;
        interface HplSam3PeripheralClockCntl as US2PPCntl   ;
        interface HplSam3PeripheralClockCntl as US3PPCntl   ;
        interface HplSam3PeripheralClockCntl as MCI0PPCntl  ;
        interface HplSam3PeripheralClockCntl as TWI0PPCntl  ;
        interface HplSam3PeripheralClockCntl as TWI1PPCntl  ;
        interface HplSam3PeripheralClockCntl as SPI0PPCntl  ;
        interface HplSam3PeripheralClockCntl as SSC0PPCntl  ;
        interface HplSam3PeripheralClockCntl as TC0PPCntl   ;
        interface HplSam3PeripheralClockCntl as TC1PPCntl   ;
        interface HplSam3PeripheralClockCntl as TC2PPCntl   ;
        interface HplSam3PeripheralClockCntl as PWMCPPCntl  ;
        interface HplSam3PeripheralClockCntl as ADC12BPPCntl;
        interface HplSam3PeripheralClockCntl as ADCPPCntl   ;
        interface HplSam3PeripheralClockCntl as HDMAPPCntl  ;
        interface HplSam3PeripheralClockCntl as UDPHSPPCntl ;
    }
}
implementation
{
#define PMC_PC_BASE 0x400e0410

    components HplSam3uClockP,
               new HplSam3PeripheralClockP(AT91C_ID_RTC   ,PMC_PC_BASE ) as RTC,
               new HplSam3PeripheralClockP(AT91C_ID_RTT   ,PMC_PC_BASE ) as RTT,
               new HplSam3PeripheralClockP(AT91C_ID_WDG   ,PMC_PC_BASE ) as WDG,
               new HplSam3PeripheralClockP(AT91C_ID_PMC   ,PMC_PC_BASE ) as PMC,
               new HplSam3PeripheralClockP(AT91C_ID_EFC0  ,PMC_PC_BASE ) as EFC0,
               new HplSam3PeripheralClockP(AT91C_ID_EFC1  ,PMC_PC_BASE ) as EFC1,
               new HplSam3PeripheralClockP(AT91C_ID_DBGU  ,PMC_PC_BASE ) as DBGU,
               new HplSam3PeripheralClockP(AT91C_ID_HSMC4 ,PMC_PC_BASE ) as HSMC4,
               new HplSam3PeripheralClockP(AT91C_ID_PIOA  ,PMC_PC_BASE ) as PIOA,
               new HplSam3PeripheralClockP(AT91C_ID_PIOB  ,PMC_PC_BASE ) as PIOB,
               new HplSam3PeripheralClockP(AT91C_ID_PIOC  ,PMC_PC_BASE ) as PIOC,
               new HplSam3PeripheralClockP(AT91C_ID_US0   ,PMC_PC_BASE ) as US0,
               new HplSam3PeripheralClockP(AT91C_ID_US1   ,PMC_PC_BASE ) as US1,
               new HplSam3PeripheralClockP(AT91C_ID_US2   ,PMC_PC_BASE ) as US2,
               new HplSam3PeripheralClockP(AT91C_ID_US3   ,PMC_PC_BASE ) as US3,
               new HplSam3PeripheralClockP(AT91C_ID_MCI0  ,PMC_PC_BASE ) as MCI0,
               new HplSam3PeripheralClockP(AT91C_ID_TWI0  ,PMC_PC_BASE ) as TWI0,
               new HplSam3PeripheralClockP(AT91C_ID_TWI1  ,PMC_PC_BASE ) as TWI1,
               new HplSam3PeripheralClockP(AT91C_ID_SPI0  ,PMC_PC_BASE ) as SPI0,
               new HplSam3PeripheralClockP(AT91C_ID_SSC0  ,PMC_PC_BASE ) as SSC0,
               new HplSam3PeripheralClockP(AT91C_ID_TC0   ,PMC_PC_BASE ) as TC0,
               new HplSam3PeripheralClockP(AT91C_ID_TC1   ,PMC_PC_BASE ) as TC1,
               new HplSam3PeripheralClockP(AT91C_ID_TC2   ,PMC_PC_BASE ) as TC2,
               new HplSam3PeripheralClockP(AT91C_ID_PWMC  ,PMC_PC_BASE ) as PWMC,
               new HplSam3PeripheralClockP(AT91C_ID_ADC12B,PMC_PC_BASE ) as ADC12B,
               new HplSam3PeripheralClockP(AT91C_ID_ADC   ,PMC_PC_BASE ) as ADC,
               new HplSam3PeripheralClockP(AT91C_ID_HDMA  ,PMC_PC_BASE ) as HDMA,
               new HplSam3PeripheralClockP(AT91C_ID_UDPHS ,PMC_PC_BASE ) as UDPHS;

    HplSam3Clock = HplSam3uClockP;

    RTCPCCntl   = RTC.Cntl;
    RTTPPCntl   = RTT.Cntl;
    WDGPPCntl   = WDG.Cntl;
    PMCPPCntl   = PMC.Cntl;
    EFC0PPCntl  = EFC0.Cntl;
    EFC1PPCntl  = EFC1.Cntl;
    DBGUPPCntl  = DBGU.Cntl;
    HSMC4PPCntl = HSMC4.Cntl;
    PIOAPPCntl  = PIOA.Cntl;
    PIOBPPCntl  = PIOB.Cntl;
    PIOCPPCntl  = PIOC.Cntl;
    US0PPCntl   = US0.Cntl;
    US1PPCntl   = US1.Cntl;
    US2PPCntl   = US2.Cntl;
    US3PPCntl   = US3.Cntl;
    MCI0PPCntl  = MCI0.Cntl;
    TWI0PPCntl  = TWI0.Cntl;
    TWI1PPCntl  = TWI1.Cntl;
    SPI0PPCntl  = SPI0.Cntl;
    SSC0PPCntl  = SSC0.Cntl;
    TC0PPCntl   = TC0.Cntl;
    TC1PPCntl   = TC1.Cntl;
    TC2PPCntl   = TC2.Cntl;
    PWMCPPCntl  = PWMC.Cntl;
    ADC12BPPCntl= ADC12B.Cntl;
    ADCPPCntl   = ADC.Cntl;
    HDMAPPCntl  = HDMA.Cntl;
    UDPHSPPCntl = UDPHS.Cntl;

  components McuSleepC;
  McuSleepC.HplSam3Clock -> HplSam3uClockP;
}
