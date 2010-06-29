// $Id: HplAtm128GeneralIOPinP.nc,v 1.5 2010-06-29 22:07:43 scipio Exp $

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

/// @author Martin Turon <mturon@xbow.com>
/// @author David Gay <dgay@intel-research.net>

/**
 * Generic pin access for pins mapped into I/O space (for which the sbi, cbi
 * instructions give atomic updates). This can be used for ports A-E.
 */
generic module HplAtm128GeneralIOPinP (uint8_t port_addr, 
				 uint8_t ddr_addr, 
				 uint8_t pin_addr,
				 uint8_t bit)
{
  provides interface GeneralIO as IO;
}
implementation
{
#define pin  pin_addr
#define port port_addr
#define ddr  ddr_addr

  inline async command bool IO.get()        { return READ_BIT (port, bit); }
  inline async command void IO.set()        {
    dbg("Pins", "Setting bit %i of port %i.\n", (int)bit, (int)port);
    SET_BIT  (port, bit);
  }
  inline async command void IO.clr()        { CLR_BIT  (port, bit); }
  inline async command void IO.toggle()     { atomic FLIP_BIT (port, bit); }
    
  inline async command void IO.makeInput()  { CLR_BIT  (ddr, bit);  }
  inline async command void IO.makeOutput() { SET_BIT  (ddr, bit);  }
  inline async command bool IO.isInput() { return !READ_BIT  (ddr, bit);  }
  inline async command bool IO.isOutput() { return READ_BIT  (ddr, bit);  }
}

