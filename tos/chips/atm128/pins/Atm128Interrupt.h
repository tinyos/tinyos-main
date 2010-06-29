// $Id: Atm128Interrupt.h,v 1.5 2010-06-29 22:07:43 scipio Exp $

/*
 * Copyright (c) 2004-2005 Crossbow Technology, Inc.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of Crossbow Technology nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

// @author Martin Turon <mturon@xbow.com>

#ifndef _H_Atm128Interrupt_h
#define _H_Atm128Interrupt_h

//====================== External Interrupts ===============================

/* Sleep modes */
enum {
  ATM128_IRQ_ON_LOW    = 0, 
  ATM128_IRQ_ON_CHANGE = 1, 
  ATM128_IRQ_ON_FALL   = 2, 
  ATM128_IRQ_ON_RISE   = 3, 
};

/* Interrupt Control Register */
typedef struct
{
  uint8_t isc0  : 2;  //!< Interrupt Sense Control
  uint8_t isc1  : 2;  //!< Interrupt Sense Control
  uint8_t isc2  : 2;  //!< Interrupt Sense Control
  uint8_t isc3  : 2;  //!< Interrupt Sense Control
} Atm128_InterruptCtrl_t;

typedef Atm128_InterruptCtrl_t Atm128_EICRA_t;   //!< Ext Interrupt Control A
typedef Atm128_InterruptCtrl_t Atm128_EICRB_t;   //!< Ext Interrupt Control B

typedef uint8_t Atm128_EIMSK_t;         //!< External Interrupt Mask Register
typedef uint8_t Atm128_EIFR_t;          //!< External Interrupt Flag Register

#endif //_H_Atm128Interrupt_h

