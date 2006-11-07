/* $Id: MotePlatformC.nc,v 1.3 2006-11-07 19:31:25 scipio Exp $
 * Copyright (c) 2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * The portion of a mica-family initialisation that is mote-specific.
 * For the mica2dot, we leave everything as inputs except as explicitly
 * configured otherwise by other components.
 * 
 * @author David Gay
 */
configuration MotePlatformC
{
  provides interface Init as PlatformInit;
  uses interface Init as SubInit;
}
implementation {
  components HplCC1000InitP;

  PlatformInit = HplCC1000InitP;
  SubInit = PlatformInit;
}
