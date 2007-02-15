// $Id: Mag.nc,v 1.1 2007-02-15 10:33:37 pipeng Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
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
   * Returns:  return SUCCESS.
   */
  event error_t gainAdjustXDone(bool result);

  /* Pot adjustment on the Y axis of the magnetometer is finished.
   * Returns:  return SUCCESS.
   */
  event error_t gainAdjustYDone(bool result);
}
