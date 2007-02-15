/* $Id: PhotoTempDeviceP.nc,v 1.1 2007-02-15 10:33:38 pipeng Exp $
 * Copyright (c) 2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Internal component for basicsb photodiode. Arbitrates access to the photo
 * diode and automatically turns it on or off based on user requests.
 * 
 * @author David Gay
 */

#include "mts300.h"

configuration PhotoTempDeviceP 
{
  provides 
  {
    interface Init;
    interface StdControl;
    interface ResourceConfigure as PhotoResourceConfigure;
    interface Atm128AdcConfig as PhotoAtm128AdcConfig;
    interface ResourceConfigure as TempResourceConfigure;
    interface Atm128AdcConfig as TempAtm128AdcConfig;    
  }
}
implementation 
{
  components PhotoTempP, MicaBusC, HplAtm128GeneralIOC as Pins;
//  components new FcfsArbiterC(MTS3X0_PHOTO_TEMP) as Arbiter;  
  components LedsC, NoLedsC;
  
  Init = PhotoTempP;
  StdControl = PhotoTempP;

  PhotoResourceConfigure = PhotoTempP.PhotoResourceConfigure;
  PhotoAtm128AdcConfig   = PhotoTempP.PhotoAtm128AdcConfig;

  TempResourceConfigure  = PhotoTempP.TempResourceConfigure;
  TempAtm128AdcConfig    = PhotoTempP.TempAtm128AdcConfig;

  PhotoTempP.LightPower  -> Pins.PortE5;
  PhotoTempP.TempPower   -> Pins.PortE6;
  PhotoTempP.SensorAdc -> MicaBusC.Adc1;
  
  DEBUG_LEDS(PhotoTempP);
}
