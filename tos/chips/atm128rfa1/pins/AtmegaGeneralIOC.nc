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
 * @author Miklos Maroti
 */

configuration AtmegaGeneralIOC
{
	provides
	{
		interface GeneralIO as PortA0;
		interface GeneralIO as PortA1;
		interface GeneralIO as PortA2;
		interface GeneralIO as PortA3;
		interface GeneralIO as PortA4;
		interface GeneralIO as PortA5;
		interface GeneralIO as PortA6;
		interface GeneralIO as PortA7;

		interface GeneralIO as PortB0;
		interface GeneralIO as PortB1;
		interface GeneralIO as PortB2;
		interface GeneralIO as PortB3;
		interface GeneralIO as PortB4;
		interface GeneralIO as PortB5;
		interface GeneralIO as PortB6;
		interface GeneralIO as PortB7;

		interface GeneralIO as PortC0;
		interface GeneralIO as PortC1;
		interface GeneralIO as PortC2;
		interface GeneralIO as PortC3;
		interface GeneralIO as PortC4;
		interface GeneralIO as PortC5;
		interface GeneralIO as PortC6;
		interface GeneralIO as PortC7;

		interface GeneralIO as PortD0;
		interface GeneralIO as PortD1;
		interface GeneralIO as PortD2;
		interface GeneralIO as PortD3;
		interface GeneralIO as PortD4;
		interface GeneralIO as PortD5;
		interface GeneralIO as PortD6;
		interface GeneralIO as PortD7;

		interface GeneralIO as PortE0;
		interface GeneralIO as PortE1;
		interface GeneralIO as PortE2;
		interface GeneralIO as PortE3;
		interface GeneralIO as PortE4;
		interface GeneralIO as PortE5;
		interface GeneralIO as PortE6;
		interface GeneralIO as PortE7;

		interface GeneralIO as PortF0;
		interface GeneralIO as PortF1;
		interface GeneralIO as PortF2;
		interface GeneralIO as PortF3;
		interface GeneralIO as PortF4;
		interface GeneralIO as PortF5;
		interface GeneralIO as PortF6;
		interface GeneralIO as PortF7;

		interface GeneralIO as PortG0;
		interface GeneralIO as PortG1;
		interface GeneralIO as PortG2;
		interface GeneralIO as PortG3;
		interface GeneralIO as PortG4;
		interface GeneralIO as PortG5;
	}
}

implementation
{
	components new AtmegaGeneralIOP((uint8_t)&PORTA, (uint8_t)&DDRA, (uint8_t)&PINA) as PortA;

	PortA0 = PortA.Pin[0];
	PortA1 = PortA.Pin[1];
	PortA2 = PortA.Pin[2];
	PortA3 = PortA.Pin[3];
	PortA4 = PortA.Pin[4];
	PortA5 = PortA.Pin[5];
	PortA6 = PortA.Pin[6];
	PortA7 = PortA.Pin[7];

	components new AtmegaGeneralIOP((uint8_t)&PORTB, (uint8_t)&DDRB, (uint8_t)&PINB) as PortB;

	PortB0 = PortB.Pin[0];
	PortB1 = PortB.Pin[1];
	PortB2 = PortB.Pin[2];
	PortB3 = PortB.Pin[3];
	PortB4 = PortB.Pin[4];
	PortB5 = PortB.Pin[5];
	PortB6 = PortB.Pin[6];
	PortB7 = PortB.Pin[7];

	components new AtmegaGeneralIOP((uint8_t)&PORTC, (uint8_t)&DDRC, (uint8_t)&PINC) as PortC;

	PortC0 = PortC.Pin[0];
	PortC1 = PortC.Pin[1];
	PortC2 = PortC.Pin[2];
	PortC3 = PortC.Pin[3];
	PortC4 = PortC.Pin[4];
	PortC5 = PortC.Pin[5];
	PortC6 = PortC.Pin[6];
	PortC7 = PortC.Pin[7];

	components new AtmegaGeneralIOP((uint8_t)&PORTD, (uint8_t)&DDRD, (uint8_t)&PIND) as PortD;

	PortD0 = PortD.Pin[0];
	PortD1 = PortD.Pin[1];
	PortD2 = PortD.Pin[2];
	PortD3 = PortD.Pin[3];
	PortD4 = PortD.Pin[4];
	PortD5 = PortD.Pin[5];
	PortD6 = PortD.Pin[6];
	PortD7 = PortD.Pin[7];

	components new AtmegaGeneralIOP((uint8_t)&PORTE, (uint8_t)&DDRE, (uint8_t)&PINE) as PortE;

	PortE0 = PortE.Pin[0];
	PortE1 = PortE.Pin[1];
	PortE2 = PortE.Pin[2];
	PortE3 = PortE.Pin[3];
	PortE4 = PortE.Pin[4];
	PortE5 = PortE.Pin[5];
	PortE6 = PortE.Pin[6];
	PortE7 = PortE.Pin[7];

	components new AtmegaGeneralIOP((uint8_t)&PORTF, (uint8_t)&DDRF, (uint8_t)&PINF) as PortF;

	PortF0 = PortF.Pin[0];
	PortF1 = PortF.Pin[1];
	PortF2 = PortF.Pin[2];
	PortF3 = PortF.Pin[3];
	PortF4 = PortF.Pin[4];
	PortF5 = PortF.Pin[5];
	PortF6 = PortF.Pin[6];
	PortF7 = PortF.Pin[7];

	components new AtmegaGeneralIOP((uint8_t)&PORTG, (uint8_t)&DDRG, (uint8_t)&PING) as PortG;

	PortG0 = PortG.Pin[0];
	PortG1 = PortG.Pin[1];
	PortG2 = PortG.Pin[2];
	PortG3 = PortG.Pin[3];
	PortG4 = PortG.Pin[4];
	PortG5 = PortG.Pin[5];
}
