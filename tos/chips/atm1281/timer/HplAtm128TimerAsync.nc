// $Id: HplAtm128TimerAsync.nc,v 1.2 2010-06-29 22:07:43 scipio Exp $
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
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holder nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
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
