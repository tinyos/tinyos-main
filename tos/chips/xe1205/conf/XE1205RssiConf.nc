/* 
 * Copyright (c) 2006, Ecole Polytechnique Federale de Lausanne (EPFL),
 * Switzerland.
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
 * - Neither the name of the Ecole Polytechnique Federale de Lausanne (EPFL) 
 *   nor the names of its contributors may be used to 
 *   endorse or promote products derived from this software without 
 *   specific prior written permission.
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
 * ========================================================================
 */

/**
 * Interface for Rssi settings and measurements
 * on the XE1205 radio. 
 *
 * @author Henri Dubois-Ferriere
 */



interface XE1205RssiConf {

  /**
   * Enable RSSI measurements.
   *
   * @param on: 1 to enable, 0 to disable
   * @return SUCCESS if operation done ok, error status otherwise 
   */
    async command error_t setRssiMode(bool on);

  /** 
   * Return the returns the period (in us) between two successive rssi measurements, 
   * taking into account the current setting of the frequency deviation.
   *
   * @return rssi measure period.
   */
  async command uint16_t getRssiMeasurePeriod_us();

  /**
   * Set RSSI measurement points to low/high values at 
   * 
   * @param high: 1 for high range (-95, -90, -85 dBm)
   *              0 for low range (-110, -105, -100 dBm)
   * @return SUCCESS if operation done ok, error status otherwise 
   */
  async command error_t setRssiRange(bool high);

  /** 
   * Read RSSI value in 2 bits. RSSI block should be enabled before calling this.
   *
   * @param rssi Pointer to byte where rssi will be written.
   * @return SUCCESS if operation done ok, error status otherwise 
   * (in which case *rssi should not be used).
   */
  async command error_t getRssi(uint8_t* rssi);
}
