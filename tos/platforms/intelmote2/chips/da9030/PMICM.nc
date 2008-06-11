/* $Id: PMICM.nc,v 1.6 2008-06-11 00:42:14 razvanm Exp $ */
/*
 * Copyright (c) 2005 Arched Rock Corporation 
 * All rights reserved. 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *	Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 *  
 *   Neither the name of the Arched Rock Corporation nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE ARCHED
 * ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */
/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */

/*
 *
 * Authors:  Lama Nachman, Robert Adler
 */

#define START_RADIO_LDO 1
#define START_SENSOR_BOARD_LDO 1
/*
 * VCC_MEM is connected to BUCK2 by default, make sure you have a board
 * that has the right resistor settings before disabling BUCK2
 */
#define DISABLE_BUCK2 0	

//#include "trace.h"
#include "Timer.h"
#include "pmic.h"

module PMICM {
  provides{
    interface Init;
    interface PMIC;
  }

  uses interface Timer<TMilli> as chargeMonitorTimer;
  uses interface HplPXA27xGPIOPin as PMICGPIO;
  uses interface HplPXA27xI2C as PI2C;
  uses interface PlatformReset;
}

implementation {
#include "pmic.h"
  
  bool gotReset;
  
  
  error_t readPMIC(uint8_t address, uint8_t *value, uint8_t numBytes){
    //send the PMIC the address that we want to read
    if(numBytes > 0){
      call PI2C.setIDBR(PMIC_SLAVE_ADDR<<1); 
      call PI2C.setICR(call PI2C.getICR() | ICR_START);
      call PI2C.setICR(call PI2C.getICR() | ICR_TB); 
      while(call PI2C.getICR() & ICR_TB);
      
      //actually send the address terminated with a STOP
      call PI2C.setIDBR(address);
      call PI2C.setICR(call PI2C.getICR() & ~ICR_START);
      call PI2C.setICR(call PI2C.getICR() | ICR_STOP);
      call PI2C.setICR(call PI2C.getICR() | ICR_TB); 
      while(call PI2C.getICR() & ICR_TB);
      call PI2C.setICR(call PI2C.getICR() & ~ICR_STOP);
      
      //actually request the read of the data
      call PI2C.setIDBR(PMIC_SLAVE_ADDR<<1 | 1);
      call PI2C.setICR(call PI2C.getICR() | ICR_START); 
      call PI2C.setICR(call PI2C.getICR() | ICR_TB);
      while(call PI2C.getICR() & ICR_TB);
      call PI2C.setICR(call PI2C.getICR() & ~ICR_START);
      
      //using Page Read Mode
      while (numBytes > 1){
	call PI2C.setICR(call PI2C.getICR() | ICR_TB); 
	while(call PI2C.getICR() & ICR_TB);
	*value = call PI2C.getIDBR(); 
	value++;
	numBytes--;
      }
      
      call PI2C.setICR(call PI2C.getICR() | ICR_STOP);
      call PI2C.setICR(call PI2C.getICR() | ICR_ACKNAK);
      call PI2C.setICR(call PI2C.getICR() | ICR_TB); 
      while(call PI2C.getICR() & ICR_TB);
      *value = call PI2C.getIDBR(); 
      call PI2C.setICR(call PI2C.getICR() & ~ICR_STOP); 
      call PI2C.setICR(call PI2C.getICR() & ~ICR_ACKNAK);
      
      return SUCCESS;
    }
    else{
      return FAIL;
    }
  }

  error_t writePMIC(uint8_t address, uint8_t value){
    call PI2C.setIDBR(PMIC_SLAVE_ADDR<<1); 
    call PI2C.setICR(call PI2C.getICR() | ICR_START); 
    call PI2C.setICR(call PI2C.getICR() | ICR_TB); 
    while(call PI2C.getICR() & ICR_TB);
    
    PIDBR = address;
    call PI2C.setICR(call PI2C.getICR() & ~ICR_START); 
    call PI2C.setICR(call PI2C.getICR() | ICR_TB); 
    while(call PI2C.getICR() & ICR_TB);

    PIDBR = value;
    call PI2C.setICR(call PI2C.getICR() | ICR_STOP); 
    call PI2C.setICR(call PI2C.getICR() | ICR_TB); 
    while(call PI2C.getICR() & ICR_TB);
    call PI2C.setICR(call PI2C.getICR() & ~ICR_STOP); PICR &= ~ICR_STOP;

    return SUCCESS;
  }
  
  void startLDOs() {
    //uint8_t temp;
    uint8_t oldVal, newVal;

#if START_SENSOR_BOARD_LDO 
    // TODO : Need to move out of here to sensor board functions
    readPMIC(PMIC_A_REG_CONTROL_1, &oldVal, 1);
    newVal = oldVal | ARC1_LDO10_EN | ARC1_LDO11_EN;	// sensor board
    writePMIC(PMIC_A_REG_CONTROL_1, newVal);

    readPMIC(PMIC_B_REG_CONTROL_2, &oldVal, 1);
    newVal = oldVal | BRC2_LDO10_EN | BRC2_LDO11_EN;
    writePMIC(PMIC_B_REG_CONTROL_2, newVal);
#endif

#if START_RADIO_LDO
    // TODO : Move to radio start
    readPMIC(PMIC_B_REG_CONTROL_1, &oldVal, 1);
    newVal = oldVal | BRC1_LDO5_EN; 
    writePMIC(PMIC_B_REG_CONTROL_1, newVal);
#endif

#if DISABLE_BUCK2  // Disable BUCK2 if VCC_MEM is not configured to use BUCK2
    readPMIC(PMIC_B_REG_CONTROL_1, &oldVal, 1);
    newVal = oldVal & ~BRC1_BUCK_EN;
    writePMIC(PMIC_B_REG_CONTROL_1, newVal);
#endif

#if 0
    // Configure above LDOs, Radio and sensor board LDOs to turn off in sleep
    // TODO : Sleep setting doesn't work
    temp = BSC1_LDO1(1) | BSC1_LDO2(1) | BSC1_LDO3(1) | BSC1_LDO4(1);
    writePMIC(PMIC_B_SLEEP_CONTROL_1, temp);
    temp = BSC2_LDO5(1) | BSC2_LDO7(1) | BSC2_LDO8(1) | BSC2_LDO9(1);
    writePMIC(PMIC_B_SLEEP_CONTROL_2, temp);
    temp = BSC3_LDO12(1); 
    writePMIC(PMIC_B_SLEEP_CONTROL_3, temp);
#endif
  }

  error_t startPMICstuff() {
    //command result_t StdControl.start(){ XXX-pb
    //init unit
    uint8_t val[3];
    //call PI2CInterrupt.enable(); XXX-pb

  }

  command error_t Init.init(){
    uint8_t val[3];
    PCFR |= PCFR_PI2C_EN; // Overrides GPIO settings on pins
    call PI2C.setICR(call PI2C.getICR() | (ICR_IUE | ICR_SCLE));
    atomic{
      gotReset=FALSE;
    }    

    call PMICGPIO.setGAFRpin(0);
    call PMICGPIO.setGPDRbit(FALSE);
    call PMICGPIO.setGFERbit(TRUE);
    /*
     * Reset the watchdog, switch it to an interrupt, so we can disable it
     * Ignore SLEEP_N pin, enable H/W reset via button 
     */
    writePMIC(PMIC_SYS_CONTROL_A, 
              SCA_RESET_WDOG | SCA_WDOG_ACTION | SCA_HWRES_EN);

    // Disable all interrupts from PMIC except for ONKEY button
    writePMIC(PMIC_IRQ_MASK_A, ~IMA_ONKEY_N);
    writePMIC(PMIC_IRQ_MASK_B, 0xFF);
    writePMIC(PMIC_IRQ_MASK_C, 0xFF);
    
    //read out the EVENT registers so that we can receive interrupts
    readPMIC(PMIC_EVENTS, val, 3);

    // Set default core voltage to 0.85 V
#ifdef PXA27X_13M
    //P85 is not reliable, using P95
    call PMIC.setCoreVoltage(B2R1_TRIM_P95_V);
#else
    call PMIC.setCoreVoltage(B2R1_TRIM_1_25_V);
#endif
    startLDOs();
    return SUCCESS;
  }

  async event void PI2C.interruptI2C() { //PI2CInterrupt.fired(){
    uint32_t status, update=0;
    status = call PI2C.getISR(); //PISR;
    if(status & ISR_ITE){
      update |= ISR_ITE;
      //trace(DBG_USR1,"sent data");
    }

    if(status & ISR_BED){
      update |= ISR_BED;
      //trace(DBG_USR1,"bus error");
    }
    call PI2C.setISAR(update); //PISR = update;
  }
  
  async event void PMICGPIO.interruptGPIOPin(){
    uint8_t events[3];
    bool localGotReset;
   
    //call PMICGPIO.call PMICInterrupt.clear(); XXX autocleard by GPIO module
   
    readPMIC(PMIC_EVENTS, events, 3);
   
    if(events[EVENTS_A_OFFSET] & EA_ONKEY_N){
      atomic{
        localGotReset = gotReset;
      }
      if(localGotReset==TRUE){
	call PlatformReset.reset();
      }
      else{
        atomic{
	  gotReset=TRUE;
        }
      }
    }
    else{
      //trace(DBG_USR1,"PMIC EVENTs =%#x %#x %#x\r\n",events[0], events[1], events[2]);
    }
  }

  /*
   * The Buck2 controls the core voltage, set to appropriate trim value
   */
  command error_t PMIC.setCoreVoltage(uint8_t trimValue) {
    writePMIC(PMIC_BUCK2_REG1, (trimValue & B2R1_TRIM_MASK) | B2R1_GO);
    return SUCCESS;
  }
  
  command error_t PMIC.shutDownLDOs() {
    uint8_t temp;
    uint8_t oldVal, newVal;
    /* 
     * Shut down all LDOs that are not controlled by the sleep mode
     * Note, we assume here the LDO10 & LDO11 (sensor board) will be off
     * Should be moved to sensor board control
     */

    // LDO1, LDO4, LDO6, LDO7, LDO8, LDO9, LDO10, LDO 11, LDO13, LDO14

    readPMIC(PMIC_A_REG_CONTROL_1, &oldVal, 1);
    newVal = oldVal & ~ARC1_LDO13_EN & ~ARC1_LDO14_EN;
    newVal = newVal & ~ARC1_LDO10_EN & ~ARC1_LDO11_EN;	// sensor board
    writePMIC(PMIC_A_REG_CONTROL_1, newVal);

    readPMIC(PMIC_B_REG_CONTROL_1, &oldVal, 1);
    newVal = oldVal & ~BRC1_LDO1_EN & ~BRC1_LDO4_EN & ~BRC1_LDO5_EN &
             ~BRC1_LDO6_EN & ~BRC1_LDO7_EN;
    writePMIC(PMIC_B_REG_CONTROL_1, newVal);

    readPMIC(PMIC_B_REG_CONTROL_2, &oldVal, 1);
    newVal = oldVal & ~BRC2_LDO8_EN & ~BRC2_LDO9_EN & ~BRC2_LDO10_EN &
             ~BRC2_LDO11_EN & ~BRC2_LDO14_EN & ~BRC2_SIMCP_EN;
    writePMIC(PMIC_B_REG_CONTROL_2, newVal);
    
    return SUCCESS;
  }

  error_t getPMICADCVal(uint8_t channel, uint8_t *val){
    uint8_t oldval;
    error_t rval;
    
    //read out the old value so that we can reset at the end
    rval = readPMIC(PMIC_ADC_MAN_CONTROL, &oldval,1);
    if (rval == SUCCESS) {
      rval = writePMIC(PMIC_ADC_MAN_CONTROL, PMIC_AMC_ADCMUX(channel) | 
		       PMIC_AMC_MAN_CONV | PMIC_AMC_LDO_INT_Enable);
    }
    if (rval == SUCCESS) {
      rval = readPMIC(PMIC_MAN_RES,val,1);
    }
    if (rval == SUCCESS) {
    //reset to old state
    rval = writePMIC(PMIC_ADC_MAN_CONTROL, oldval);
    }

    return rval;
  }

  command error_t PMIC.getBatteryVoltage(uint8_t *val){
    //for now, let's use the manual conversion mode
    return getPMICADCVal(0, val);
  }
  
  command error_t PMIC.chargingStatus(uint8_t *vBat, uint8_t *vChg, 
                                       uint8_t *iChg){
    getPMICADCVal(0, vBat);
    getPMICADCVal(2, vChg);
    getPMICADCVal(1, iChg);
    return SUCCESS;
  }  
  
  command error_t PMIC.enableAutoCharging(bool enable){
    return SUCCESS;
  }
  
  command error_t PMIC.enableManualCharging(bool enable){
    //just turn on or off the LED for now!!
    uint8_t val;
    
    if(enable){
      //want to turn on the charger
      getPMICADCVal(2, &val);
      //if charger is present due some stuff...75 should be 4.65V or so 
      if(val > 75 ) {
	//trace(DBG_USR1,"Charger Voltage is %.3fV...enabling charger...\r\n", ((val*6) * .01035));
	//write the total timeout to be 8 hours
	writePMIC(PMIC_TCTR_CONTROL,8);
	//enable the charger at 100mA and 4.35V
	writePMIC(PMIC_CHARGE_CONTROL,PMIC_CC_CHARGE_ENABLE | PMIC_CC_ISET(1) | PMIC_CC_VSET(7));
	//turn on the LED
	writePMIC(PMIC_LED1_CONTROL,0x80);
	//start a timer to monitor our progress every 5 minutes!
	call chargeMonitorTimer.startPeriodic(300000);
      }
      else{
	//trace(DBG_USR1,"Charger Voltage is %.3fV...charger not enabled\r\n", ((val*6) * .01035));
      }
    }
    else{
      //turn off the charger and the LED
      call PMIC.getBatteryVoltage(&val);
      //trace(DBG_USR1,"Disabling Charger...Battery Voltage is %.3fV\r\n", (val * .01035) + 2.65);
      //disable everything that we enabled
      writePMIC(PMIC_TCTR_CONTROL,0);
      writePMIC(PMIC_CHARGE_CONTROL,0);
      writePMIC(PMIC_LED1_CONTROL,0x00);
    }
    return SUCCESS; 
  }  
  
  event void chargeMonitorTimer.fired(){
    uint8_t val;
    call PMIC.getBatteryVoltage(&val);
    //stop when vBat>4V
    if(val>130){
      call PMIC.enableManualCharging(FALSE);
      call chargeMonitorTimer.stop();
    }
    return;
  }


}
