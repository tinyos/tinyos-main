// $Id: AntiTheftC.nc,v 1.4 2007-09-13 23:10:19 scipio Exp $
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
 * Main code for the anti theft demo application.
 *
 * @author David Gay
 */
module AntiTheftC
{
  uses {
    interface Timer<TMilli> as Check;
    interface Read<uint16_t>;
    interface ReadStream<uint16_t>;
    interface Leds;
    interface Boot;
    interface Mts300Sounder;
    interface DisseminationValue<settings_t> as SettingsValue;
    interface Send as AlertRoot;
    interface StdControl as CollectionControl;
    interface StdControl as DisseminationControl;
    interface SplitControl as RadioControl;
    interface LowPowerListening;
    interface AMSend as TheftSend;
    interface Receive as TheftReceive;
  }
}
implementation
{
  enum {
    /* Threshold for considering mote in a dark place */
    DARK_THRESHOLD = 200, 

    /* Amount of time warning leds should stay on (in checkInterval counts) */
    WARNING_TIME = 3,

    /* Number of acceleration samples to collect */
    ACCEL_SAMPLES = 10,

    /* Interval between acceleration samples (us) */
    ACCEL_INTERVAL = 10000
  };

  settings_t settings;
  message_t alertMsg, theftMsg;
  uint16_t ledTime; /* Time left until leds switched off */
  uint16_t accelSamples[ACCEL_SAMPLES];

  /********* LED handling **********/

  /* Warn that some error occurred */
  void errorLed() {
    ledTime = WARNING_TIME;
    call Leds.led2On();
  }

  /* Notify user that settings changed */
  void settingsLed() {
    ledTime = WARNING_TIME;
    call Leds.led1On();
  }

  /* Turn on bright red light! (LED) */
  void theftLed() {
    ledTime = WARNING_TIME;
    call Leds.led0On();
  }

  /* Time-out leds. Called every checkInterval */
  void updateLeds() {
    if (ledTime && !--ledTime)
      {
	call Leds.led0Off();
	call Leds.led1Off();
	call Leds.led2Off();
      }
  }

  /* Check result code and report error if a problem occurred */
  void check(error_t ok) {
    if (ok != SUCCESS)
      errorLed();
  }

  /* Report theft, based on current settings */
  void theft() {
    if (settings.alert & ALERT_LEDS)
      theftLed();
    if (settings.alert & ALERT_SOUND)
      call Mts300Sounder.beep(100);
    if (settings.alert & ALERT_RADIO)
      /* A local broadcast with no payload */
      check(call TheftSend.send(AM_BROADCAST_ADDR, &theftMsg, 0));
    if (settings.alert & ALERT_ROOT)
      {
	/* Report the identity of this node, using the collection protocol */

	/* Get the payload part of alertMsg and fill in our data */
	alert_t *newAlert = call AlertRoot.getPayload(&alertMsg, sizeof(alert_t));
	if (newAlert != NULL) {
	  newAlert->stolenId = TOS_NODE_ID;
	  /* and send it... */
	  check(call AlertRoot.send(&alertMsg, sizeof *newAlert));
	}
      }
  }

  /* We have nothing to do after messages are sent */
  event void AlertRoot.sendDone(message_t *msg, error_t ok) { }
  event void TheftSend.sendDone(message_t *msg, error_t ok) { }

  /* We've received a theft alert from a neighbour. Turn on the theft warning
     light! */
  event message_t *TheftReceive.receive(message_t* msg, void* payload, uint8_t len) {
    theftLed();
    /* We don't need to hold on to the message buffer, so just return the
       received buffer */
    return msg;
  }
  
  /* At boot time, start the periodic timer and the radio */
  event void Boot.booted() {
    errorLed();
    settings.alert = DEFAULT_ALERT;
    settings.detect = DEFAULT_DETECT;

    call Check.startPeriodic(DEFAULT_CHECK_INTERVAL);
    call RadioControl.start();
  }

  /* Radio started. Now start the collection protocol and set the
     radio to a 2% low-power-listening duty cycle */
  event void RadioControl.startDone(error_t ok) {
    if (ok == SUCCESS)
      {
	call DisseminationControl.start();
	call CollectionControl.start();
	call LowPowerListening.setLocalDutyCycle(200);
      }
    else
      errorLed();
  }

  event void RadioControl.stopDone(error_t ok) { }

  /* New settings received, update our local copy */
  event void SettingsValue.changed() {
    const settings_t *newSettings = call SettingsValue.get();

    settingsLed();
    settings = *newSettings;
    /* Switch to the new check interval */
    call Check.startPeriodic(newSettings->checkInterval);
  }

  /* Every check interval: update leds, check for theft based on current
     settings */
  event void Check.fired() {
    updateLeds();

    if (settings.detect & DETECT_DARK)
      call Read.read(); /* Initiate light sensor read */
    if (settings.detect & DETECT_ACCEL)
      {
	/* To sample acceleration, we first register our buffer
	   (postBuffer). Then we trigger sampling at the desired
	   interval (read) */
	call ReadStream.postBuffer(accelSamples, ACCEL_SAMPLES);
	call ReadStream.read(ACCEL_INTERVAL);
      }
  }

  /* Light sample completed. Check if it indicates theft */
  event void Read.readDone(error_t ok, uint16_t val) {
    if (ok == SUCCESS && val < DARK_THRESHOLD)
      theft(); /* ALERT! ALERT! */
  }

  /* A deferred task to check the acceleration data and detect theft. */
  task void checkAcceleration() {
    uint8_t i;
    uint16_t avg;
    uint32_t var;

    /* We check for theft by checking whether the variance of the sample
       (in mysterious acceleration units) is > 4 */

    for (avg = 0, i = 0; i < ACCEL_SAMPLES; i++)
      avg += accelSamples[i];
    avg /= ACCEL_SAMPLES;

    for (var = 0, i = 0; i < ACCEL_SAMPLES; i++)
      {
	int16_t diff = accelSamples[i] - avg;
	var += diff * diff;
      }

    if (var > 4 * ACCEL_SAMPLES)
      theft(); /* ALERT! ALERT! */
  }

  /* The acceleration read completed. Post the task that will check for
     theft. We defer this somewhat cpu-intensive computation to avoid
     having the current task run for too long. */
  event void ReadStream.readDone(error_t ok, uint32_t usActualPeriod) {
    if (ok == SUCCESS)
      post checkAcceleration();
    else
      errorLed();
  }

  /* The current sampling buffer is full. If we were using several buffers,
     we would switch between them here. */
  event void ReadStream.bufferDone(error_t ok, uint16_t *buf, uint16_t count) { }
}
