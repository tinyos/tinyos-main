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
 * @author Martin Turon <mturon@xbow.com>
 * @author David Gay <dgay@intel-research.net>
 * @author Miklos Maroti
 */

generic module AtmegaGeneralIOP(uint8_t port_addr, 
				uint8_t ddr_addr, 
				uint8_t pin_addr) @safe()
{
	provides interface GeneralIO as Pin[uint8_t bit];
}

implementation
{
#define pin (*TCAST(volatile uint8_t * ONE, pin_addr))
#define port (*TCAST(volatile uint8_t * ONE, port_addr))
#define ddr (*TCAST(volatile uint8_t * ONE, ddr_addr))

	inline async command bool Pin.get[uint8_t bit]() { return (pin & (1<<bit)) != 0; }
	inline async command void Pin.set[uint8_t bit]() { port |= 1<<bit; }
	inline async command void Pin.clr[uint8_t bit]() { port &= ~(1<<bit); }
	inline async command void Pin.toggle[uint8_t bit]() { atomic port ^= 1 <<bit; }

	inline async command void Pin.makeInput[uint8_t bit]() { ddr &= ~(1<<bit); }
	inline async command bool Pin.isInput[uint8_t bit]() { return (ddr & (1<<bit)) == 0; }
	inline async command void Pin.makeOutput[uint8_t bit]() { ddr |= 1<<bit; }
	inline async command bool Pin.isOutput[uint8_t bit]() { return (ddr & (1<<bit)) != 0;}
}
