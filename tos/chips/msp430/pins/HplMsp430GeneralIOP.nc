
/* Copyright (c) 2000-2005 The Regents of the University of California.  
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
 * - Neither the name of the copyright holder nor the names of
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
 * @author Joe Polastre
 */

#include "msp430regtypes.h"

generic module HplMsp430GeneralIOP(
				uint8_t port_in_addr,
				uint8_t port_out_addr,
				uint8_t port_dir_addr,
				uint8_t port_sel_addr,
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
}
