/*
 * Copyright (c) 2011 Lulea University of Technology
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
 * - Neither the name of the copyright holders nor the names of
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
 */

/**
 * Interface for the Maxim MAX116xx A/D converter chips.
 *
 * @param T The type that is needed to store a A/D value.
 *          uint8_t for MAX11600-MAX11605 and uint16_t for
 *          other versions.
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 */

#include "HplMAX116xx.h"

interface HplMAX116xx<T>
{
  /**
   * Sets the setup register.
   *
   * @param setup Register settings.
   * @return SUCCESS if the regiser will be set. A SUCCESS will
   *         always be followed by a setDone event.
   */
  command error_t setSetup(max116xx_setup_t setup);

  /**
   * Sets the configuration register.
   *
   * @param conf Register settings.
   * @param setup Register settings.
   * @return SUCCESS if the regiser will be set. A SUCCESS will
   *         always be followed by a setDone event.
   */ 
  command error_t setConfiguration(max116xx_configuration_t conf);

  /**
   * Sets both the setup and configuration registers.
   *
   * @param setup The setup register settings.
   * @param conf The configuration register settings.
   * @return SUCCESS if the regisers will be set. A SUCCESS will
   *         always be followed by a setDone event.
   */
  command error_t setSetupAndConfiguration(max116xx_setup_t setup, max116xx_configuration_t conf);

  /**
   * Measuress one or more A/D channels. The parameter values to this command
   * varies depending on the settings in the setup and configuration
   * registers.
   *
   * @param numChannels The number of A/D channels that should be read.
   * @param buf Memory where the values should be stored. This must
   *            be big enough to fit all values.
   * @return SUCCESS if the A/D values will be read. A SUCCESS will
   *         always be followed by a readAdcsDone event.
   */
  command error_t measureChannels(uint8_t numChannels, T* buf);

  /**
   * Event signalled after a set of the setup and/or configuration register.
   *
   * @param e SUCCESS if the set of the register was successfull.
   */
  event void setDone(error_t e);

  /**
   * Event signalled after a reading of one or more A/D channels.
   *
   * @param e SUCCESS will the reading was successfull.
   * @param numChannels Number of A/D channels read.
   * @param buf memory where the A/D values are stored.
   */
  event void measureChannelsDone(error_t e, uint8_t numChannels, T* buf);
}
