/// $Id: TestSleepC.nc,v 1.4 2006-12-12 18:22:51 vlahan Exp $

/**
 * "Copyright (c) 2005 Crossbow Technology, Inc. 
 *  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 * 
 * IN NO EVENT SHALL THE COPYRIGHT HOLDERS AND CONTRIBUTORS BE LIABLE TO ANY 
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF THE COPYRIGHT HOLDERS AND CONTRIBUTORS HAVE BEEN ADVISED OF THE 
 * POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE COPYRIGHT HOLDERS AND CONTRIBUTORS SPECIFICALLY DISCLAIM ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 * FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS ON AN 
 * "AS IS" BASIS, AND THE COPYRIGHT HOLDERS AND CONTRIBUTORS HAVE NO OBLIGATION
 * TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

/// @author Martin Turon <mturon@xbow.com>

/** 
 * TestSleep simple puts the processor into sleep mode and stays there.
 * The instananeous and average current should be ~20 uA on the ATmega128.
 */
configuration TestSleepC
{
}
implementation
{
  components MainC, TestSleepM, 
      HplSleepC;  // Low-level control just for test purposes

  TestSleepM -> MainC.Boot;

  TestSleepM.PowerManager -> HplSleepC;
}

