/* $Id: NoPinC.nc,v 1.3 2006-11-07 19:31:28 scipio Exp $
 * Copyright (c) 2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Dummy pin component.
 *
 * @author David Gay
 */

generic module NoPinC()
{
  provides interface GeneralIO;
}
implementation
{
  async command bool GeneralIO.get() { return 0; }
  async command void GeneralIO.set() { }
  async command void GeneralIO.clr() { }
  async command void GeneralIO.toggle() { }
  async command void GeneralIO.makeInput() { }
  async command void GeneralIO.makeOutput() { }
  async command bool GeneralIO.isInput() { }
  async command bool GeneralIO.isOutput() { }
}

