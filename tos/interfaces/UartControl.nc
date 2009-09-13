/* $Id: UartControl.nc,v 1.1 2009-09-13 23:55:32 scipio Exp $ */
/*
 * Copyright (c) 2009 Stanford University.
 * All rights reserved.
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
 * - Neither the name of the Stanford University nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
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

/**
 *  A hardware-independent (HIL) interface for configuring a UART.
 *  Allows setting speed, parity bits, stop bits, and duplex mode.
 *  Parameters are generally TinyOS enum constants, defined within a 
 *  chip's header files, such that using an unsupported setting
 *  will reference an undefined constant and lead to a compilation
 *  error.
 *
 *  @author Philip Levis
 *  @date   $Date: 2009-09-13 23:55:32 $
 */


interface UartControl {

  /** Set the UART speed for both reception and transmission.
    * This command should be called only when both reception
    * and transmission are disabled, either through a power interface
    * or setDuplexMode(). The parameter is a constant of the
    * form TOS_UART_XX, where XX is the speed, such as 
    * TOS_UART_57600. Different platforms support different speeds.
    * A compilation error on the constant indicates the platform
    * does not support that speed.
    *
    *  @param speed The UART speed to change to.
    */
  async command error_t setSpeed(uart_speed_t speed);

  /**
    * Returns the current UART speed. 
    */
  async command uart_speed_t speed();

  /**
    * Set the duplex mode of the UART. Valid modes are
    * TOS_UART_OFF, TOS_UART_RONLY, TOS_UART_TONLY, and
    * TOS_UART_DUPLEX. Some platforms may support only
    * a subset of these modes: trying to use an unsupported
    * mode is a compile-time error. The duplex mode setting
    * affects what kinds of interrupts the UART will issue.
    *
    *  @param duplex The duplex mode to change to.
    */
  async command error_t setDuplexMode(uart_duplex_t duplex);

  /**
    * Return the current duplex mode. 
    */
  async command uart_duplex_t duplexMode();

  /**
    * Set whether UART bytes have even parity bits, odd
    * parity bits, or no parity bits. This command should
    * only be called when both the receive and transmit paths
    * are disabled, either through a power control interface
    * or setDuplexMode. Valid parity settings are
    * TOS_PARITY_NONE, TOS_PARITY_EVEN, and TOS_PARITY_ODD.
    *
    *  @param parity The parity mode to change to.
    */

  async command error_t setParity(uart_parity_t parity);

  /**
    * Return the current parity mode.
    */
  async command uart_parity_t parity();

  /**
    * Enable stop bits. This command should only be called
    * when both the receive and transmits paths are disabled,
    * either through a power control interface or setDuplexMode.
    */
  async command error_t setStop();

  /**
    * Disable stop bits. This command should only be called
    * when both the receive and transmits paths are disabled,
    * either through a power control interface or setDuplexMode.
    */
  async command error_t setNoStop();

  /**
    * Returns whether stop bits are enabled.
    */
  async command bool stopBits();
}
