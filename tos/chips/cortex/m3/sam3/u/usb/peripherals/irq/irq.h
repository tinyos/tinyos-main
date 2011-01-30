/* ----------------------------------------------------------------------------
 *         ATMEL Microcontroller Software Support 
 * ----------------------------------------------------------------------------
 * Copyright (c) 2008, Atmel Corporation
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
 * Atmel's name may not be used to endorse or promote products derived from
 * this software without specific prior written permission.
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
 * ----------------------------------------------------------------------------
 */

//------------------------------------------------------------------------------
/// \unit
///
/// !Purpose
/// 
/// Methods and definitions for configuring interrupts.
/// 
/// !Usage
///
/// -# Configure an interrupt source using IRQ_ConfigureIT
/// -# Enable or disable interrupt generation of a particular source with
///    IRQ_EnableIT and IRQ_DisableIT.
///
/// \note Most of the time, peripheral interrupts must be also configured
/// inside the peripheral itself.
//------------------------------------------------------------------------------

#ifndef IRQ_H
#define IRQ_H

//------------------------------------------------------------------------------
//         Headers
//------------------------------------------------------------------------------

#include <board.h>
#if defined(cortexm3)
#include <cmsis/core_cm3.h>
#endif

//------------------------------------------------------------------------------
//         Definitions
//------------------------------------------------------------------------------
#if 0
#if defined(cortexm3)
#ifdef __NVIC_PRIO_BITS
#undef __NVIC_PRIO_BITS
#define __NVIC_PRIO_BITS           ((SCB->AIRCR & 0x700) >> 8) 
#endif
#endif
#endif

//------------------------------------------------------------------------------
//         Global functions
//------------------------------------------------------------------------------

extern void IRQ_ConfigureIT(unsigned int source,
                            unsigned int mode,         // mode for AIC, priority for NVIC
                            void( *handler )( void )); // ISR

extern void IRQ_EnableIT(unsigned int source);

extern void IRQ_DisableIT(unsigned int source);

#endif //#ifndef IRQ_H

