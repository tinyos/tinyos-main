/*
 * Copyright (c) 2009 DEXMA SENSORS SL
 * Copyright (c) 2011 ZOLERTIA LABS
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 *
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 *
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
 */

/*
 * Implementation of ADXL345 accelerometer, as a part of Zolertia Z1 mote
 *
 * Credits goes to DEXMA SENSORS SL
 * @author: Xavier Orduna <xorduna@dexmatech.com>
 * @author: Jordi Soucheiron <jsoucheiron@dexmatech.com>
 * @author: Antonio Linan <alinan@zolertia.com>
 */

#include "ADXL345.h"

module ADXL345P {
   provides {
	interface SplitControl;
	interface Read<uint8_t> as Register;
	interface Read<uint8_t> as Duration;
	interface Read<uint8_t> as Latent;
	interface Read<uint8_t> as Window;
	interface Read<uint8_t> as BwRate;
	interface Read<uint8_t> as PowerCtl;
	interface Read<uint8_t> as IntEnable;	
	interface Read<uint8_t> as IntMap;
	interface Read<uint8_t> as IntSource;
	interface Read<uint16_t> as X;
	interface Read<uint16_t> as Y;
	interface Read<uint16_t> as Z;
	interface Read<adxl345_readxyt_t> as XYZ;
	interface ADXL345Control;
	interface Notify<adxlint_state_t> as Int1;
	interface Notify<adxlint_state_t> as Int2;
   }
   uses {
	interface Resource;
	interface ResourceRequested;
	interface I2CPacket<TI2CBasicAddr> as I2CBasicAddr;     
	interface GeneralIO as GeneralIO1;
	interface GeneralIO as GeneralIO2;
	interface GpioInterrupt as GpioInterrupt1;
	interface GpioInterrupt as GpioInterrupt2;
	interface Timer<TMilli> as TimeoutAlarm;
  }
   
}
implementation {
  
  norace bool lock=FALSE;
  norace uint8_t state;
  norace uint8_t adxlcmd;
  norace uint8_t databuf[20];
  norace uint8_t set_reg[2];
  norace uint8_t pointer;
  norace uint8_t readAddress=0;
  norace uint8_t regData;
  norace uint8_t duration;
  norace uint8_t latent;
  norace uint8_t window;
  norace uint8_t bw_rate;
  norace uint8_t power_ctl=0x0;
  norace uint8_t int_enable;
  norace uint8_t int_map;
  norace uint8_t int_source;
  norace uint8_t dataformat;
  norace error_t error_return= SUCCESS;
  norace uint16_t x_axis;
  norace uint16_t y_axis;
  norace uint16_t z_axis;
  norace adxl345_readxyt_t xyz_axis;


  task void sendEvent1();
  task void sendEvent2();
  
  task void started(){
	if(call TimeoutAlarm.isRunning()) call TimeoutAlarm.stop();
	lock = FALSE;
  	signal SplitControl.startDone(error_return);
  }
  
  task void stopped(){
	lock = FALSE;
	signal SplitControl.stopDone(error_return);
  }
  
  task void calculatePowerCtl() {
	lock = FALSE;
	signal PowerCtl.readDone(error_return, power_ctl);
  }
  
  task void calculateBwRate() {
	lock = FALSE;
	signal BwRate.readDone(error_return, bw_rate);
  }

  task void calculateIntMap() {
	lock = FALSE;
	signal IntMap.readDone(error_return, int_map);
  }
  
  task void calculateIntEnable() {
	lock = FALSE;
	signal IntEnable.readDone(error_return, int_enable);
  }

  task void calculateIntSource() {
	lock = FALSE;
	signal IntSource.readDone(error_return, int_source);
  }
  
  task void calculateX(){
	lock = FALSE;
  	signal X.readDone(error_return, x_axis);
  }

  task void calculateY(){
	lock = FALSE;
  	signal Y.readDone(error_return, y_axis);
  }

  task void calculateZ(){
	lock = FALSE;
  	signal Z.readDone(error_return, z_axis);
  }

  task void calculateXYZ(){
	lock = FALSE;
  	signal XYZ.readDone(error_return, xyz_axis);
  }

  task void calculateRegister() {
	lock = FALSE;
	signal Register.readDone(error_return, regData);
  }

  task void rangeDone(){
	lock = FALSE;
  	signal ADXL345Control.setRangeDone(error_return);
  }

  task void setRegisterDone(){
	lock = FALSE;
  	signal ADXL345Control.setRegisterDone(error_return);
  }

  task void setIntMapDone(){
	lock = FALSE;
  	signal ADXL345Control.setIntMapDone(error_return);
  }

  task void interruptsDone(){
	lock = FALSE;
  	signal ADXL345Control.setInterruptsDone(error_return);
  }

  task void durationDone(){
	lock = FALSE;
  	signal ADXL345Control.setDurationDone(error_return);
  }

  task void latentDone(){
	lock = FALSE;
  	signal ADXL345Control.setLatentDone(error_return);
  }
  task void windowDone(){
	lock = FALSE;
  	signal ADXL345Control.setWindowDone(error_return);
  }

  task void readDurationDone(){
	lock = FALSE;
  	signal Duration.readDone(error_return, duration);
  }

  task void readLatentDone(){
	lock = FALSE;
  	signal Latent.readDone(error_return, latent);
  }

  task void readWindowDone(){
	lock = FALSE;
  	signal Window.readDone(error_return, window);
  }

  task void setReadAddressDone() {
    lock = FALSE;
	signal ADXL345Control.setReadAddressDone(SUCCESS);
  }


  command error_t SplitControl.start(){
	error_t e;
	if(lock) return EBUSY;
	lock = TRUE;
	adxlcmd = ADXLCMD_START;
	e = call Resource.request();
	if (e==SUCCESS) {
	  call TimeoutAlarm.startOneShot(ADXL345_START_TIMEOUT);
	  return SUCCESS;
	}
	lock = FALSE;
	return e;
  }
  
  command error_t SplitControl.stop(){
	error_t e;
	if(lock) return EBUSY;
	lock = TRUE;
	adxlcmd = ADXLCMD_STOP;
	e = call Resource.request();
  	if (e==SUCCESS) {
	  return SUCCESS;
	}
	lock = FALSE;
	return e;
  }

  command error_t ADXL345Control.setReadAddress(uint8_t address){
    if(lock) return EBUSY;
    lock = TRUE;
    if( address >= 0x01 && address <= 0x1C) return EINVAL;		//reserved, do not access
    if( address >= 0x3A) return EINVAL; 				        //too big
    readAddress = address;
    post setReadAddressDone();
    return SUCCESS;
  }
  
  command error_t ADXL345Control.setRange(uint8_t range, uint8_t resolution){
	error_t e;
	if(lock) return EBUSY;
	lock = TRUE;
	adxlcmd = ADXLCMD_SET_RANGE;
  	e=call Resource.request();
  	if(e==SUCCESS) {
	  dataformat = resolution << 3;
	  dataformat = dataformat + range;
	  return SUCCESS;
	}
	lock = FALSE;
	return e;
  }

  command error_t ADXL345Control.setRegister(uint8_t reg, uint8_t value){
	error_t e;
	if(lock) return EBUSY;
	lock = TRUE;
	adxlcmd = ADXLCMD_SET_REGISTER;
  	e=call Resource.request();
  	if(e==SUCCESS) {
	  set_reg[0] = reg;
	  set_reg[1] = value;
	  return SUCCESS;
	}
	lock = FALSE;
	return e;
  }

  command error_t ADXL345Control.setInterrups(uint8_t int_enable_par) {
	error_t e;
	if(lock) return EBUSY;
	lock = TRUE;
	adxlcmd = ADXLCMD_INT;
	e = call Resource.request();
	if (e==SUCCESS) {
	  int_enable = int_enable_par;
	  return SUCCESS;
	}
	lock = FALSE;
	return e;
  }

  command error_t ADXL345Control.setDuration(uint8_t duration_par) {
	error_t e;
	if(lock) return EBUSY;
	lock = TRUE;
	adxlcmd = ADXLCMD_SET_DURATION;
	e = call Resource.request();
	if (e==SUCCESS) {
	  duration = duration_par;
	  return SUCCESS;
	}
	lock = FALSE;
	return e;
  }

  command error_t ADXL345Control.setLatent(uint8_t latent_par) {
	error_t e;
	if(lock) return EBUSY;
	lock = TRUE;
	adxlcmd = ADXLCMD_SET_LATENT;
	e = call Resource.request();
	if (e==SUCCESS) {
	  latent = latent_par;
	  return SUCCESS;
	}
	lock = FALSE;
	return e;
  }

  command error_t ADXL345Control.setWindow(uint8_t window_par) {
	error_t e;
	if(lock) return EBUSY;
	lock = TRUE;
	adxlcmd = ADXLCMD_SET_WINDOW;
	e = call Resource.request();
	if (e==SUCCESS) {
	  window = window_par;
	  return SUCCESS;
	}
	lock = FALSE;
	return e;
  }

  command error_t ADXL345Control.setIntMap(uint8_t int_map_par) {
	error_t e;
	if(lock) return EBUSY;
	lock = TRUE;
	adxlcmd = ADXLCMD_SET_INT_MAP;
	e = call Resource.request();
	if (e==SUCCESS) {
	  int_map = int_map_par;
	  return SUCCESS;
	}
	lock = FALSE;
	return e;
  }
  
  command error_t PowerCtl.read() {
	error_t e;
	if(lock) return EBUSY;
	lock = TRUE;
	adxlcmd = ADXLCMD_READ_POWER_CTL;
	e = call Resource.request();
	if (e==SUCCESS) {
	  return SUCCESS;
	}
	lock = FALSE;
	return e;
  }
  
  command error_t BwRate.read() {
	error_t e;
	if(lock) return EBUSY;
	lock = TRUE;
	adxlcmd = ADXLCMD_READ_BW_RATE;
	e = call Resource.request();
	if (e==SUCCESS) {
      return SUCCESS;
	}
	lock = FALSE;
	return e;
  }
  
  command error_t IntEnable.read() {
	error_t e;
	if(lock) return EBUSY;
	lock = TRUE;
	adxlcmd = ADXLCMD_READ_INT_ENABLE;
	e = call Resource.request();
	if (e==SUCCESS) {
	  return SUCCESS;
	}
	lock = FALSE;
	return e;
  }

  command error_t IntMap.read() {
	error_t e;
	if(lock) return EBUSY;
	lock = TRUE;
	adxlcmd = ADXLCMD_READ_INT_MAP;
	e = call Resource.request();
	if (e==SUCCESS) {
	  return SUCCESS;
	}
	lock = FALSE;
	return e;
  }

  command error_t IntSource.read() {
	error_t e;
	if(lock) return EBUSY;
	lock = TRUE;
	adxlcmd = ADXLCMD_READ_INT_SOURCE;
	e = call Resource.request();
	if (e==SUCCESS) {
	  return SUCCESS;
	}
	lock = FALSE;
	return e;
  }

  command error_t Register.read() {
	error_t e;
	if(lock) return EBUSY;
	lock = TRUE;
	adxlcmd = ADXLCMD_READ_REGISTER;
	e = call Resource.request();
	if (e==SUCCESS) {
		return SUCCESS;
	}
	lock = FALSE;
	return e;
  }

  command error_t X.read(){
	error_t e;
	if(lock) return EBUSY;
	lock = TRUE;
	adxlcmd = ADXLCMD_READ_X;
	if ((power_ctl & ADXL345_MEASURE_MODE) == 0) {
		lock=FALSE;
		return FAIL;
	}
	e = call Resource.request();
	if (e==SUCCESS) {
		return SUCCESS;
	}
	lock = FALSE;
	return e;
  }

  command error_t Y.read(){
	error_t e;
	if(lock) return EBUSY;
	lock = TRUE;
	adxlcmd = ADXLCMD_READ_Y;
	if ((power_ctl & ADXL345_MEASURE_MODE) == 0) {
		lock=FALSE;
		return FAIL;
	}
	e = call Resource.request();
	if (e==SUCCESS) {
		return SUCCESS;
	}
	lock = FALSE;
	return e;
  }

  command error_t Z.read(){
	error_t e;
	if(lock) return EBUSY;
	lock = TRUE;
	adxlcmd = ADXLCMD_READ_Z;
	if ((power_ctl & ADXL345_MEASURE_MODE) == 0) {
	  lock=FALSE;
	  return FAIL;
	}
	e = call Resource.request();
	if (e==SUCCESS) return SUCCESS;
	lock = FALSE;
	return e;
  }

  command error_t XYZ.read(){
	error_t e;
	if(lock) return EBUSY;
	lock = TRUE;
	adxlcmd = ADXLCMD_READ_XYZ;
	if ((power_ctl & ADXL345_MEASURE_MODE) == 0) {
	  lock=FALSE;
	  return FAIL;
	}
	e = call Resource.request();
	if (e==SUCCESS) return SUCCESS;
	lock = FALSE;
	return e;
  }

  command error_t Duration.read(){
	error_t e;
	if(lock) return EBUSY;
	lock = TRUE;
	adxlcmd = ADXLCMD_READ_DURATION;
	e = call Resource.request();
	if (e==SUCCESS) {
		return SUCCESS;
	}
	lock = FALSE;
	return e;
  }

  command error_t Latent.read(){
	error_t e;
	if(lock) return EBUSY;
	lock = TRUE;
	adxlcmd = ADXLCMD_READ_LATENT;
	e = call Resource.request();
	if (e==SUCCESS) {
		return SUCCESS;
	}
	lock = FALSE;
	return e;
  }

  command error_t Window.read(){
	error_t e;
	if(lock) return EBUSY;
	lock = TRUE;
	adxlcmd = ADXLCMD_READ_WINDOW;
	e = call Resource.request();
	if (e==SUCCESS) {
      return SUCCESS;
	}
	lock = FALSE;
	return e;
  }

  event void Resource.granted(){
	error_t e;
  	switch(adxlcmd){

		case ADXLCMD_READ_XYZ: //NOTE moved to speedup
		   	pointer = ADXL345_DATAX0;
		   	e = call I2CBasicAddr.write((I2C_START | I2C_STOP), ADXL345_ADDRESS, 1, &pointer); 
			if (e!= SUCCESS) {
			  error_return = e;
			  post calculateXYZ();
			}
  			break;

  		case ADXLCMD_START:
			power_ctl = power_ctl | ADXL345_MEASURE_MODE;
			databuf[0] = ADXL345_THRESH_TAP;
			databuf[1] = 0x40;			//ADXL345_THRESH_TAP
			databuf[2] = 0x0;			//ADXL345_OFSX
			databuf[3] = 0x0;			//ADXL345_OFSY
			databuf[4] = 0x0;			//ADXL345_OFSZ
			databuf[5] = 0x7F;			//ADXL345_DUR
			databuf[6] = 0x30;			//ADXL345_LATENT
			databuf[7] = 0x7F;			//ADXL345_WINDOW
			databuf[8] = 0x2;			//ADXL345_THRESH_ACT
			databuf[9] = 0x1;			//ADXL345_THRESH_INACT
			databuf[10] = 0xFF;			//ADXL345_TIME_INACT
			databuf[11] = 0xFF;			//ADXL345_ACT_INACT_CTL
			databuf[12] = 0x05;			//ADXL345_THRESH_FF
			databuf[13] = 0x14;			//ADXL345_TIME_FF
			databuf[14] = 0x7;			//ADXL345_TAP_AXES
			databuf[15] = 0x0;			//ADXL345_ACT_TAP_STATUS(read only)
			databuf[16] = 0x0A;			//ADXL345_BW_RATE
			databuf[17] = power_ctl;		//ADXL345_POWER_CTL
			databuf[18] = 0x0;			//ADXL345_INT_ENABLE (all disabled by default)
			e = call I2CBasicAddr.write((I2C_START | I2C_STOP), ADXL345_ADDRESS, 19, databuf);
			if (e!= SUCCESS) {
			  error_return = e;
			  post started();
			}
			break;

		case ADXLCMD_READ_DURATION:
			pointer = ADXL345_DUR;
			e = call I2CBasicAddr.write((I2C_START | I2C_STOP), ADXL345_ADDRESS, 1, &pointer); 
			if (e!= SUCCESS) {
				error_return = e;
				post readDurationDone();
			}
			break;

  		case ADXLCMD_READ_LATENT:
		   	pointer = ADXL345_LATENT;
		   	e = call I2CBasicAddr.write((I2C_START | I2C_STOP), ADXL345_ADDRESS, 1, &pointer); 
			if (e!= SUCCESS) {
				error_return = e;
				post readLatentDone();
			}
  			break;

  		case ADXLCMD_READ_WINDOW:
		   	pointer = ADXL345_WINDOW;
		   	e = call I2CBasicAddr.write((I2C_START | I2C_STOP), ADXL345_ADDRESS, 1, &pointer); 
			if (e!= SUCCESS) {
				error_return = e;
				post readWindowDone();
			}
  			break;
			
		case ADXLCMD_READ_POWER_CTL:
			pointer = ADXL345_POWER_CTL;
			e = call I2CBasicAddr.write((I2C_START | I2C_STOP), ADXL345_ADDRESS, 1, &pointer); 
			if (e!= SUCCESS) {
				error_return = e;
				post calculatePowerCtl();
			}
			break;
			
		case ADXLCMD_READ_BW_RATE:
			pointer = ADXL345_BW_RATE;
			e = call I2CBasicAddr.write((I2C_START | I2C_STOP), ADXL345_ADDRESS, 1, &pointer); 
			if (e!= SUCCESS) {
				error_return = e;
				post calculateBwRate();
			}
			break;

		case ADXLCMD_READ_INT_ENABLE:
			pointer = ADXL345_INT_ENABLE;
			e = call I2CBasicAddr.write((I2C_START | I2C_STOP), ADXL345_ADDRESS, 1, &pointer); 
			if (e!= SUCCESS) {
				error_return = e;
				post calculateIntEnable();
			}
			break;
			
  		case ADXLCMD_READ_INT_MAP:
		   	pointer = ADXL345_INT_MAP;
		   	e = call I2CBasicAddr.write((I2C_START | I2C_STOP), ADXL345_ADDRESS, 1, &pointer); 
			if (e!= SUCCESS) {
				error_return = e;
				post calculateIntMap();
			}
  			break;
			
  		case ADXLCMD_READ_INT_SOURCE:
		   	pointer = ADXL345_INT_SOURCE;
		   	e = call I2CBasicAddr.write((I2C_START | I2C_STOP), ADXL345_ADDRESS, 1, &pointer);
			if (e!= SUCCESS) {
				error_return = e;
				post calculateIntSource();
			}
  			break;
			
  		case ADXLCMD_READ_X:
		   	pointer = ADXL345_DATAX0;
		   	e = call I2CBasicAddr.write((I2C_START | I2C_STOP), ADXL345_ADDRESS, 1, &pointer); 
			if (e!= SUCCESS) {
				error_return = e;
				post calculateX();
			}
  			break;

  		case ADXLCMD_READ_Y:
		   	pointer = ADXL345_DATAY0;
		   	e = call I2CBasicAddr.write((I2C_START | I2C_STOP), ADXL345_ADDRESS, 1, &pointer); 
			if (e!= SUCCESS) {
				error_return = e;
				post calculateY();
			}
			break;

  		case ADXLCMD_READ_Z:
		   	pointer = ADXL345_DATAZ0;
		   	e = call I2CBasicAddr.write((I2C_START | I2C_STOP), ADXL345_ADDRESS, 1, &pointer); 
			if (e!= SUCCESS) {
				error_return = e;
				post calculateZ();
			}
  			break;

		case ADXLCMD_READ_REGISTER:
		   	pointer = readAddress;
		   	e = call I2CBasicAddr.write((I2C_START | I2C_STOP), ADXL345_ADDRESS, 1, &pointer); 
			if (e!= SUCCESS) {
				error_return = e;
				post calculateRegister();
			}
  			break;

		case ADXLCMD_SET_REGISTER:
		   	databuf[0] = set_reg[0];
  			databuf[1] = set_reg[1];
		   	e = call I2CBasicAddr.write((I2C_START | I2C_STOP), ADXL345_ADDRESS, 2, databuf);
			if (e!= SUCCESS) {
				error_return = e;
				post setRegisterDone();
			}
  			break;

		case ADXLCMD_SET_INT_MAP:
		   	databuf[0] = ADXL345_INT_MAP;
  			databuf[1] = int_map;
		   	e = call I2CBasicAddr.write((I2C_START | I2C_STOP), ADXL345_ADDRESS, 2, databuf);
			if (e!= SUCCESS) {
				error_return = e;
				post setIntMapDone();
			}
  			break;

  		case ADXLCMD_SET_RANGE:
  			databuf[0] = ADXL345_DATAFORMAT;
  			databuf[1] = dataformat;
  			e = call I2CBasicAddr.write((I2C_START | I2C_STOP), ADXL345_ADDRESS, 2, databuf);
			if (e!= SUCCESS) {
				error_return = e;
				post rangeDone();
			}
  			break;

		case ADXLCMD_STOP:
			power_ctl = power_ctl & ADXL345_STANDBY_MODE;
			databuf[0] = ADXL345_POWER_CTL;
		  	databuf[1] = power_ctl;
			e = call I2CBasicAddr.write((I2C_START | I2C_STOP), ADXL345_ADDRESS, 2, databuf);
			if (e!= SUCCESS) {
				error_return = e;
				post stopped();
			}
			break;

		case ADXLCMD_INT:
			databuf[0] = ADXL345_INT_ENABLE;
			databuf[1] = int_enable;
			e = call I2CBasicAddr.write((I2C_START | I2C_STOP), ADXL345_ADDRESS, 2, databuf);
			if (e!= SUCCESS) {
				error_return = e;
				post interruptsDone();
			}
			break;

		case ADXLCMD_SET_DURATION:
			databuf[0] = ADXL345_DUR;
			databuf[1] = duration;
			e = call I2CBasicAddr.write((I2C_START | I2C_STOP), ADXL345_ADDRESS, 2, databuf);
			if (e!= SUCCESS) {
				error_return = e;
				post durationDone();
			}
			break;

		case ADXLCMD_SET_LATENT:
			databuf[0] = ADXL345_LATENT;
			databuf[1] = latent;
			e = call I2CBasicAddr.write((I2C_START | I2C_STOP), ADXL345_ADDRESS, 2, databuf);
			if (e!= SUCCESS) {
				error_return = e;
				post latentDone();
			}
			break;

		case ADXLCMD_SET_WINDOW:
			databuf[0] = ADXL345_WINDOW;
			databuf[1] = window;
			e = call I2CBasicAddr.write((I2C_START | I2C_STOP), ADXL345_ADDRESS, 2, databuf);
			if (e!= SUCCESS) {
				error_return = e;
				post windowDone();
			}
			break;

  	}
  }
  
  async event void ResourceRequested.requested(){
  	
  }
  
  async event void ResourceRequested.immediateRequested(){
  
  }
  
  async event void I2CBasicAddr.readDone(error_t error, uint16_t addr, uint8_t length, uint8_t *data){
	uint16_t tmp=0;
	if(call Resource.isOwner()) {
		error_return=error;
		for(tmp=0;tmp<0x8fff;tmp++);		//delay
		tmp= call Resource.release();
		if(adxlcmd == ADXLCMD_READ_X || adxlcmd == ADXLCMD_READ_Y || adxlcmd == ADXLCMD_READ_Z)
		{
		  tmp = data[1];
		  tmp = tmp << 8;
		  tmp = tmp + data[0];
		}
		switch(adxlcmd){
            case ADXLCMD_READ_XYZ: //NOTE moved to speedup
				xyz_axis.x_axis = (data[1] << 8) + data[0];
				xyz_axis.y_axis = (data[3] << 8) + data[2];
                xyz_axis.z_axis = (data[5] << 8) + data[4];
				post calculateXYZ();
				break;
			case ADXLCMD_READ_REGISTER:
				regData=data[0];
				post calculateRegister();
				break;
			case ADXLCMD_READ_DURATION:
				duration=data[0];
				post readDurationDone();
				break;
			case ADXLCMD_READ_LATENT:
				latent=data[0];
				post readLatentDone();
				break;
			case ADXLCMD_READ_WINDOW:
				window=data[0];
				post readWindowDone();
				break;
			case ADXLCMD_READ_POWER_CTL:
				power_ctl=data[0];
				post calculatePowerCtl();
				break;
			case ADXLCMD_READ_BW_RATE:
				bw_rate=data[0];
				post calculateBwRate();
				break;
			case ADXLCMD_READ_INT_ENABLE:
				int_enable=data[0];
				post calculateIntEnable();
				break;
			case ADXLCMD_READ_INT_MAP:
				int_map=data[0];
				post calculateIntMap();
				break;
			case ADXLCMD_READ_INT_SOURCE:
				int_source=data[0];
				post calculateIntSource();
				break;
			case ADXLCMD_READ_X:
				x_axis = tmp;
				post calculateX();
				break;
			case ADXLCMD_READ_Y:
				y_axis = tmp;
				post calculateY();
				break;
			case ADXLCMD_READ_Z:
				z_axis = tmp;
				post calculateZ();
				break;
		}
	}
  }

  async event void I2CBasicAddr.writeDone(error_t error, uint16_t addr, uint8_t length, uint8_t *data){
	if(call Resource.isOwner()) {
		error_return=error;
		if(	adxlcmd != ADXLCMD_READ_XYZ //NOTE moved to speedup
            && adxlcmd != ADXLCMD_READ_REGISTER
			&& adxlcmd != ADXLCMD_READ_DURATION
			&& adxlcmd != ADXLCMD_READ_LATENT
			&& adxlcmd != ADXLCMD_READ_WINDOW
			&& adxlcmd != ADXLCMD_READ_INT_ENABLE
			&& adxlcmd != ADXLCMD_READ_INT_MAP
			&& adxlcmd != ADXLCMD_READ_INT_SOURCE
			&& adxlcmd != ADXLCMD_READ_X
			&& adxlcmd != ADXLCMD_READ_Y 
			&& adxlcmd != ADXLCMD_READ_Z
		)
		{
			call Resource.release();
		}
		switch(adxlcmd){
			case ADXLCMD_READ_XYZ: //NOTE moved to speedup
				if (error==SUCCESS)
                  call I2CBasicAddr.read ((I2C_START | I2C_STOP),  ADXL345_ADDRESS, 6, databuf);	
				else 
				  post calculateXYZ();
				break;
			case ADXLCMD_START:
				post started();
				break;
			case ADXLCMD_READ_REGISTER:
				if (error==SUCCESS)
					call I2CBasicAddr.read ((I2C_START | I2C_STOP),  ADXL345_ADDRESS, 1, databuf);	
				else 
					post calculateRegister();
				break;	
			case ADXLCMD_READ_DURATION:
				if (error==SUCCESS)
					call I2CBasicAddr.read ((I2C_START | I2C_STOP),  ADXL345_ADDRESS, 1, databuf);	
				else 
					post readDurationDone();
				break;	
			case ADXLCMD_READ_LATENT:
				if (error==SUCCESS)
					call I2CBasicAddr.read ((I2C_START | I2C_STOP),  ADXL345_ADDRESS, 1, databuf);	
				else 
					post readLatentDone();
				break;	
			case ADXLCMD_READ_WINDOW:
				if (error==SUCCESS)
					call I2CBasicAddr.read ((I2C_START | I2C_STOP),  ADXL345_ADDRESS, 1, databuf);	
				else 
					post readWindowDone();
				break;	
			case ADXLCMD_READ_POWER_CTL:
				if (error==SUCCESS)
					call I2CBasicAddr.read ((I2C_START | I2C_STOP),  ADXL345_ADDRESS, 1, databuf);	
				else 
					post calculatePowerCtl();
				break;	
			case ADXLCMD_READ_BW_RATE:
				if (error==SUCCESS)
					call I2CBasicAddr.read ((I2C_START | I2C_STOP),  ADXL345_ADDRESS, 1, databuf);	
				else 
					post calculateBwRate();
				break;	
			case ADXLCMD_READ_INT_ENABLE:
				if (error==SUCCESS)
					call I2CBasicAddr.read ((I2C_START | I2C_STOP),  ADXL345_ADDRESS, 1, databuf);	
				else 
					post calculateIntEnable();
				break;	
			case ADXLCMD_READ_INT_MAP:
				if (error==SUCCESS)
					call I2CBasicAddr.read ((I2C_START | I2C_STOP),  ADXL345_ADDRESS, 1, databuf);	
				else 
					post calculateIntMap();
				break;	
			case ADXLCMD_READ_INT_SOURCE:
				if (error==SUCCESS)
					call I2CBasicAddr.read ((I2C_START | I2C_STOP),  ADXL345_ADDRESS, 1, databuf);	
				else 
					post calculateIntSource();
				break;	
			case ADXLCMD_READ_X:
				if (error==SUCCESS)
					call I2CBasicAddr.read((I2C_START | I2C_STOP),  ADXL345_ADDRESS, 2, databuf);	
				else 
					post calculateX();
				break;
			case ADXLCMD_READ_Y:
				if (error==SUCCESS)
					call I2CBasicAddr.read((I2C_START | I2C_STOP),  ADXL345_ADDRESS, 2, databuf);	
				else 
					post calculateY();
				break;
			case ADXLCMD_READ_Z:
				if (error==SUCCESS)
					call I2CBasicAddr.read ((I2C_START | I2C_STOP),  ADXL345_ADDRESS, 2, databuf);	
				else 
					post calculateZ();
				break;
			case ADXLCMD_SET_REGISTER:
				post setRegisterDone();
				break;
			case ADXLCMD_SET_INT_MAP:
				post setIntMapDone();
				break;
			case ADXLCMD_SET_RANGE:
				post rangeDone();
				break;
			case ADXLCMD_STOP:
				post stopped();
				break;
			case ADXLCMD_INT:
				post interruptsDone();
				break;
			case ADXLCMD_SET_DURATION:
				post durationDone();
				break;
			case ADXLCMD_SET_LATENT:
				post latentDone();
				break;
			case ADXLCMD_SET_WINDOW:
				post windowDone();
				break;
	  	}
	 }
  }   
  
  /* default handlers */
  default event void Register.readDone(error_t error, uint8_t data) {
	return;
  }

  default event void Duration.readDone(error_t error, uint8_t data){
  	return;
  }

  default event void Latent.readDone(error_t error, uint8_t data) {
	return;
  }

  default event void Window.readDone(error_t error, uint8_t data) {
	return;
  }
  
  default event void PowerCtl.readDone(error_t error, uint8_t data) {
	return;
  }
  
  default event void BwRate.readDone(error_t error, uint8_t data) {
	return;
  }
  
  default event void IntEnable.readDone(error_t error, uint8_t data) {
	return;
  }

  default event void IntMap.readDone(error_t error, uint8_t data) {
	return;
  }

  default event void IntSource.readDone(error_t error, uint8_t data){
  	return;
  }

  default event void X.readDone(error_t error, uint16_t data){
  	return;
  }	  
  
  default event void Y.readDone(error_t error, uint16_t data){
  	return;
  }	  
  
  default event void Z.readDone(error_t error, uint16_t data){
  	return;
  }	  

  default event void XYZ.readDone(error_t error, adxl345_readxyt_t data){
  	return;
  }
  
  default event void ADXL345Control.setRangeDone(error_t error){
  	return;
  }

  default event void ADXL345Control.setInterruptsDone(error_t error){
  	return;
  }

  default event void ADXL345Control.setRegisterDone(error_t error){
	return;
  }
  
  default event void ADXL345Control.setDurationDone(error_t error){
	return;
  }

  default event void ADXL345Control.setLatentDone(error_t error){
	return;
  }

  default event void ADXL345Control.setWindowDone(error_t error){
	return;
  }

  default event void ADXL345Control.setIntMapDone(error_t error){
	return;
  }

  default event void ADXL345Control.setReadAddressDone(error_t error){
	return;
  } 

  default event void Int1.notify(adxlint_state_t val) {
  }

  default event void Int2.notify(adxlint_state_t val) {
  }
  /*defaut handlers end*/

  event void TimeoutAlarm.fired() {
    if(lock && (adxlcmd == ADXLCMD_START))
    {
      lock = FALSE;
      
      signal SplitControl.startDone(EOFF);
    }
  } 

  command error_t Int1.enable() {
    call GeneralIO1.makeInput();
    return call GpioInterrupt1.enableRisingEdge();
  }

  command error_t Int2.enable() {
    call GeneralIO2.makeInput();
    return call GpioInterrupt2.enableRisingEdge();
  }

  command error_t Int1.disable() {
    return call GpioInterrupt1.disable();
  }

  command error_t Int2.disable() {
    return call GpioInterrupt2.disable();
  }

  task void sendEvent1() {
    signal Int1.notify( 1 );
    call GpioInterrupt1.enableRisingEdge();
  }

  task void sendEvent2() {  
    signal Int2.notify( 1 );
    call GpioInterrupt2.enableRisingEdge();
  }

  async event void GpioInterrupt1.fired() {
    call GpioInterrupt1.disable();

    post sendEvent1();
  }

  async event void GpioInterrupt2.fired() {
    call GpioInterrupt2.disable();
    post sendEvent2();
  }
  
}
