/// $Id: HplAtm128GeneralIOSlowPinP.nc,v 1.5 2008-02-16 05:30:24 regehr Exp $

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
 * Generic pin access for pins not mapped into I/O space (for which the
 * sbi, cbi instructions cannot be used). This can be used for ports F-G.
 *
 * @author Martin Turon <mturon@xbow.com>
 * @author David Gay <dgay@intel-research.net>
 */

generic module HplAtm128GeneralIOSlowPinP (uint8_t port_addr, 
				     uint8_t ddr_addr, 
				     uint8_t pin_addr,
				     uint8_t bit)
{
  provides interface GeneralIO as IO;
}
implementation
{
#define pin (*TCAST(volatile uint8_t * SINGLE NONNULL, pin_addr))
#define port (*TCAST(volatile uint8_t * SINGLE NONNULL, port_addr))
#define ddr (*TCAST(volatile uint8_t * SINGLE NONNULL, ddr_addr))

  inline async command bool IO.get()        { return READ_BIT (pin, bit); }
  inline async command void IO.set()        { atomic SET_BIT  (port, bit); }
  inline async command void IO.clr()        { atomic CLR_BIT  (port, bit); }
  inline async command void IO.toggle()     { atomic FLIP_BIT (port, bit); }
    
  inline async command void IO.makeInput()  { atomic CLR_BIT  (ddr, bit);  }
  inline async command bool IO.isInput() { return !READ_BIT(ddr, bit); }
  inline async command void IO.makeOutput() { atomic SET_BIT  (ddr, bit);  }
  inline async command bool IO.isOutput() { return READ_BIT(ddr, bit); }
}
