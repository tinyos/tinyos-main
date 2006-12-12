// $Id: HilTimerMilliC.nc,v 1.4 2006-12-12 18:23:44 vlahan Exp $
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
 * Dummy implementation to support the null platform.
 */

module HilTimerMilliC
{
  provides interface Init;
  provides interface Timer<TMilli> as TimerMilli[ uint8_t num ];
  provides interface LocalTime<TMilli>;
}
implementation
{

  command error_t Init.init() {
    return SUCCESS;
  }

  command void TimerMilli.startPeriodic[ uint8_t num ]( uint32_t dt ) {
  }

  command void TimerMilli.startOneShot[ uint8_t num ]( uint32_t dt ) {
  }

  command void TimerMilli.stop[ uint8_t num ]() {
  }

  command bool TimerMilli.isRunning[ uint8_t num ]() {
    return FALSE;
  }

  command bool TimerMilli.isOneShot[ uint8_t num ]() {
    return FALSE;
  }

  command void TimerMilli.startPeriodicAt[ uint8_t num ]( uint32_t t0, uint32_t dt ) {
  }

  command void TimerMilli.startOneShotAt[ uint8_t num ]( uint32_t t0, uint32_t dt ) {
  }

  command uint32_t TimerMilli.getNow[ uint8_t num ]() {
    return 0;
  }

  command uint32_t TimerMilli.gett0[ uint8_t num ]() {
    return 0;
  }

  command uint32_t TimerMilli.getdt[ uint8_t num ]() {
    return 0;
  }

  async command uint32_t LocalTime.get() {
    return 0;
  }
}
