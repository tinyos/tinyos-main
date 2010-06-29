// $Id: VoltageC.nc,v 1.2 2010-06-29 22:07:51 scipio Exp $

/*
 *
 *
 * Copyright (c) 2000-2004 The Regents of the University  of California.  
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
 *
 */

/**
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 */

module VoltageC {
  provides {
    interface Voltage;
  }
}

implementation {

  command bool Voltage.okToProgram() {

		/** original code form the msp430 folder */
    int i;

    // Turn on and set up ADC12 with REF_1_5V
    ADC12CTL0 = ADC12ON | SHT0_2 | REFON;
    // Use sampling timer
    ADC12CTL1 = SHP;
    // Set up to sample voltage
    ADC12MCTL0 = EOS | SREF_1 | INCH_11;
    // Delay for reference start-up
    for ( i=0; i<0x3600; i++ );

    // Enable conversions
    ADC12CTL0 |= ENC;
    // Start conversion
    ADC12CTL0 |= ADC12SC;
    // Wait for completion
    while ((ADC12IFG & BIT0) == 0);

    // Turn off ADC12
    ADC12CTL0 &= ~ENC;
    ADC12CTL0 = 0;

    // Check if voltage is greater than 2.7V
    return ( ADC12MEM0 > VTHRESH );
  }

}
