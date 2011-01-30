/**
 * "Copyright (c) 2009 The Regents of the University of California.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

/**
 * @author Thomas Schmid
 */

#include "sam3unvichardware.h"

configuration HplNVICC
{
    provides
    {
        interface HplNVICCntl;
		interface Init;

        interface HplNVICInterruptCntl as SUPCInterrupt;  // SUPPLY CONTROLLER
        interface HplNVICInterruptCntl as RSTCInterrupt;  // RESET CONTROLLER
        interface HplNVICInterruptCntl as RTCInterrupt;   // REAL TIME CLOCK
        interface HplNVICInterruptCntl as RTTInterrupt;   // REAL TIME TIMER
        interface HplNVICInterruptCntl as WDGInterrupt;   // WATCHDOG TIMER
        interface HplNVICInterruptCntl as PMCInterrupt;   
        interface HplNVICInterruptCntl as EFC0Interrupt;  
        interface HplNVICInterruptCntl as EFC1Interrupt;  
        interface HplNVICInterruptCntl as DBGUInterrupt;  
        interface HplNVICInterruptCntl as HSMC4Interrupt; 
        interface HplNVICInterruptCntl as PIOAInterrupt;  // PARALLEL IO CONTROLLER A
        interface HplNVICInterruptCntl as PIOBInterrupt;  // PARALLEL IO CONTROLLER B
        interface HplNVICInterruptCntl as PIOCInterrupt;  // PARALLEL IO CONTROLLER C
        interface HplNVICInterruptCntl as US0Interrupt;   // USART 0
        interface HplNVICInterruptCntl as US1Interrupt;   // USART 1
        interface HplNVICInterruptCntl as US2Interrupt;   // USART 2
        interface HplNVICInterruptCntl as US3Interrupt;   // USART 3
        interface HplNVICInterruptCntl as MCI0Interrupt;  // MULTIMEDIA CARD INTERFACE
        interface HplNVICInterruptCntl as TWI0Interrupt;  
        interface HplNVICInterruptCntl as TWI1Interrupt;  
        interface HplNVICInterruptCntl as SPI0Interrupt;  // SERIAL PERIPHERAL INTERFACE
        interface HplNVICInterruptCntl as SSC0Interrupt;  // SERIAL SYNCHRONOUS CONTROLLER 0
        interface HplNVICInterruptCntl as TC0Interrupt;   // TIMER COUNTER 0
        interface HplNVICInterruptCntl as TC1Interrupt;   // TIMER COUNTER 1
        interface HplNVICInterruptCntl as TC2Interrupt;   // TIMER COUNTER 2
        interface HplNVICInterruptCntl as PWMCInterrupt;  // PULSE WIDTH MODULATION CONTROLLER
        interface HplNVICInterruptCntl as ADC12BInterrupt; // 12-BIT ADC CONTROLLER
        interface HplNVICInterruptCntl as ADCInterrupt;   // 10-BIT ADC CONTROLLER
        interface HplNVICInterruptCntl as HDMAInterrupt;  
        interface HplNVICInterruptCntl as UDPHSInterrupt; // USB DEVICE HIGH SPEED
    }
}

implementation
{
    components HplNVICCntlP,
        new HplNVICInterruptP(AT91C_ID_SUPC)  as HSUPC,
        new HplNVICInterruptP(AT91C_ID_RSTC)  as HRSTC,
        new HplNVICInterruptP(AT91C_ID_RTC)   as HRTC,
        new HplNVICInterruptP(AT91C_ID_RTT)   as HRTT,
        new HplNVICInterruptP(AT91C_ID_WDG)   as HWDG,
        new HplNVICInterruptP(AT91C_ID_PMC)   as HPMC,
        new HplNVICInterruptP(AT91C_ID_EFC0)  as HEFC0,
        new HplNVICInterruptP(AT91C_ID_EFC1)  as HEFC1,
        new HplNVICInterruptP(AT91C_ID_DBGU)  as HDBGU,
        new HplNVICInterruptP(AT91C_ID_HSMC4) as HHSMC4,
        new HplNVICInterruptP(AT91C_ID_PIOA)  as HPIOA,
        new HplNVICInterruptP(AT91C_ID_PIOB)  as HPIOB,
        new HplNVICInterruptP(AT91C_ID_PIOC)  as HPIOC,
        new HplNVICInterruptP(AT91C_ID_US0)   as HUS0,
        new HplNVICInterruptP(AT91C_ID_US1)   as HUS1,
        new HplNVICInterruptP(AT91C_ID_US2)   as HUS2,
        new HplNVICInterruptP(AT91C_ID_US3)   as HUS3,
        new HplNVICInterruptP(AT91C_ID_MCI0)  as HMCI0,
        new HplNVICInterruptP(AT91C_ID_TWI0)  as HTWI0,
        new HplNVICInterruptP(AT91C_ID_TWI1)  as HTWI1,
        new HplNVICInterruptP(AT91C_ID_SPI0)  as HSPI0,
        new HplNVICInterruptP(AT91C_ID_SSC0)  as HSSC0,
        new HplNVICInterruptP(AT91C_ID_TC0)   as HTC0,
        new HplNVICInterruptP(AT91C_ID_TC1)   as HTC1,
        new HplNVICInterruptP(AT91C_ID_TC2)   as HTC2,
        new HplNVICInterruptP(AT91C_ID_PWMC)  as HPWMC,
        new HplNVICInterruptP(AT91C_ID_ADC12B) as HADC12B,
        new HplNVICInterruptP(AT91C_ID_ADC)   as HADC,
        new HplNVICInterruptP(AT91C_ID_HDMA)  as HHDMA,
        new HplNVICInterruptP(AT91C_ID_UDPHS) as HUDPHS;


    HplNVICCntl = HplNVICCntlP;
    Init = HplNVICCntlP;

    SUPCInterrupt = HSUPC.Cntl;
    RSTCInterrupt = HRSTC.Cntl;
    RTCInterrupt = HRTC.Cntl;
    RTTInterrupt = HRTT.Cntl;
    WDGInterrupt = HWDG.Cntl;
    PMCInterrupt = HPMC.Cntl;
    EFC0Interrupt = HEFC0.Cntl;
    EFC1Interrupt = HEFC1.Cntl;
    DBGUInterrupt = HDBGU.Cntl;
    HSMC4Interrupt = HHSMC4.Cntl;
    PIOAInterrupt = HPIOA.Cntl;
    PIOBInterrupt = HPIOB.Cntl;
    PIOCInterrupt = HPIOC.Cntl;
    US0Interrupt = HUS0.Cntl;
    US1Interrupt = HUS1.Cntl;
    US2Interrupt = HUS2.Cntl;
    US3Interrupt = HUS3.Cntl;
    MCI0Interrupt = HMCI0.Cntl;
    TWI0Interrupt = HTWI0.Cntl;
    TWI1Interrupt = HTWI1.Cntl;
    SPI0Interrupt = HSPI0.Cntl;
    SSC0Interrupt = HSSC0.Cntl;
    TC0Interrupt = HTC0.Cntl;
    TC1Interrupt = HTC1.Cntl;
    TC2Interrupt = HTC2.Cntl;
    PWMCInterrupt = HPWMC.Cntl;
    ADC12BInterrupt = HADC12B.Cntl;
    ADCInterrupt = HADC.Cntl;
    HDMAInterrupt = HHDMA.Cntl;
    UDPHSInterrupt = HUDPHS.Cntl;
}
