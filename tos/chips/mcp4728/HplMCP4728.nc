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
 * Hpl interface for Microchips MCP4728 12bit digital-to-analog converter
 * chip with EEPROM.
 *
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 */

#include "HplMCP4728.h"

// TODO(henrik) Add support for reading registers and all commands.

interface HplMCP4728
{
  /**
   * Checks the status of EEPROM programming activity.
   *
   * @return TRUE if there is no EEPROM activity.
   */
  command bool EEPROMisReady();

  /**
   * Sets the LDAC pin.
   *
   * @param high TRUE if LDAC should be high, FALSE for low.
   */
  command void setLDAC(bool high);

  /**
   * Sets the reference voltage for the D/A channels.
   *
   * @return SUCCESS if the references will be set and a
   *                 setRefereceDone event will be signaled.
   */
  command error_t setReference(bool a_internal,
                               bool b_internal,
                               bool c_internal,
                               bool d_internal);
  
  /**
   * Event that indicates the status of a setReference call.
   * 
   * @param e SUCCESS if the references were successfully set.
   */
  event void setRefereceDone(error_t e);

  /**
   * Sets the gain on the D/A channels.
   *
   * @param a TRUE for gain of 2,
   *          FALSE for gain 1 on channel a.
   * @param b TRUE for gain of 2,
   *          FALSE for gain 1 on channel b.
   * @param c TRUE for gain of 2,
   *          FALSE for gain 1 on channel c.
   * @param d TRUE for gain of 2,
   *          FALSE for gain 1 on channel d.
   *
   * @return SUCCESS if the gains will be set and a
   *                 setGainDone event will be signaled.
   */
  command error_t setGain(bool a,
                          bool b,
                          bool c,
                          bool d);
  
  /**
   * Event that indicates the status of a setGain call.
   * 
   * @param e SUCCESS if the gains were successfully set.
   */
  event void setGainDone(error_t e);

  /**
   * Sets power-down mode for the D/A channels.
   *
   * @return SUCCESS if the modes will be set and a
   *                 setPowerDownDone event will be signaled.
   */
  command error_t setPowerDown(MCP4728_POWER_DOWN a,
                               MCP4728_POWER_DOWN b,
                               MCP4728_POWER_DOWN c,
                               MCP4728_POWER_DOWN d);
  
  /**
   * Event that indicates the status of a setPowerDown call.
   * 
   * @param e SUCCESS if the power down modes were successfully set.
   */
  event void setPowerDownDone(error_t e);

  /**
   * Sets output voltage on the D/A channels. The input is the value
   * that should be written to the register.
   *
   * @return SUCCESS if the voltages will be set and a
   *                 setOutputVoltageDone event will be signaled.
   */
  command error_t setOutputVoltage(uint16_t a,
                                   uint16_t b,
                                   uint16_t c,
                                   uint16_t d);
  
  /**
   * Event that indicates the status of a setOutputVoltage call.
   * 
   * @param e SUCCESS if the voltages were successfully set.
   */
  event void setOutputVoltageDone(error_t e);

  /**
   * Specifies the settings of a D/A channel and stores the settings
   * in EEPROM. On SUCCESS a writeDACRegisterAndEEPROM event is signaled.
   *
   * @param channel The channel that the settings should be written to.
   * @param volt The output voltage of the channel. volt is the value
   *             that will be written to the register and EEPROM.
   * @param internal_vref TRUE for internal- and
   *                      FALSE for external reference.
   * @param power_down Power-Down mode of the channel.
   * @param gain TRUE for gain of 2 and FALSE for gain 1.
   * @param upload TRUE if the voltage output should be updated.
   *
   * @return SUCCESS if the settings will be set and a
   *                 writeDACRegisterAndEEPROMDone event will be signaled.
   */
  command error_t writeDACRegisterAndEEPROM(MCP4728_CHANNEL channel,
                                            uint16_t volt,
                                            bool internal_vref,
                                            MCP4728_POWER_DOWN power_down,
                                            bool gain,
                                            bool upload);
  
  /**
   * Event that indicates the status of a writeDACRegisterAndEEPROM call.
   * 
   * @param e SUCCESS if the call were successful.
   * @param channel The channel that the settings were applied to.
   */
  event void writeDACRegisterAndEEPROMDone(error_t e, MCP4728_CHANNEL channel);

}
