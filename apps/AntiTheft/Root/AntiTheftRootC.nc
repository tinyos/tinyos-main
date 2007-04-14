// $Id: AntiTheftRootC.nc,v 1.3 2007-04-14 00:35:07 gtolle Exp $
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
 * Root node code for the antitheft demo app, just acts as a bridge with the PC:
 * - disseminates settings received from the PC
 * - acts as a root forthe theft alert collection tree
 * - forwards theft alerts received from the collection tree to the PC
 *
 * @author David Gay
 */
module AntiTheftRootC
{
  uses
  {
    interface Boot;
    interface SplitControl as SerialControl;
    interface SplitControl as RadioControl;
    interface LowPowerListening;

    interface DisseminationUpdate<settings_t> as SettingsUpdate;
    interface Receive as SettingsReceive;

    interface StdControl as CollectionControl;
    interface StdControl as DisseminationControl;
    interface RootControl;
    interface Receive as AlertsReceive;
    interface AMSend as AlertsForward;

    interface Leds;
  }
}
implementation
{
  /* Start the radio and serial ports when booting */
  event void Boot.booted()
  {
    call SerialControl.start();
    call RadioControl.start();
  }

  event void SerialControl.startDone(error_t error) { }
  event void SerialControl.stopDone(error_t error) { }
  event void RadioControl.startDone(error_t error) {
    /* Once the radio has started, we can setup low-power listening, and
       start the collection and dissemination services. Additionally, we
       set ourselves as the (sole) root for the theft alert dissemination
       tree */
    if (error == SUCCESS)
      {
	call LowPowerListening.setLocalDutyCycle(200);
	call DisseminationControl.start();
	call CollectionControl.start();
	call RootControl.setRoot();
      }
  }
  event void RadioControl.stopDone(error_t error) { }

  /* When we receive new settings from the serial port, we disseminate
     them by calling the change command */
  event message_t *SettingsReceive.receive(message_t* msg, void* payload, uint8_t len)
  {
    settings_t *newSettings = payload;

    if (len == sizeof(*newSettings))
      {
	call Leds.led2Toggle();
	call SettingsUpdate.change(newSettings);
      }
    return msg;
  }

  message_t fwdMsg;
  bool fwdBusy;

  /* When we (as root of the collection tree) receive a new theft alert,
     we forward it to the PC via the serial port */
  event message_t *AlertsReceive.receive(message_t* msg, void* payload, 
					 uint8_t len)
  {
    alert_t *newAlert = payload;

    call Leds.led0Toggle();

    if (len == sizeof(*newAlert) && !fwdBusy)
      {
	/* Copy payload (newAlert) from collection system to our serial
	   message buffer (fwdAlert), then send our serial message */
	alert_t *fwdAlert = call AlertsForward.getPayload(&fwdMsg);

	*fwdAlert = *newAlert;
	if (call AlertsForward.send(AM_BROADCAST_ADDR, &fwdMsg, sizeof *fwdAlert) == SUCCESS)
	  fwdBusy = TRUE;
      }
    return msg;
  }

  event void AlertsForward.sendDone(message_t *msg, error_t error) {
    if (msg == &fwdMsg)
      fwdBusy = FALSE;
  }

}
