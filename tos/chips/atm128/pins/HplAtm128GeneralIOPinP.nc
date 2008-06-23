/// $Id: HplAtm128GeneralIOPinP.nc,v 1.7 2008-06-23 20:25:15 regehr Exp $

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

/**
 * Generic pin access for pins mapped into I/O space (for which the sbi, cbi
 * instructions give atomic updates). This can be used for ports A-E.
 *
 * @author Martin Turon <mturon@xbow.com>
 * @author David Gay <dgay@intel-research.net>
 */
generic module HplAtm128GeneralIOPinP (uint8_t port_addr, 
				 uint8_t ddr_addr, 
				 uint8_t pin_addr,
				 uint8_t bit) @safe()
{
  provides interface GeneralIO as IO;
}
implementation
{
#define pin (*TCAST(volatile uint8_t * ONE, pin_addr))
#define port (*TCAST(volatile uint8_t * ONE, port_addr))
#define ddr (*TCAST(volatile uint8_t * ONE, ddr_addr))

  inline async command bool IO.get()        { return READ_BIT (pin, bit); }
  inline async command void IO.set()        { SET_BIT  (port, bit); }
  inline async command void IO.clr()        { CLR_BIT  (port, bit); }
  async command void IO.toggle()     { atomic FLIP_BIT (port, bit); }
    
  inline async command void IO.makeInput()  { CLR_BIT  (ddr, bit);  }
  inline async command bool IO.isInput() { return !READ_BIT(ddr, bit); }
  inline async command void IO.makeOutput() { SET_BIT  (ddr, bit);  }
  inline async command bool IO.isOutput() { return READ_BIT(ddr, bit); }
}

