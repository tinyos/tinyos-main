/*
 * Copyright (c) 2016 Eric B. Decker
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 *
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 *
 * - Neither the name of the Stanford University nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL STANFORD
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * @author Eric B. Decker <cire831@gmail.com>
 *
 * This file is used to build an object that contains various types that
 * can be imported into GDB for messing with hardware on the msp432.
 *
 * To use from within gdb type "add-symbol-file <path/to/symbols.o> 0"
 *
 */

#include <stdint.h>
#include <msp432.h>

/*
 * msp432.h find the right chip header (msp432p401r.h) which also pulls in
 * the correct cmsis header (core_cm4.h).
 *
 * If __MSP432_DVRLIB_ROM__ is defined driverlib calls will be made to
 * the ROM copy on board the msp432 chip.
 */


/*
 * dma control block
 */
typedef struct {
  volatile void *src_end;
  volatile void *dest_end;
  volatile uint32_t control;
  volatile uint32_t pad;
} dma_cb_t;


/* pull in the type definitions.  allocates 4 bytes per (pointers) */
SCB_Type                    *__scb;
SCnSCB_Type                 *__scnscb;
SysTick_Type                *__systick;
NVIC_Type                   *__nvic;
ITM_Type                    *__itm;
DWT_Type                    *__dwt;
TPI_Type                    *__tpi;
CoreDebug_Type              *__cd;
MPU_Type                    *__mpu;
FPU_Type                    *__fpu;

RSTCTL_Type                 *__rstctl;
SYSCTL_Type                 *__sysctl;
SYSCTL_Boot_Type            *__sysboot;
CS_Type                     *__cs;
DIO_PORT_Odd_Interruptable_Type  *__p_odd;
DIO_PORT_Even_Interruptable_Type *__p_even;
PSS_Type                    *__pss;
PCM_Type                    *__pcm;
FLCTL_Type                  *__flctl;
DMA_Channel_Type            *__dmachn;
DMA_Control_Type            *__dmactl;
PMAP_COMMON_Type            *__pmap;
PMAP_REGISTER_Type          *__p1map;
CRC32_Type                  *__crc32;
AES256_Type                 *__aes256;
WDT_A_Type                  *__wdt;
Timer32_Type                *__t32;
Timer_A_Type                *__ta0;
RTC_C_Type                  *__rtc;
REF_A_Type                  *__ref;
ADC14_Type                  *__adc14;
EUSCI_A_Type                *_uca0;
EUSCI_B_Type                *_ucb0;
FL_BOOTOVER_MAILBOX_Type    *__bomb;
TLV_Type                    *__tlv;
dma_cb_t                    *__dma_cb;
