#include "TMP102.h"


module SimpleTMP102P {
   provides interface Read<uint16_t>;
   uses {
    interface Timer<TMilli> as TimerSensor;
    interface Timer<TMilli> as TimerFail;
  	interface Resource;
  	interface ResourceRequested;
  	interface I2CPacket<TI2CBasicAddr> as I2CBasicAddr;        
  }
   
}
implementation {
  
  uint16_t temp;
  uint8_t pointer;
  uint8_t temperaturebuff[2];
  uint16_t tmpaddr;
  
  norace uint8_t tempcmd;
    
  task void calculateTemp(){
	uint16_t tmp;
  	atomic tmp = temp;
  	signal Read.readDone(SUCCESS, tmp);
  }
  
  command error_t Read.read(){
	atomic P5DIR |= 0x01;
	atomic P5OUT |= 0x01;
	call TimerSensor.startOneShot(100);
	//call TimerFail.startOneShot(1024);
	return SUCCESS;
  }

  event void TimerSensor.fired() {
	call Resource.request();  
  }
  
  event void TimerFail.fired() {
  	signal Read.readDone(SUCCESS, 0);
  }

  event void Resource.granted(){
	error_t error;
	pointer = TMP102_TEMPREG;
	tempcmd = TMP_READ_TMP;
	error= call I2CBasicAddr.write((I2C_START | I2C_STOP), TMP102_ADDRESS, 1, &pointer); 
	if(error)
	{
		call Resource.release();
		signal Read.readDone(error, 0);
	}
  }
  
  async event void ResourceRequested.requested(){
  
  }
  
  async event void ResourceRequested.immediateRequested(){
  
  }
  
  async event void I2CBasicAddr.readDone(error_t error, uint16_t addr, uint8_t length, uint8_t *data){
    if(call Resource.isOwner()) {
	uint16_t tmp;
	for(tmp=0;tmp<0xffff;tmp++);	//delay
	call Resource.release();
	tmp = data[0];
	tmp = tmp << 8;
	tmp = tmp + data[1];
	tmp = tmp >> 4;
	atomic temp = tmp;
	post calculateTemp();
	}
  }

  async event void I2CBasicAddr.writeDone(error_t error, uint16_t addr, uint8_t length, uint8_t *data){
	//printfUART("write done in temp\n");
	if(call Resource.isOwner()){
		error_t e;
		e = call I2CBasicAddr.read((I2C_START | I2C_STOP),  TMP102_ADDRESS, 2, temperaturebuff);
		if(e)
		{
			call Resource.release();
			signal Read.readDone(error, 0);
		}
  	}
  }   
  
	  
  
}
