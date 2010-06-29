/*
 * Copyright (c) 2009 Communication Group and Eislab at
 * Lulea University of Technology
 *
 * Contact: Laurynas Riliskis, LTU
 * Mail: laurynas.riliskis@ltu.se
 * All rights reserved.
 *
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of Communication Group at Lulea University of Technology
 *   nor the names of its contributors may be used to endorse or promote
 *    products derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL STANFORD
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/*
 * Copyright (c) 2004-2005 Crossbow Technology, Inc.  All rights reserved.
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
 * - Neither the name of Crossbow Technology nor the names of
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
 */

/**
 * Basic interface to the hardware timers on the M16C/62p.
 * This interface provides four major groups of functionality:<ol>
 *      <li>Timer Value: get/set current time
 *      <li>Interrupt event, occurs when the timer under- or overflows.
 *      <li>Control of Interrupt: enableInterrupt/disableInterrupt/clearInterrupt...
 *      <li>Timer Initialization: turn on/off clock source
 * </ol>
 *
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 * @author Martin Turon <mturon@xbow.com>
 */
 
#include "M16c62pTimer.h"

interface HplM16c62pTimer
{
  /**
   * Turn on the clock.
   */
  async command void on();
  
  /**
   * Turn off the clock.
   */
  async command void off();

  /**
   * Check if the clock is on.
   */
  async command bool isOn();

  /** 
   * Get the current time.
   * @return  the current time.
   */
  async command uint16_t get();

  /** 
   * Set the current time.
   * @param t the time to set.
   */
  async command void set( uint16_t t );

  /**
   * Signalled on timer interrupt.
   */
  async event void fired();

  /**
   * Clear the interrupt flag.
   */
  async command void clearInterrupt();

  /**
   * Enable the interrupts.
   */
  async command void enableInterrupt();

  /**
   * Turns off interrupts.
   */
  async command void disableInterrupt();

  /** 
   * Checks if an interrupt has occured.
   * @return TRUE if interrupt has triggered.
   */
  async command bool testInterrupt();

  /** 
   * Checks if interrupts are on.
   * @return TRUE if interrups are enabled.
   */
  async command bool isInterruptOn();
  
  /**
   * Turn stop mode on/off while the timer is on.
   * @param allow If true the mcu can go into stop mode while
   *              timer is on if false the mcu can only use
   *              wait mode while timer is on.
   */
  async command void allowStopMode(bool allow);
}
