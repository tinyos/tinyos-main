/*									tab:4
 *
 *
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
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
 */
/**
 * Low Power Listening control interface
 *
 * @author Joe Polastre
 */
interface LowPowerListening
{
  /**
   * Set the current Low Power Listening mode.
   * Setting the LPL mode sets both the check interval and preamble length.
   * The listening mode can only be set while the radio is stopped.
   *
   * Modes include:
   *  0 = Radio fully on
   *  1 = 10ms check interval
   *  2 = 25ms check interval
   *  3 = 50ms check interval
   *  4 = 100ms check interval (recommended)
   *  5 = 200ms check interval
   *  6 = 400ms check interval
   *  7 = 800ms check interval
   *  8 = 1600ms check interval
   *
   * @param mode the mode number
   * @return SUCCESS if the mode was successfully changed, FAIL otherwise
   */
  async command error_t setListeningMode(uint8_t mode);

  /**
   * Get the current Low Power Listening mode
   * @return mode number (see SetListeningMode)
   */
  async command uint8_t getListeningMode();

  /**
   * Set the transmit mode.  This allows for hybrid schemes where
   * the transmit mode is different than the receive mode.
   * Use SetListeningMode first, then change the mode with SetTransmitMode.
   *
   * @param mode mode number (see SetListeningMode)
   * @return SUCCESS if the mode was successfully changed, FAIL otherwise
   */
  async command error_t setTransmitMode(uint8_t mode);

  /**
   * Get the current Low Power Listening transmit mode
   * @return mode number (see SetListeningMode)
   */
  async command uint8_t getTransmitMode();

  /**
   * Set the preamble length of outgoing packets. Note that this overrides
   * the value set by setListeningMode or setTransmitMode.
   *
   * @param bytes length of the preamble in bytes
   * @return SUCCESS if the preamble length was successfully changed, FAIL
   *   otherwise
   */
  async command error_t setPreambleLength(uint16_t bytes);

  /**
   * Get the preamble length of outgoing packets
   *
   * @return length of the preamble in bytes
   */
  async command uint16_t getPreambleLength();

  /**
   * Set the check interval (time between waking up and sampling
   * the radio for activity in low power listening). The sleep time
   * can only be changed if low-power-listening is enabled 
   * (setListeningMode called with a non-zero value).
   *
   * @param ms check interval in milliseconds
   * @return SUCCESS if the check interval was successfully changed,
   *   FAIL otherwise.
   */
  async command error_t setCheckInterval(uint16_t ms);

  /**
   * Get the check interval currently used by low power listening
   *
   * @return length of the check interval in milliseconds
   */
  async command uint16_t getCheckInterval();
}
