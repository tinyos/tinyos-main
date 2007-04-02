// $Id: AntiTheftAppC.nc,v 1.2 2007-04-02 20:38:05 idgay Exp $
/*
 * Copyright (c) 2007 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Top-level configuration for node code for the AntiTheft demo app.
 * Instantiates the sensors, dissemination and collection services, and
 * does all the necessary wiring.
 *
 * @author David Gay
 */
#include "antitheft.h"

configuration AntiTheftAppC { }
implementation
{
  /* First wire the low-level services (booting, serial port, radio).
     There is no standard name for the actual radio component, so we use
     #ifdef to get the right one for the current platform. */
  components AntiTheftC, ActiveMessageC, MainC, LedsC,
    new TimerMilliC() as MyTimer;
#if defined(PLATFORM_MICA2)
  components CC1000CsmaRadioC as Radio;
#elif defined(PLATFORM_MICAZ)
  components CC2420ActiveMessageC as Radio;
#else
#error "The AntiTheft application is only supported for mica2 and micaz nodes"
#endif

  AntiTheftC.Boot -> MainC.Boot;
  AntiTheftC.Check -> MyTimer;
  AntiTheftC.Leds -> LedsC;
  AntiTheftC.RadioControl -> ActiveMessageC;
  AntiTheftC.LowPowerListening -> Radio;

  /* Instaniate, wire MTS300 sensor board components. */
  components new PhotoC(), new AccelXStreamC(), SounderC;

  AntiTheftC.Read -> PhotoC;
  AntiTheftC.ReadStream -> AccelXStreamC;
  AntiTheftC.Mts300Sounder -> SounderC;

  /* Instantiate and wire our settings dissemination service */
  components new DisseminatorC(settings_t, DIS_SETTINGS),

  AntiTheftC.SettingsValue -> DisseminatorC;

  /* Instantiate and wire our collection service for theft alerts */
  components CollectionC, new CollectionSenderC(COL_ALERTS) as AlertSender;

  AntiTheftC.AlertRoot -> AlertSender;
  AntiTheftC.CollectionControl -> CollectionC;

  /* Instantiate and wire our local radio-broadcast theft alert and 
     reception services */
  components new AMSenderC(AM_THEFT) as SendTheft, 
    new AMReceiverC(AM_THEFT) as ReceiveTheft;

  AntiTheftC.TheftSend -> SendTheft;
  AntiTheftC.TheftReceive -> ReceiveTheft;
}
