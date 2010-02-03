// $Id: CC1000CsmaP.nc,v 1.10 2010-02-03 16:50:27 sallai Exp $

/*
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

#include "message.h"
#include "crc.h"
#include "CC1000Const.h"
#include "Timer.h"

/**
 * A rewrite of the low-power-listening CC1000 radio stack.
 * This file contains the CSMA and low-power listening logic. Actual
 * packet transmission and reception is in SendReceive.
 * <p>
 * This code has some degree of platform-independence, via the
 * CC1000Control, RSSIADC and SpiByteFifo interfaces which must be provided
 * by the platform. However, these interfaces may still reflect some
 * particularities of the mica2 hardware implementation.
 *
 * @author Philip Buonadonna
 * @author Jaein Jeong
 * @author Joe Polastre
 * @author David Gay
 */
  
module CC1000CsmaP @safe() {
  provides {
    interface Init;
    interface SplitControl;
    interface CsmaControl;
    interface CsmaBackoff;
    interface LowPowerListening;
  }
  uses {
    interface Init as ByteRadioInit;
    interface StdControl as ByteRadioControl;
    interface ByteRadio;

    //interface PowerManagement;
    interface CC1000Control;
    interface CC1000Squelch;
    interface Random;
    interface Timer<TMilli> as WakeupTimer;
    interface BusyWait<TMicro, uint16_t>;

    interface ReadNow<uint16_t> as RssiNoiseFloor;
    interface ReadNow<uint16_t> as RssiCheckChannel;
    interface ReadNow<uint16_t> as RssiPulseCheck;
    async command void cancelRssi();
  }
}
implementation 
{
  enum {
    DISABLED_STATE,
    IDLE_STATE,
    RX_STATE,
    TX_STATE,
    POWERDOWN_STATE,
    PULSECHECK_STATE
  };

  enum {
    TIME_AFTER_CHECK =  30,
  };

  uint8_t radioState = DISABLED_STATE;
  struct {
    uint8_t ccaOff : 1;
    uint8_t txPending : 1;
  } f; // f for flags
  uint8_t count;
  uint8_t clearCount;

  int16_t macDelay;

  uint16_t sleepTime;

  uint16_t rssiForSquelch;

  task void setWakeupTask();

  cc1000_metadata_t * ONE getMetadata(message_t * ONE amsg) {
    return TCAST(cc1000_metadata_t * ONE, (uint8_t*)amsg + offsetof(message_t, footer) + sizeof(cc1000_footer_t));
  }
  
  void enterIdleState() {
    call cancelRssi();
    radioState = IDLE_STATE;
  }

  void enterIdleStateSetWakeup() {
    enterIdleState();
    post setWakeupTask();
  }

  void enterDisabledState() {
    call cancelRssi();
    radioState = DISABLED_STATE;
  }

  void enterPowerDownState() {
    call cancelRssi();
    radioState = POWERDOWN_STATE;
  }

  void enterPulseCheckState() {
    radioState = PULSECHECK_STATE;
    count = 0;
  }

  void enterRxState() {
    call cancelRssi();
    radioState = RX_STATE;
  }

  void enterTxState() {
    radioState = TX_STATE;
  }

  /* Basic radio power control */

  void radioOn() {
    call CC1000Control.coreOn();
    call BusyWait.wait(2000);
    call CC1000Control.biasOn();
    call BusyWait.wait(200);
    atomic call ByteRadio.listen();
  }

  void radioOff() {
    call CC1000Control.off();
    call ByteRadio.off();
  }

  void setPreambleLength(message_t * ONE msg);

  /* Initialisation, startup and stopping */
  /*--------------------------------------*/

  command error_t Init.init() {
    call ByteRadioInit.init();
    call CC1000Control.init();

    return SUCCESS;
  }

  task void startStopDone() {
    uint8_t s;

    // Save a byte of RAM by sharing start/stopDone task
    atomic s = radioState;
    if (s == DISABLED_STATE)
      signal SplitControl.stopDone(SUCCESS);
    else
      signal SplitControl.startDone(SUCCESS);
  }

  command error_t SplitControl.start() {
    atomic 
      if (radioState == DISABLED_STATE)
	{
	  call ByteRadioControl.start();
	  enterIdleStateSetWakeup();
	  f.txPending = FALSE;
	}
      else
	return SUCCESS;

    radioOn();

    post startStopDone();

    return SUCCESS;
  }

  command error_t SplitControl.stop() {
    atomic 
      {
	call ByteRadioControl.stop();
	enterDisabledState();
	radioOff();
      }
    call WakeupTimer.stop();
    post startStopDone();
    return SUCCESS;
  }

  /* Wakeup timer */
  /*-------------*/

  /* All timer setting code is placed in setWakeup, for consistency. */
  void setWakeup() {
    switch (radioState)
      {
      case IDLE_STATE:
	/* Timer already running means that we have a noise floor
	   measurement scheduled. If we just set a new alarm here, we
	   might indefinitely delay noise floor measurements if we're,
	   e,g, transmitting frequently. */
	if (!call WakeupTimer.isRunning())
	  if (call CC1000Squelch.settled())
	    {
	      if (sleepTime == 0)
		call WakeupTimer.startOneShot(CC1K_SquelchIntervalSlow);
	      else
		// timeout for receiving a message after an lpl check
		// indicates channel activity.
		call WakeupTimer.startOneShot(TIME_AFTER_CHECK);
	    }
	  else
	    call WakeupTimer.startOneShot(CC1K_SquelchIntervalFast);
	break;
      case PULSECHECK_STATE:
	// Radio warm-up time.
	call WakeupTimer.startOneShot(1);
	break;
      case POWERDOWN_STATE:
	// low-power listening check interval
	call WakeupTimer.startOneShot(sleepTime);
	break;
      }
  }

  task void setWakeupTask() {
    atomic setWakeup();
  }

  event void WakeupTimer.fired() {
    atomic 
      {
	switch (radioState)
	  {
	  case IDLE_STATE:
	    /* If we appear to be receiving a packet we don't check the
	       noise floor. For LPL, this means that going to sleep will
	       be delayed by another TIME_AFTER_CHECK ms. */
	    if (!call ByteRadio.syncing())
	      {
		call cancelRssi();
		call RssiNoiseFloor.read();
	      }
	    break;

	  case POWERDOWN_STATE:
	    // Turn radio on, wait for 1ms
	    enterPulseCheckState();
	    call CC1000Control.biasOn();
	    break;

	  case PULSECHECK_STATE:
	    // Switch to RX mode and get RSSI output
	    call CC1000Control.rxMode();
	    call RssiPulseCheck.read();
	    call BusyWait.wait(80);
	    return; // don't set wakeup timer
	  }
	setWakeup();
      }
  }

  /* Low-power listening stuff */
  /*---------------------------*/

  /* Should we go to sleep, or turn the radio fully on? */
  task void sleepCheck() {
    bool turnOn = FALSE;

    atomic
      if (f.txPending || !sleepTime)
	{
	  if (radioState == PULSECHECK_STATE || radioState == POWERDOWN_STATE)
	    {
	      enterIdleStateSetWakeup();
	      turnOn = TRUE;
	    }
	}
      else if (call CC1000Squelch.settled() && !call ByteRadio.syncing())
	{
	  radioOff();
	  enterPowerDownState();
	  setWakeup();
	}

    if (turnOn)
      radioOn();
  }

  task void adjustSquelch();

  async event void RssiPulseCheck.readDone(error_t result, uint16_t data) {
    if (result != SUCCESS)
      {
	/* Just give up on this interval. */
	post sleepCheck();
	return;
      }

    /* We got some RSSI data for our LPL check. Decide whether to:
       - go back to sleep (quiet)
       - wake up (channel active)
       - get more RSSI data
    */
    if (data > call CC1000Squelch.get() - (call CC1000Squelch.get() >> 2))
      {
	post sleepCheck();
	// don't be too agressive (ignore really quiet thresholds).
	if (data < call CC1000Squelch.get() + (call CC1000Squelch.get() >> 3))
	  {
	    // adjust the noise floor level, go back to sleep.
	    rssiForSquelch = data;
	    post adjustSquelch();
	  }
      }
    else if (count++ > 5)
      {
	//go to the idle state since no outliers were found
	enterIdleStateSetWakeup();
	call ByteRadio.listen();
      }
    else
      {
	call RssiPulseCheck.read();
	call BusyWait.wait(80);
      }
  }

  /* CSMA */
  /*------*/

  event void ByteRadio.rts(message_t * ONE msg) {
    atomic
      {
	f.txPending = TRUE;

	if (radioState == POWERDOWN_STATE)
	  post sleepCheck();
	if (!f.ccaOff)
	  macDelay = signal CsmaBackoff.initial(call ByteRadio.getTxMessage());
	else
	  macDelay = 1;

	setPreambleLength(msg);
      }
  }

  async event void ByteRadio.sendDone() {
    f.txPending = FALSE;
    enterIdleStateSetWakeup();
  }

  void congestion() {
    macDelay = signal CsmaBackoff.congestion(call ByteRadio.getTxMessage());
  }

  async event void ByteRadio.idleByte(bool preamble) {
    if (f.txPending)
      {
	if (!f.ccaOff && preamble)
	  congestion();
	else if (macDelay && !--macDelay)
	  {
	    call cancelRssi();
	    count = 0;
	    call RssiCheckChannel.read();
	  }
      }
  }

  async event void RssiCheckChannel.readDone(error_t result, uint16_t data) {
    if (result != SUCCESS)
      {
	/* We'll retry the transmission at the next SPI event. */
	atomic macDelay = 1;
	return;
      }

    count++;
    if (data > call CC1000Squelch.get() + CC1K_SquelchBuffer)
      clearCount++;
    else
      clearCount = 0;

    // if the channel is clear or CCA is disabled, GO GO GO!
    if (clearCount >= 1 || f.ccaOff)
      {
	enterTxState();
	call ByteRadio.cts();
      }
    else if (count == CC1K_MaxRSSISamples)
      congestion();
    else 
      call RssiCheckChannel.read();
  }

  /* Message being received. We basically just go inactive. */
  /*--------------------------------------------------------*/

  async event void ByteRadio.rx() {
    enterRxState();
  }

  async event void ByteRadio.rxDone() {
    if (radioState == RX_STATE)
      enterIdleStateSetWakeup();
  }

  /* Noise floor */
  /*-------------*/

  task void adjustSquelch() {
    uint16_t squelchData;

    atomic squelchData = rssiForSquelch;
    call CC1000Squelch.adjust(squelchData);
  }

  async event void RssiNoiseFloor.readDone(error_t result, uint16_t data) {
    if (result != SUCCESS)
      {
	/* We just ignore failed noise floor measurements */
	post sleepCheck();
	return;
      }

    rssiForSquelch = data;
    post adjustSquelch();
    post sleepCheck();
  }

  /* Options */
  /*---------*/

  async command error_t CsmaControl.enableCca() {
    atomic f.ccaOff = FALSE;
    return SUCCESS;
  }

  async command error_t CsmaControl.disableCca() {
    atomic f.ccaOff = TRUE;
    return SUCCESS;
  }

  /* Default MAC backoff parameters */
  /*--------------------------------*/

  default async event uint16_t CsmaBackoff.initial(message_t *m) { 
    // initially back off [1,32] bytes (approx 2/3 packet)
    return (call Random.rand16() & 0x1F) + 1;
  }

  default async event uint16_t CsmaBackoff.congestion(message_t *m) { 
    return (call Random.rand16() & 0xF) + 1;
  }

  /* LowPowerListening setup */
  /* ----------------------- */

  uint16_t validateSleepInterval(uint16_t sleepIntervalMs) {
    if (sleepIntervalMs < CC1K_LPL_MIN_INTERVAL)
      return 0;
    else if (sleepIntervalMs > CC1K_LPL_MAX_INTERVAL)
      return CC1K_LPL_MAX_INTERVAL;
    else
      return sleepIntervalMs;
  }

  uint16_t dutyToSleep(uint16_t dutyCycle) {
    /* Scaling factors on CC1K_LPL_CHECK_TIME and dutyCycle are identical */
    uint16_t interval = (1000 * CC1K_LPL_CHECK_TIME) / dutyCycle;

    return interval < CC1K_LPL_MIN_INTERVAL ? 0 : interval;
  }

  uint16_t sleepToDuty(uint16_t sleepInterval) {
    if (sleepInterval < CC1K_LPL_MIN_INTERVAL)
      return 10000;

    /* Scaling factors on CC1K_LPL_CHECK_TIME and dutyCycle are identical */
    return (1000 * CC1K_LPL_CHECK_TIME) / sleepInterval;
  }

  command void LowPowerListening.setLocalWakeupInterval(uint16_t s) {
    sleepTime = validateSleepInterval(s);
  }

  command uint16_t LowPowerListening.getLocalWakeupInterval() {
    return sleepTime;
  }

  command void LowPowerListening.setRemoteWakeupInterval(message_t *msg, uint16_t sleepIntervalMs) {
    cc1000_metadata_t *meta = getMetadata(msg);

    meta->strength_or_preamble = -(int16_t)validateSleepInterval(sleepIntervalMs) - 1;
  }

  command uint16_t LowPowerListening.getRemoteWakeupInterval(message_t *msg) {
    cc1000_metadata_t *meta = getMetadata(msg);

    if (meta->strength_or_preamble >= 0)
      return sleepTime;
    else
      return -(meta->strength_or_preamble + 1);
  }

  void setPreambleLength(message_t * ONE msg) {
    cc1000_metadata_t *meta = getMetadata(msg);
    uint16_t s;
    uint32_t plen;

    if (meta->strength_or_preamble >= 0)
      s = sleepTime;
    else
      s = -(meta->strength_or_preamble + 1);
    meta->strength_or_preamble = 0; /* Destroy setting */

    if (s == 0)
      plen = 6;
    else
      plen = ((s * 614UL) >> 8) + 22; /* ~ s * 2.4 + 22 */
    call ByteRadio.setPreambleLength(plen);
  }
}
