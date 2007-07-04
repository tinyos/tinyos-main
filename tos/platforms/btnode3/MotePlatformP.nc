/* $Id: MotePlatformP.nc,v 1.5 2007-07-04 22:02:45 beutel Exp $
 * Copyright (c) 2006 ETH Zurich.
 * Copyright (c) 2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * The porttion of a mica-family initialisation that is btnode3-specific.
 * 
 * @author David Gay
 * @author Jan Beutel
 */
module MotePlatformP
{
  provides interface Init as PlatformInit;
  uses interface GeneralIO as SerialIdPin;
  uses interface Init as SubInit;
}
implementation {

  command error_t PlatformInit.init() {
    // Pull C I/O port pins low to initialize LED's to off
    // Turn in cc1000 and IO power 
    // Turn off bluetooth power
    // Set port C as output only
    PORTC = 0xb0;
    DDRC = 0xff;
    
    // TODO: release Bluetooth reset pin
    
    //btnode3: set latch_select PB5 for now
    PORTB = 0x20;
    DDRB = 0x20;
    

    // Prevent sourcing current
//    call SerialIdPin.makeI0xffnput(); 
//    call SerialIdPin.clr();

    return call SubInit.init();
  }

  default command error_t SubInit.init() {
    return SUCCESS;
  }
}
