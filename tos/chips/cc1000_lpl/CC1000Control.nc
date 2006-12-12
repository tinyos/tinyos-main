/* $Id: CC1000Control.nc,v 1.4 2006-12-12 18:23:05 vlahan Exp $
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
/**
 * CC1000 internal radio control interface.
 * @author Philip Buonadonna
 * @aythor Jaein Jeong
 */
interface CC1000Control
{
  /**
   * Initialise the radio to its default state.
   */
  command void init();

  /**
   * Tune the radio to one of the frequencies available in the CC1K_Params
   * table.  Calling Tune will allso reset the rfpower and LockVal
   * selections to the table values.
   * 
   * @param freq The index into the CC1K_Params table that holds the
   * desired preset frequency parameters.
   */
  command void tunePreset(uint8_t freq); 

  /**
   * Tune the radio to a given frequency. Since the CC1000 uses a digital
   * frequency synthesizer, it cannot tune to just an arbitrary frequency.
   * This routine will determine the closest achievable channel, compute
   * the necessary parameters and tune the radio.
   * 
   * @param The desired channel frequency, in Hz.
   * 
   * @return The actual computed channel frequency, in Hz.  A return value
   * of '0' indicates that no frequency was computed and the radio was not
   * tuned.
   */
  command uint32_t tuneManual(uint32_t DesiredFreq);

  /**
   * Turn the CC1000 off
   */
  async command void off();

  /**
   * Shift the CC1000 Radio into transmit mode.
   */
  async command void txMode();

  /**
   * Shift the CC1000 Radio in receive mode.
   */
  async command void rxMode();

  /**
   * Turn off the bias power on the CC1000 radio, but leave the core and
   * crystal oscillator powered.  This will result in approximately a 750
   * uA power savings.
   */
  async command void coreOn();			

  /**
   * Turn the bias power on. This function must be followed by a call to
   * either rxMode() or txMode() to place the radio in a recieve/transmit
   * state respectively. There is approximately a 200us delay when
   * restoring bias power.
   */
  async command void biasOn();

  /**
   * Set the transmit RF power value.  The input value is simply an
   * arbitrary index that is programmed into the CC1000 registers.  Consult
   * the CC1000 datasheet for the resulting power output/current
   * consumption values.
   *
   * @param power A power index between 1 and 255.
   */
  command void setRFPower(uint8_t power);	

  /**
   * Get the present RF power index.
   *
   * @return The power index value.
   */
  command uint8_t getRFPower();		

  /** 
   * Select the signal to monitor at the CHP_OUT pin of the CC1000.  See
   * the CC1000 data sheet for the available signals.
   * 
   * @param LockVal The index of the signal to monitor at the CHP_OUT pin
   */
  command void selectLock(uint8_t LockVal); 

  /**
   * Get the binary value from the CHP_OUT pin.  Analog signals cannot be
   * read using function.
   *
   * @return 1 - Pin is high or 0 - Pin is low
   */
  command uint8_t getLock();

  /**
   * Returns whether the present frequency set is using high-side LO
   * injection or not.  This information is used to determine if the data
   * from the CC1000 needs to be inverted or not.
   *
   * @return TRUE if high-side LO injection is being used (i.e. data does NOT need to be inverted
   * at the receiver.
   */
  command bool getLOStatus();
}
