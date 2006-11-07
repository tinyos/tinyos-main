// $Id: MicaBusP.nc,v 1.3 2006-11-07 19:31:24 scipio Exp $
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
 * Internal component of the simplistic mica bus interface.
 * @author David Gay
 */

module MicaBusP {
  provides {
    interface MicaBusAdc as Adc0;
    interface MicaBusAdc as Adc1;
    interface MicaBusAdc as Adc2;
    interface MicaBusAdc as Adc3;
    interface MicaBusAdc as Adc4;
    interface MicaBusAdc as Adc5;
    interface MicaBusAdc as Adc6;
    interface MicaBusAdc as Adc7;
  }
}
implementation {
  async command uint8_t Adc0.getChannel() { return 0; }
  async command uint8_t Adc1.getChannel() { return 1; }
  async command uint8_t Adc2.getChannel() { return 2; }
  async command uint8_t Adc3.getChannel() { return 3; }
  async command uint8_t Adc4.getChannel() { return 4; }
  async command uint8_t Adc5.getChannel() { return 5; }
  async command uint8_t Adc6.getChannel() { return 6; }
  async command uint8_t Adc7.getChannel() { return 7; }
}
