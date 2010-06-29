// $Id: Mag.nc,v 1.5 2010-06-29 22:07:56 scipio Exp $

/*
 * Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 * - Neither the name of the University of California nor the names of
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/*
 * Authors:             Alec Woo
 * Date lase modified:  8/20/02
 *
 * The MagSetting inteface provides an asynchronous mechanism for
 * setting the gain offset for the Magnetometer on the mica sensorboard.
 * This is particularly useful in calibrating the offset of the Magnetometer
 * such that X and Y axis can stay in the center for idle signals.  
 * If not calibrated, the data you get may rail.  (railing means
 * the data either stays at the maximum (~785) or minimum (~240)). 
 *
 * The gain adjust has 256 steps ranging from 0 to 255.
 *
 */

/**
 * @author Alec Woo
 */

interface Mag {
  /* Effects:  adjust pot setting on the X axis of the magnetometer.
   * Returns:  return SUCCESS of FAILED.
   */
  command error_t gainAdjustX(uint8_t val);

  /* Effects:  adjust pot setting on the Y axis of the magnetometer.
   * Returns:  return SUCCESS of FAILED.
   */
  command error_t gainAdjustY(uint8_t val);

  /* Pot adjustment on the X axis of the magnetometer is finished.
   */
  event void gainAdjustXDone(error_t result);

  /* Pot adjustment on the Y axis of the magnetometer is finished.
   */
  event void gainAdjustYDone(error_t result);
}
