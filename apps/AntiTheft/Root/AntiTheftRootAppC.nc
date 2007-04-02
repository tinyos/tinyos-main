// $Id: AntiTheftRootAppC.nc,v 1.2 2007-04-02 20:38:06 idgay Exp $
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
 * Top-level configuration for root-node code for the AntiTheft demo app.
 * Instantiates the dissemination and collection services, and does all
 * the necessary wiring.
 *
 * @author David Gay
 */
#include "../Nodes/antitheft.h"

configuration AntiTheftRootAppC { }
implementation
{
  /* First wire the low-level services (booting, serial port, radio).
     There is no standard name for the actual radio component, so we use
     #ifdef to get the right one for the current platform. */
  components AntiTheftRootC, MainC, LedsC, ActiveMessageC, SerialActiveMessageC;
#if defined(PLATFORM_MICA2)
  components CC1000CsmaRadioC as Radio;
#elif defined(PLATFORM_MICAZ)
  components CC2420ActiveMessageC as Radio;
#else
#error "The AntiTheft application is only supported for mica2 and micaz nodes"
#endif

  AntiTheftRootC.Boot -> MainC;
  AntiTheftRootC.SerialControl -> SerialActiveMessageC;
  AntiTheftRootC.RadioControl -> ActiveMessageC;
  AntiTheftRootC.LowPowerListening -> Radio;
  AntiTheftRootC.Leds -> LedsC;

  /* Next, instantiate and wire a disseminator (to send settings) and a
     serial receiver (to receive settings from the PC) */
  components new DisseminatorC(settings_t, DIS_SETTINGS),
    new SerialAMReceiverC(AM_SETTINGS) as SettingsReceiver;

  AntiTheftRootC.SettingsReceive -> SettingsReceiver;
  AntiTheftRootC.SettingsUpdate -> DisseminatorC;

  /* Finally, instantiate and wire a collector (to receive theft alerts) and
     a serial sender (to send the alerts to the PC) */
  components CollectionC, new SerialAMSenderC(AM_ALERTS) as AlertsForwarder;

  AntiTheftRootC.CollectionControl -> CollectionC;
  AntiTheftRootC.RootControl -> CollectionC;
  AntiTheftRootC.AlertsReceive -> CollectionC.Receive[COL_ALERTS];
  AntiTheftRootC.AlertsForward -> AlertsForwarder;

}
