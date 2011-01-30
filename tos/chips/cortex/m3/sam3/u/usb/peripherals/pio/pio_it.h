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
/// !!!Purpose
/// 
/// Configuration and handling of interrupts on PIO status changes. The API
/// provided here have several advantages over the traditional PIO interrupt
/// configuration approach:
///    - It is highly portable
///    - It automatically demultiplexes interrupts when multiples pins have been
///      configured on a single PIO controller
///    - It allows a group of pins to share the same interrupt
/// 
/// However, it also has several minor drawbacks that may prevent from using it
/// in particular applications:
///    - It enables the clocks of all PIO controllers
///    - PIO controllers all share the same interrupt handler, which does the
///      demultiplexing and can be slower than direct configuration
///    - It reserves space for a fixed number of interrupts, which can be
///      increased by modifying the appropriate constant in pio_it.c.
///
/// !!!Usage
/// 
/// -# Initialize the PIO interrupt mechanism using PIO_InitializeInterrupts()
///    with the desired priority (0 ... 7).
/// -# Configure a status change interrupt on one or more pin(s) with
///    PIO_ConfigureIt().
/// -# Enable & disable interrupts on pins using PIO_EnableIt() and
///    PIO_DisableIt().
//------------------------------------------------------------------------------

#ifndef PIO_IT_H
#define PIO_IT_H

//------------------------------------------------------------------------------
//         Headers
//------------------------------------------------------------------------------

#include "pio.h"

//------------------------------------------------------------------------------
//         Global functions
//------------------------------------------------------------------------------

extern void PIO_InitializeInterrupts(unsigned int priority);

extern void PIO_ConfigureIt(const Pin *pPin, void (*handler)(const Pin *));

extern void PIO_EnableIt(const Pin *pPin);

extern void PIO_DisableIt(const Pin *pPin);

extern void PIO_IT_InterruptHandler(void);

#endif //#ifndef PIO_IT_H

