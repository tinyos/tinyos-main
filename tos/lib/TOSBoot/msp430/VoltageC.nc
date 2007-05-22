// $Id: VoltageC.nc,v 1.1 2007-05-22 20:34:21 razvanm Exp $

/*									tab:2
 *
 *
 * "Copyright (c) 2000-2004 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
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

  enum {
    VTHRESH = 0xE66, // 2.7V
  };

  command bool Voltage.okToProgram() {

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
