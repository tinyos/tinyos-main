/* 
 * Copyright (c) 2014, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * @author Moksha Birk <birk@tkn.tu-berlin.de>
 * ========================================================================
 */

interface Jn516HWDebug
{
  /** 
   * Enable RX/TX pin toggling in the radios high power mode.
   *
   * DIO2 is high during RX
   * DIO3 is high during TX
   */
  async command void enableRadioHighPowerRxTxPins();

  /** 
   * Disable RX/TX pin toggling in the radios high power mode.
   */
  async command void disableRadioHighPowerRxTxPins();

  /**
   * Check whether the radio high power RX/TX pin toggling is enabled
   *
   * @returns TRUE If enabled
   *          FALSE Otherwise
   */
  async command bool getStateRadioHighPowerRxTxPins();

  /** 
   * Enable several pins to debug the radio state.
   *
   * DIO0      in_packet    Receiving a packet. (Probably after SFD)
   * DIO2      rx_sig       Incomoing IF (intermediate frequency) signal
   * DIO4:3    rx_gain      Internal receiver gain setting
   *                        0=13dB, 1=33dB, 2=61dB
   * DIO5      rx_rssi_en   Controls when RSSI measurements should be taken
   * DIO10:8   rx_adc_sel   Selects tap point for RSSI measurement
   * DIO13:11  rx_adc_rssi  RSSI value
   * DIO14     phy_on       Radio on/off indication
   * DIO15     phy_dir      Radio TX/RX indication
   * DIO16     phy_ready    PHY ready to TX or RX
   * DIO17     clk_16m      16MHz clock
   */
  async command void enableRadioChipTestPins();

  /** 
   * Disable several pins to debug the radio state.
   */
  async command void disableRadioChipTestPins();

  /**
   * Check whether the radio debug pins are enabled
   *
   * @returns TRUE If enabled
   *          FALSE Otherwise
   */
  async command bool getStateRadioChipTestPins();
}
