// $Id: HplAtm128TimerAsync.nc,v 1.1 2007-11-05 20:36:43 sallai Exp $
/*
 * Copyright (c) 2007 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/*
 * Copyright (c) 2007, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 */

/**
 * HPL Interface to Atmega1281 8-bit asynchronous timer control registers
 *
 * @author David Gay
 * @author Janos Sallai <janos.sallai@vanderbilt.edu>
 */
interface HplAtm128TimerAsync
{
  /**
   * Read timer2 asynchronous status register (ASSR)
   * @return Current value of ASSR
   */
  async command Atm128_ASSR_t getAssr();

  /**
   * Set timer2 asynchronous status register (ASSR)
   * @param x New value for ASSR
   */
  async command void setAssr(Atm128_ASSR_t x);

  /**
   * Turn on timer 2 asynchronous mode
   */
  async command void setTimer2Asynchronous();

  /**
   * Check if control register TCCR2A is busy (should not be updated if true)
   * @return TRUE if TCCR2A is busy, FALSE otherwise (can be updated)
   */
  async command int controlABusy();

  /**
   * Check if control register TCCR2B is busy (should not be updated if true)
   * @return TRUE if TCCR2B is busy, FALSE otherwise (can be updated)
   */
  async command int controlBBusy();

  /**
   * Check if compare register OCR2A is busy (should not be updated if true)
   * @return TRUE if OCR2A is busy, FALSE otherwise (can be updated)
   */
  async command int compareABusy();

  /**
   * Check if compare register OCR2B is busy (should not be updated if true)
   * @return TRUE if OCR2B is busy, FALSE otherwise (can be updated)
   */
  async command int compareBBusy();

  /**
   * Check if current timer value (TCNT2) is busy (should not be updated if true)
   * @return TRUE if TCNT2 is busy, FALSE otherwise (can be updated)
   */
  async command int countBusy();

}
