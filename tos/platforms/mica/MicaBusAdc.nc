// $Id: MicaBusAdc.nc,v 1.3 2006-11-07 19:31:24 scipio Exp $
/*
 * Copyright (c) 2005-2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * A simplistic beginning to providing a standard interface to the mica-family
 * 51-pin bus. Just provides the PW0-PW7 digital I/O pins.
 */

interface MicaBusAdc {
  /**
   * Return the A/D channel number to use for one of the ADCn pins.
   */
  async command uint8_t getChannel();
}
