/**
 * Copyright (c) 2009 DEXMA SENSORS SL
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
 * - Neither the name of the DEXMA SENSORS SL nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * DEXMA SENSORS SL OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */


/**
 * This code is extracted from code examples at TI website.
 *
 * 
 * @author: Xavier Orduña (xorduna@dexmatech.com)
 */


#ifndef MS430XDCOCALIB_H
#define MS430XDCOCALIB_H

#define DELTA_1MHZ	244
#define	DELTA_8MHZ	1953
#define	DELTA_12MHZ	2930
#define DELTA_16MHZ	3906


unsigned char CAL_DATA[8];
//volatile unsigned int k;
int dcoj;

char *Flash_ptrA;
void Set_DCO(unsigned int Delta);


void dco_flash()
{
	//WDTCTL = WDTPW + WDTHOLD;
	for (dcoj = 0; dcoj < 0xfffe; dcoj++);
	P5OUT=0x00;	
	
	P5DIR=0x21;
	//P5DIR=0x20;
	P5OUT=0x01;	
	
	P2SEL |= 0x02;
	P2DIR |= 0x02;

	dcoj = 0;
	Set_DCO(DELTA_16MHZ);                     // Set DCO and obtain constants
	CAL_DATA[dcoj++] = DCOCTL;
	CAL_DATA[dcoj++] = BCSCTL1;

	Set_DCO(DELTA_12MHZ);                     // Set DCO and obtain constants
	CAL_DATA[dcoj++] = DCOCTL;
	CAL_DATA[dcoj++] = BCSCTL1;

	Set_DCO(DELTA_8MHZ);                      // Set DCO and obtain constants
	CAL_DATA[dcoj++] = DCOCTL;
	CAL_DATA[dcoj++] = BCSCTL1;

	Set_DCO(DELTA_1MHZ);                      // Set DCO and obtain constants
	CAL_DATA[dcoj++] = DCOCTL;
	CAL_DATA[dcoj++] = BCSCTL1;

	Flash_ptrA = (char *)0x10C0;              // Point to beginning of seg A
	FCTL2 = FWKEY + FSSEL0 + FN1;             // MCLK/3 for Flash Timing Generator
	FCTL1 = FWKEY + ERASE;                    // Set Erase bit
	FCTL3 = FWKEY + LOCKA;                    // Clear LOCK & LOCKA bits

	*Flash_ptrA = 0x00;                       // Dummy write to erase Flash seg A
	FCTL1 = FWKEY + WRT;                      // Set WRT bit for write operation
	Flash_ptrA = (char *)0x10F8;              // Point to beginning of cal consts

	for (dcoj = 0; dcoj < 8; dcoj++)
		*Flash_ptrA++ = CAL_DATA[dcoj];            // re-flash DCO calibration data

	FCTL1 = FWKEY;                            // Clear WRT bit
	FCTL3 = FWKEY + LOCKA + LOCK;             // Set LOCK & LOCKA bit

	P5OUT ^= 0x20;                          // Toggle LED
	//P5OUT ^= 0x20;                          // Toggle LED
	
}

void Set_DCO(unsigned int Delta)            // Set DCO to selected frequency
{
  unsigned int Compare, Oldcapture = 0;

  BCSCTL1 |= DIVA_3;                        // ACLK = LFXT1CLK/8
  TACCTL2 = CM_1 + CCIS_1 + CAP;            // CAP, ACLK
  TACTL = TASSEL_2 + MC_2 + TACLR;          // SMCLK, cont-mode, clear

  while (1)
  {
    while (!(CCIFG & TACCTL2));             // Wait until capture occured
    TACCTL2 &= ~CCIFG;                      // Capture occured, clear flag
    Compare = TACCR2;                       // Get current captured SMCLK
    Compare = Compare - Oldcapture;         // SMCLK difference
    Oldcapture = TACCR2;                    // Save current captured SMCLK

    if (Delta == Compare)
      break;                                // If equal, leave "while(1)"
    else if (Delta < Compare)
    {
      DCOCTL--;                             // DCO is too fast, slow it down
      if (DCOCTL == 0xFF)                   // Did DCO roll under?
        if (BCSCTL1 & 0x0f)
          BCSCTL1--;                        // Select lower RSEL
    }
    else
    {
      DCOCTL++;                             // DCO is too slow, speed it up
      if (DCOCTL == 0x00)                   // Did DCO roll over?
        if ((BCSCTL1 & 0x0f) != 0x0f)
          BCSCTL1++;                        // Sel higher RSEL
    }
  }
  TACCTL2 = 0;                              // Stop TACCR2
  TACTL = 0;                                // Stop Timer_A
  BCSCTL1 &= ~DIVA_3;                       // ACLK = LFXT1CLK
}
#endif
