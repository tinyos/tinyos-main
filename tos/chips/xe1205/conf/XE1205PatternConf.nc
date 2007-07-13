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
 * Interface for preamble detection settings 
 * on the XE1205 radio. 
 *
 * @author Henri Dubois-Ferriere
 */



interface XE1205PatternConf {

  /**
   * Set the length of the preamble searched by the XE1205 
   * pattern detection module.
   *
   * @param len patten length (1 <= len <= 4)
   * @return SUCCESS if operation done ok, error status otherwise 
   */
  async command error_t setDetectLen(uint8_t len);

  /**
   * Load a preamble pattern into the XE1205 pattern detection module.
   *
   * @param pattern pointer to pattern bytes.
   * @param len pattern length (1 <= len <= 4). Note that this may be larger 
   * than value set using setPatternLength; in this case the extra bytes 
   * are programmed into the radio but ignored by the pattern detection stage.
   * @return SUCCESS if operation done ok, error status otherwise 
   */
  async command error_t loadPattern(uint8_t* pattern, uint8_t len);
  async command error_t loadDataPatternHasBus();
  async command error_t loadAckPatternHasBus();

  /**
   * Set the number of bit errors accepted by the XE1205 
   * pattern detection module.
   *
   * @param nerrors max. number of errors accepted (0 <= len <= 3)
   * @return SUCCESS if operation done ok, error status otherwise 
   */
  async command error_t setDetectErrorTol(uint8_t nerrors);
}
