// $Id: HplAtm128TimerAsync.nc,v 1.2 2007-03-29 21:29:33 idgay Exp $
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
 *
 * @author David Gay
 */
interface HplAtm128TimerAsync
{
  /**
   * Read timer0 asynchronous status register (ASSR)
   * @return Current value of ASSR
   */
  async command Atm128Assr_t getAssr();

  /**
   * Set timer0 asynchronous status register (ASSR)
   * @param x New value for ASSR
   */
  async command void setAssr(Atm128Assr_t x);

  /**
   * Turn on timer 0 asynchronous mode
   */
  async command void setTimer0Asynchronous();

  /**
   * Check if control register TCCR0 is busy (should not be updated if true)
   * @return TRUE if TCCR0 is busy, FALSE otherwise (can be updated)
   */
  async command int controlBusy();

  /**
   * Check if compare register OCR0 is busy (should not be updated if true)
   * @return TRUE if OCR0 is busy, FALSE otherwise (can be updated)
   */
  async command int compareBusy();

  /**
   * Check if current timer value (TCNT0) is busy (should not be updated if true)
   * @return TRUE if TCNT0 is busy, FALSE otherwise (can be updated)
   */
  async command int countBusy();

}
