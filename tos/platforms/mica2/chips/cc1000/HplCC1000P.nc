// $Id: HplCC1000P.nc,v 1.6 2008-06-26 04:39:12 regehr Exp $

/*
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Low level hardware access to the CC1000.
 *
 * @author Jaein Jeong
 * @author Philip Buonadonna
 */

#include "Atm128Adc.h"
#include "CC1000Const.h"

module HplCC1000P @safe() {
  provides {
    interface Init as PlatformInit;
    interface HplCC1000;
    interface Atm128AdcConfig as RssiConfig;
  }
  uses {
    /* These are the CC1000 pin names */
    interface GeneralIO as CHP_OUT;
    interface GeneralIO as PALE;
    interface GeneralIO as PCLK;
    interface GeneralIO as PDATA;
  }
}
implementation
{
  command error_t PlatformInit.init() {
    call CHP_OUT.makeInput();
    call PALE.makeOutput();
    call PCLK.makeOutput();
    call PDATA.makeOutput();
    call PALE.set();
    call PDATA.set();
    call PCLK.set();

    // MAIN register to power down mode. Shut everything off
    call HplCC1000.write(CC1K_MAIN,
			 1 << CC1K_RX_PD |
			 1 << CC1K_TX_PD | 
			 1 << CC1K_FS_PD |
			 1 << CC1K_CORE_PD |
			 1 << CC1K_BIAS_PD |
			 1 << CC1K_RESET_N);
    call HplCC1000.write(CC1K_PA_POW, 0);  // turn off rf amp
    return SUCCESS;
  }
  
  command void HplCC1000.init() {
  }

  //********************************************************/
  // function: write                                       */
  // description: accepts a 7 bit address and 8 bit data,  */
  //    creates an array of ones and zeros for each, and   */
  //    uses a loop counting thru the arrays to get        */
  //    consistent timing for the chipcon radio control    */
  //    interface.  PALE active low, followed by 7 bits    */
  //    msb first of address, then lsb high for write      */
  //    cycle, followed by 8 bits of data msb first.  data */
  //    is clocked out on the falling edge of PCLK.        */
  // Input:  7 bit address, 8 bit data                     */
  //********************************************************/

  async command void HplCC1000.write(uint8_t addr, uint8_t data) {
    char cnt = 0;

    // address cycle starts here
    addr <<= 1;
    call PALE.clr();  // enable PALE
    for (cnt=0;cnt<7;cnt++)  // send addr PDATA msb first
    {
      if (addr&0x80)
        call PDATA.set();
      else
        call PDATA.clr();
      call PCLK.clr();   // toggle the PCLK
      call PCLK.set();
      addr <<= 1;
    }
    call PDATA.set();
    call PCLK.clr();   // toggle the PCLK
    call PCLK.set();

    call PALE.set();  // disable PALE

    // data cycle starts here
    for (cnt=0;cnt<8;cnt++)  // send data PDATA msb first
    {
      if (data&0x80)
        call PDATA.set();
      else
        call PDATA.clr();
      call PCLK.clr();   // toggle the PCLK
      call PCLK.set();
      data <<= 1;
    }
    call PALE.set();
    call PDATA.set();
    call PCLK.set();
  }

  //********************************************************/
  // function: read                                        */
  // description: accepts a 7 bit address,                 */
  //    creates an array of ones and zeros for each, and   */
  //    uses a loop counting thru the arrays to get        */
  //    consistent timing for the chipcon radio control    */
  //    interface.  PALE active low, followed by 7 bits    */
  //    msb first of address, then lsb low for read        */
  //    cycle, followed by 8 bits of data msb first.  data */
  //    is clocked in on the falling edge of PCLK.         */
  // Input:  7 bit address                                 */
  // Output:  8 bit data                                   */
  //********************************************************/

  async command uint8_t HplCC1000.read(uint8_t addr) {
    int cnt;
    uint8_t din;
    uint8_t data = 0;

    // address cycle starts here
    addr <<= 1;
    call PALE.clr();  // enable PALE
    for (cnt=0;cnt<7;cnt++)  // send addr PDATA msb first
    {
      if (addr&0x80)
        call PDATA.set();
      else
        call PDATA.clr();
      call PCLK.clr();   // toggle the PCLK
      call PCLK.set();
      addr <<= 1;
    }
    call PDATA.clr();
    call PCLK.clr();   // toggle the PCLK
    call PCLK.set();

    call PDATA.makeInput();  // read data from chipcon
    call PALE.set();  // disable PALE

    // data cycle starts here
    for (cnt=7;cnt>=0;cnt--)  // send data PDATA msb first
    {
      call PCLK.clr();  // toggle the PCLK
      din = call PDATA.get();
      if(din)
        data = (data<<1)|0x01;
      else
        data = (data<<1)&0xfe;
      call PCLK.set();
    }

    call PALE.set();
    call PDATA.makeOutput();
    call PDATA.set();

    return data;
  }


  async command bool HplCC1000.getLOCK() {
    return call CHP_OUT.get();
  }

  async command uint8_t RssiConfig.getChannel() {
    return CHANNEL_RSSI;
  }

  async command uint8_t RssiConfig.getRefVoltage() {
    return ATM128_ADC_VREF_OFF;
  }

  async command uint8_t RssiConfig.getPrescaler() {
    return ATM128_ADC_PRESCALE;
  }
}
  
