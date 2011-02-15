
/* "Copyright (c) 2000-2005 The Regents of the University of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

/**
 * @author Joe Polastre
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */

#include "msp430regtypes.h"

generic module HplMsp430GeneralIORenP(
				unsigned int port_in_addr,
				unsigned int port_out_addr,
				unsigned int port_dir_addr,
				unsigned int port_sel_addr,
				unsigned int port_ren_addr,
				uint8_t pin
				) @safe()
{
  provides interface HplMsp430GeneralIO as IO;
}
implementation
{
  #define PORTxIN (*TCAST(volatile TYPE_PORT_IN* ONE, port_in_addr))
  #define PORTx (*TCAST(volatile TYPE_PORT_OUT* ONE, port_out_addr))
  #define PORTxDIR (*TCAST(volatile TYPE_PORT_DIR* ONE, port_dir_addr))
  #define PORTxSEL (*TCAST(volatile TYPE_PORT_SEL* ONE, port_sel_addr))
  #define PORTxREN (*TCAST(volatile TYPE_PORT_REN* ONE, port_ren_addr))

  async command void IO.set() { atomic PORTx |= (0x01 << pin); }
  async command void IO.clr() { atomic PORTx &= ~(0x01 << pin); }
  async command void IO.toggle() { atomic PORTx ^= (0x01 << pin); }
  async command uint8_t IO.getRaw() { return PORTxIN & (0x01 << pin); }
  async command bool IO.get() { return (call IO.getRaw() != 0); }
  async command void IO.makeInput() { atomic PORTxDIR &= ~(0x01 << pin); }
  async command bool IO.isInput() { return (PORTxDIR & (0x01 << pin)) == 0; }
  async command void IO.makeOutput() { atomic PORTxDIR |= (0x01 << pin); }
  async command bool IO.isOutput() { return (PORTxDIR & (0x01 << pin)) != 0; }
  async command void IO.selectModuleFunc() { atomic PORTxSEL |= (0x01 << pin); }
  async command bool IO.isModuleFunc() { return (PORTxSEL & (0x01<<pin)) != 0; }
  async command void IO.selectIOFunc() { atomic PORTxSEL &= ~(0x01 << pin); }
  async command bool IO.isIOFunc() { return (PORTxSEL & (0x01<<pin)) == 0; }

  async command error_t IO.setResistor(uint8_t mode) {
    error_t rc = FAIL;
    atomic {
      if (0 == (PORTxDIR & (0x01 << pin))) {
        rc = SUCCESS;
        if (MSP430_PORT_RESISTOR_OFF == mode) {
          PORTxREN &= ~(0x01 << pin);
        } else if (MSP430_PORT_RESISTOR_PULLDOWN == mode) {
          PORTxREN |= (0x01 << pin);
          PORTx &= ~(0x01 << pin);
        } else if (MSP430_PORT_RESISTOR_PULLUP == mode) {
          PORTxREN |= (0x01 << pin);
          PORTx |= (0x01 << pin);
        } else {
          rc = EINVAL;
        }
      }
    }
    return rc;
  }

  async command uint8_t IO.getResistor()
  {
    uint8_t rc = MSP430_PORT_RESISTOR_INVALID;
    atomic {
      if (0 == (PORTxDIR & (0x01 << pin))) {
        if (PORTxREN & (0x01 << pin)) {
          if (PORTx & (0x01 << pin)) {
            rc = MSP430_PORT_RESISTOR_PULLUP;
          } else {
            rc = MSP430_PORT_RESISTOR_PULLDOWN;
          }
        } else {
          rc = MSP430_PORT_RESISTOR_OFF;
        }
      }
    }
    return rc;
  }
}
