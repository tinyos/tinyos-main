// $Id: Atm128Calibrate.nc,v 1.3 2006-11-07 19:30:45 scipio Exp $
/*
 * Copyright (c) 2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * This interface provides functions to compute ATmega128 configuration
 * values that are clock-rate dependent. These include:<ul>
 * <li>the ADC prescaler value necessary for full precision
 * <li>values for the UBRR registers to achieve a specific baud rate
 * <li>any adjustment necessary to values passed to some platform-provided
 *   AlarmMicroXXC components to get more accurate timing
 * <li>the number of cycles per 1/32768s (a typical implementation of this
 *   interface will measure this value at boot time and use it to compute
 *   the values above)
 * </ul>
 *
 * @author David Gay
 */

interface Atm128Calibrate {
  /**
   * Return CPU cycles per 1/32768s.
   * @return CPU cycles.
   */
  async command uint16_t cyclesPerJiffy();

  /**
   * Convert n microseconds into a value suitable for use with
   * AlarmMicro32C Alarms.
   * @param n Time in microseconds.
   * @return AlarmMicro argument that best approximates n microseconds.
   */
  async command uint32_t calibrateMicro(uint32_t n);

  /**
   * Convert values used by AlarmMicro32C Alarms into actual microseconds.
   * @param n A time expressed in AlarmMicro time units.
   * @return Time in microseconds that corresponds to AlarmMicro argument n.
   */
  async command uint32_t actualMicro(uint32_t n);

  /**
   * Return the smallest ADC prescaler value which guaranteers full
   * ADC precision.
   * @return ADC prescaler value.
   */
  async command uint8_t adcPrescaler();

  /**
   * Return the value to use for the baudrate register to achieve a
   * particular baud rate. Assumes U2X=1 (the USART is being run at
   * double speed).
   */
  async command uint16_t baudrateRegister(uint32_t baudrate);
}
