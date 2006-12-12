// $Id: Atm128Interrupt.h,v 1.4 2006-12-12 18:23:03 vlahan Exp $

/*
 * Copyright (c) 2004-2005 Crossbow Technology, Inc.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL CROSSBOW TECHNOLOGY OR ANY OF ITS LICENSORS BE LIABLE TO 
 * ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL 
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF CROSSBOW OR ITS LICENSOR HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH 
 * DAMAGE. 
 *
 * CROSSBOW TECHNOLOGY AND ITS LICENSORS SPECIFICALLY DISCLAIM ALL WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY 
 * AND FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE PROVIDED HEREUNDER IS 
 * ON AN "AS IS" BASIS, AND NEITHER CROSSBOW NOR ANY LICENSOR HAS ANY 
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR 
 * MODIFICATIONS.
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

