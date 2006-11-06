/* $Id: CC1000ControlP.nc,v 1.2 2006-11-06 11:57:05 scipio Exp $
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
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
 * Copyright (c) 2002-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
#include "CC1000Const.h"
#include "Timer.h"

/**
 * This module provides the CONTROL functionality for the Chipcon1000
 * series radio.  It exports a custom interface to control CC1000
 * operation.
 *
 * @author Philip Buonadonna
 * @author Jaein Jeong
 * @author David Gay
 */
module CC1000ControlP {
  provides {
    interface CC1000Control;
  }
  uses {
    interface HplCC1000 as CC;
    interface BusyWait<TMicro, uint16_t>;
  }
}
implementation
{
  uint8_t txCurrent, rxCurrent, power;

  enum {
    IF = 150000,
    FREQ_MIN = 4194304,
    FREQ_MAX = 16751615
  };

  const_uint32_t fRefTbl[9] = {2457600,
			       2106514,
			       1843200,
			       1638400,
			       1474560,
			       1340509,
			       1228800,
			       1134277,
			       1053257};
  
  const_uint16_t corTbl[9] = {1213,
			      1416,
			      1618,
			      1820,
			      2022,
			      2224,
			      2427,
			      2629,
			      2831};
  
  const_uint16_t fSepTbl[9] = {0x1AA,
			       0x1F1,
			       0x238,
			       0x280,
			       0x2C7,
			       0x30E,
			       0x355,
			       0x39C,
			       0x3E3};
  
  void calibrateNow() {
    // start cal
    call CC.write(CC1K_CAL,
		  1 << CC1K_CAL_START |
		  1 << CC1K_CAL_WAIT |
		  6 << CC1K_CAL_ITERATE);
    while ((call CC.read(CC1K_CAL) & 1 << CC1K_CAL_COMPLETE) == 0)
      ;

    //exit cal mode
    call CC.write(CC1K_CAL, 1 << CC1K_CAL_WAIT | 6 << CC1K_CAL_ITERATE);
  }

  void calibrate() {
    call CC.write(CC1K_PA_POW, 0x00);  // turn off rf amp
    call CC.write(CC1K_TEST4, 0x3f);   // chip rate >= 38.4kb

    // RX - configure main freq A
    call CC.write(CC1K_MAIN, 1 << CC1K_TX_PD | 1 << CC1K_RESET_N);

    calibrateNow();

    // TX - configure main freq B
    call CC.write(CC1K_MAIN,
		  1 << CC1K_RXTX |
		  1 << CC1K_F_REG |
		  1 << CC1K_RX_PD | 
		  1 << CC1K_RESET_N);
    // Set TX current
    call CC.write(CC1K_CURRENT, txCurrent);
    call CC.write(CC1K_PA_POW, 0);

    calibrateNow();
  }

  /*
   * cc1000ComputeFreq(uint32_t desiredFreq);
   *
   * Compute an achievable frequency and the necessary CC1K parameters from
   * a given desired frequency (Hz). The function returns the actual achieved
   * channel frequency in Hz.
   *
   * This routine assumes the following:
   *  - Crystal Freq: 14.7456 MHz
   *  - LO Injection: High
   *  - Separation: 64 KHz
   *  - IF: 150 KHz
   * 
   * Approximate costs for this function:
   *  - ~870 bytes FLASH
   *  - ~32 bytes RAM
   *  - 9400 cycles
   */
  uint32_t cc1000SetFrequency(uint32_t desiredFreq) {
    uint32_t ActualChannel = 0;
    uint32_t RXFreq = 0, TXFreq = 0;
    int32_t Offset = 0x7fffffff;
    uint16_t FSep = 0;
    uint8_t RefDiv = 0;
    uint8_t i, match, frontend;

    for (i = 0; i < 9; i++)
      {
	uint32_t NRef = desiredFreq + IF;
	uint32_t FRef = read_uint32_t(&fRefTbl[i]);
	uint32_t Channel = 0;
	uint32_t RXCalc = 0, TXCalc = 0;
	int32_t  diff;

	NRef = ((desiredFreq + IF)  <<  2) / FRef;
	if (NRef & 0x1)
	  NRef++;

	if (NRef & 0x2)
	  {
	    RXCalc = 16384 >> 1;
	    Channel = FRef >> 1;
	  }

	NRef >>= 2;

	RXCalc += (NRef * 16384) - 8192;
	if ((RXCalc < FREQ_MIN) || (RXCalc > FREQ_MAX)) 
	  continue;
    
	TXCalc = RXCalc - read_uint16_t(&corTbl[i]);
	if (TXCalc < FREQ_MIN || TXCalc > FREQ_MAX)
	  continue;

	Channel += NRef * FRef;
	Channel -= IF;

	diff = Channel - desiredFreq;
	if (diff < 0)
	  diff = -diff;

	if (diff < Offset)
	  {
	    RXFreq = RXCalc;
	    TXFreq = TXCalc;
	    ActualChannel = Channel;
	    FSep = read_uint16_t(&fSepTbl[i]);
	    RefDiv = i + 6;
	    Offset = diff;
	  }
      }

    if (RefDiv != 0)
      {
	call CC.write(CC1K_FREQ_0A, RXFreq);
	call CC.write(CC1K_FREQ_1A, RXFreq >> 8);
	call CC.write(CC1K_FREQ_2A, RXFreq >> 16);

	call CC.write(CC1K_FREQ_0B, TXFreq);
	call CC.write(CC1K_FREQ_1B, TXFreq >> 8);
	call CC.write(CC1K_FREQ_2B, TXFreq >> 16);

	call CC.write(CC1K_FSEP0, FSep);
	call CC.write(CC1K_FSEP1, FSep >> 8);

	if (ActualChannel < 500000000)
	  {
	    if (ActualChannel < 400000000)
	      {
		rxCurrent = 8 << CC1K_VCO_CURRENT | 1 << CC1K_LO_DRIVE;
		txCurrent = 9 << CC1K_VCO_CURRENT | 1 << CC1K_PA_DRIVE;
	      }
	    else
	      {
		rxCurrent = 4 << CC1K_VCO_CURRENT | 1 << CC1K_LO_DRIVE;
		txCurrent = 8 << CC1K_VCO_CURRENT | 1 << CC1K_PA_DRIVE;
	      }
	    frontend = 1 << CC1K_IF_RSSI;
	    match = 7 << CC1K_RX_MATCH;
	  }
	else
	  {
	    rxCurrent = 8 << CC1K_VCO_CURRENT | 3 << CC1K_LO_DRIVE;
	    txCurrent = 15 << CC1K_VCO_CURRENT | 3 << CC1K_PA_DRIVE;

	    frontend =
	      1 << CC1K_BUF_CURRENT | 2 << CC1K_LNA_CURRENT | 
	      1 << CC1K_IF_RSSI;
	    match = 2 << CC1K_RX_MATCH; // datasheet says to use 1...
	  }
	call CC.write(CC1K_CURRENT, rxCurrent);
	call CC.write(CC1K_MATCH, match);
	call CC.write(CC1K_FRONT_END, frontend);
	call CC.write(CC1K_PLL, RefDiv << CC1K_REFDIV);
      }

    return ActualChannel;
  }

  command void CC1000Control.init() {
    call CC.init();

    // wake up xtal and reset unit
    call CC.write(CC1K_MAIN,
		  1 << CC1K_RX_PD | 1 << CC1K_TX_PD | 
		  1 << CC1K_FS_PD | 1 << CC1K_BIAS_PD); 
    // clear reset.
    call CC1000Control.coreOn();
    call BusyWait.wait(2000);

    // Set default parameter values
    // POWER: 0dbm (~900MHz), 6dbm (~430MHz)
    power = 8 << CC1K_PA_HIGHPOWER | 0 << CC1K_PA_LOWPOWER;
    call CC.write(CC1K_PA_POW, power);

    // select Manchester Violation for CHP_OUT
    call CC.write(CC1K_LOCK_SELECT, 9 << CC1K_LOCK_SELECT);

    // Default modem values = 19.2 Kbps (38.4 kBaud), Manchester encoded
    call CC.write(CC1K_MODEM2, 0);
    call CC.write(CC1K_MODEM1, 
		  3 << CC1K_MLIMIT |
		  1 << CC1K_LOCK_AVG_MODE | 
		  3 << CC1K_SETTLING |
		  1 << CC1K_MODEM_RESET_N);
    call CC.write(CC1K_MODEM0, 
		  5 << CC1K_BAUDRATE |
		  1 << CC1K_DATA_FORMAT | 
		  1 << CC1K_XOSC_FREQ);

    call CC.write(CC1K_FSCTRL, 1 << CC1K_FS_RESET_N);

#ifdef CC1K_DEF_FREQ
    call CC1000Control.tuneManual(CC1K_DEF_FREQ);
#else
    call CC1000Control.tunePreset(CC1K_DEF_PRESET);
#endif
    call CC1000Control.off();
  }

  command void CC1000Control.tunePreset(uint8_t freq) {
    int i;

    // FREQA, FREQB, FSEP, CURRENT(RX), FRONT_END, POWER, PLL
    for (i = CC1K_FREQ_2A; i <= CC1K_PLL; i++)
      call CC.write(i, read_uint8_t(&CC1K_Params[freq][i]));
    call CC.write(CC1K_MATCH, read_uint8_t(&CC1K_Params[freq][CC1K_MATCH]));
    rxCurrent = read_uint8_t(&CC1K_Params[freq][CC1K_CURRENT]);
    txCurrent = read_uint8_t(&CC1K_Params[freq][CC1K_MATCH + 1]);
    power = read_uint8_t(&CC1K_Params[freq][CC1K_PA_POW]);

    calibrate();
  }

  command uint32_t CC1000Control.tuneManual(uint32_t DesiredFreq) {
    uint32_t actualFreq;

    actualFreq = cc1000SetFrequency(DesiredFreq);

    calibrate();

    return actualFreq;
  }

  async command void CC1000Control.txMode() {
    // MAIN register to TX mode
    call CC.write(CC1K_MAIN,
		  1 << CC1K_RXTX |
		  1 << CC1K_F_REG |
		  1 << CC1K_RX_PD | 
		  1 << CC1K_RESET_N);
    // Set the TX mode VCO Current
    call CC.write(CC1K_CURRENT, txCurrent);
    call BusyWait.wait(250);
    call CC.write(CC1K_PA_POW, power);
    call BusyWait.wait(20);
  }

  async command void CC1000Control.rxMode() {
    // MAIN register to RX mode
    // Powerup Freqency Synthesizer and Receiver
    call CC.write(CC1K_CURRENT, rxCurrent);
    call CC.write(CC1K_PA_POW, 0); // turn off power amp
    call CC.write(CC1K_MAIN, 1 << CC1K_TX_PD | 1 << CC1K_RESET_N);
    call BusyWait.wait(125);
  }

  async command void CC1000Control.coreOn() {
    // MAIN register to SLEEP mode
    call CC.write(CC1K_MAIN,
		  1 << CC1K_RX_PD |
		  1 << CC1K_TX_PD | 
		  1 << CC1K_FS_PD |
		  1 << CC1K_BIAS_PD |
		  1 << CC1K_RESET_N);
  }

  async command void CC1000Control.biasOn() {
    call CC.write(CC1K_MAIN,
		  1 << CC1K_RX_PD |
		  1 << CC1K_TX_PD | 
		  1 << CC1K_FS_PD | 
		  1 << CC1K_RESET_N);
  }


  async command void CC1000Control.off() {
    // MAIN register to power down mode. Shut everything off
    call CC.write(CC1K_MAIN,
		  1 << CC1K_RX_PD |
		  1 << CC1K_TX_PD | 
		  1 << CC1K_FS_PD |
		  1 << CC1K_CORE_PD |
		  1 << CC1K_BIAS_PD |
		  1 << CC1K_RESET_N);
    call CC.write(CC1K_PA_POW, 0);  // turn off rf amp
  }

  command void CC1000Control.setRFPower(uint8_t newPower) {
    power = newPower;
  }

  command uint8_t CC1000Control.getRFPower() {
    return power;
  }

  command void CC1000Control.selectLock(uint8_t fn) {
    // Select function of CHP_OUT pin (readable via getLock)
    call CC.write(CC1K_LOCK, fn << CC1K_LOCK_SELECT);
  }

  command uint8_t CC1000Control.getLock() {
    return call CC.getLOCK(); 
  }

  command bool CC1000Control.getLOStatus() {
    // We use a high-side LO (local oscillator) frequency -> data will be
    // inverted. See cc1000ComputeFreq and CC1000 datasheet p.23.
    return TRUE;
  }
}
