/* $Id: NoPinC.nc,v 1.2 2006-07-12 17:03:20 scipio Exp $
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
}

