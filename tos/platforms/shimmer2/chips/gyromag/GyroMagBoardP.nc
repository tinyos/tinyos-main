/*
 * Copyright (c) 2010, Shimmer Research, Ltd.
 * All rights reserved
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:

 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer in the documentation and/or other materials provided
 *       with the distribution.
 *     * Neither the name of Shimmer Research, Ltd. nor the names of its
 *       contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.

 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *
 * @author Steve Ayer
 * @date March, 2010
 *
 * this module adds functionality of honeywell hmc5843 magnetometer
 * to similar gyro board (idg-500 3-axis plus user button and led)
 *
 * since gyro board is stand-alone, this module uses existing gyro module
 * and interface for everything but magnetometer.
 */

#include "Magnetometer.h"

module GyroMagBoardP {
  provides {
    interface Init;
    interface StdControl;
    interface GyroMagBoard;
  }
  uses {
    interface GyroBoard;

    interface I2CPacket<TI2CBasicAddr> as I2CPacket;

    interface HplMsp430I2C as HplI2C;
    interface HplMsp430Usart as Usart;
    interface HplMsp430UsartInterrupts as UsartInterrupts;
    interface HplMsp430I2CInterrupts as I2CInterrupts;

    interface Init as GyroInit;
    interface StdControl as GyroStdControl;
    interface Leds;
    interface Timer<TMilli> as testTimer;
  }
}

implementation {
  extern int sprintf(char *str, const char *format, ...) __attribute__ ((C));
  extern int snprintf(char *str, size_t len, const char *format, ...) __attribute__ ((C));

  uint8_t readbuff[7], testPhase;
  uint8_t packet[2], readSize, * readDataBuffer;

  enum {
    INIT,
    WRITE,
    READ,
    IDLE,
  };

  command error_t Init.init() {
    msp430_i2c_union_config_t msp430_i2c_my_config = { 
      {
	rxdmaen : 0, 
	txdmaen : 0, 
	xa : 0, 
	listen : 0, 
	mst : 1,
	i2cword : 0, 
	i2crm : 1, 
	i2cssel : 0x2, 
	i2cpsc : 0, 
	i2csclh : 0x3, 
	i2cscll : 0x3,
	i2coa : 0,
      } 
    };

    
    /*
     * same power pin as gyro regulator, this will bring up second power pin (first tied to
     * shimmer regulator).  it turns on in idle mode
     */
    call GyroInit.init();

    call HplI2C.setModeI2C(&msp430_i2c_my_config);

    testPhase = 0;

    return SUCCESS;
  }

  command error_t StdControl.start(){
    call GyroStdControl.start();

    // mag ready time nominally 5ms, though we have lots of lag in gyro power-up called in init
    //    TOSH_uwait(5000UL);

    return SUCCESS;
  }

  command error_t StdControl.stop(){
    call GyroStdControl.stop();

    return SUCCESS;
  }

  // GyroBoard wrappers
  command void GyroMagBoard.ledOn() {
    call GyroBoard.ledOn();
  }
  command void GyroMagBoard.ledOff() {
    call GyroBoard.ledOff();
  }
  command void GyroMagBoard.ledToggle() {
    call GyroBoard.ledToggle();
  }

  async event void GyroBoard.buttonPressed() {
    signal GyroMagBoard.buttonPressed();
  }

  // for gyro, use use GyroStdControl, see platform's GyroMagBoardC
  command void GyroMagBoard.gyroAutoZero() {
    call GyroBoard.autoZero();
  }
  
  error_t writeRegValue(uint8_t reg_addr, uint8_t val) {
    //    uint8_t packet[2];

    // pack the packet with address of reg target, then register value
    packet[0] = reg_addr;
    packet[1] = val;

    call I2CPacket.write(I2C_START | I2C_STOP, 0x1e, 2, packet);
    return SUCCESS;
  }
  command void GyroMagBoard.writeReg(uint8_t reg_addr, uint8_t val) {
    writeRegValue(reg_addr, val);
  }
  error_t readValues(uint8_t size, uint8_t * data){
    readSize = size;
    readDataBuffer = data;

    call I2CPacket.read(I2C_START | I2C_STOP, 0x1e, size, data);
    return SUCCESS;
  }

  async event void UsartInterrupts.rxDone( uint8_t data ) {}
  async event void UsartInterrupts.txDone() {}
  async event void I2CInterrupts.fired() {}

  /*
   * 0.5, 1, 2, 5, 10 (default), 20, 50hz.  20 and 50 up power burn dramatically
   * bits 2-4 control this, values 0 - 6 map to values above, respectively
   * since the remainder of the register defaults to 0, we write the mask directly
   */
  command error_t GyroMagBoard.setMagOutputRate(uint8_t rate){
    uint8_t ret = SUCCESS, bitmask = 0x10;  // default 10hz

    switch(rate){
    case 0:
      bitmask = 0;
      break;
    case 1:
      bitmask = 0x04;
      break;
    case 2:
      bitmask = 0x08;
      break;
    case 3:
      bitmask = 0x0c;
      break;
    case 4:
      bitmask = 0x10;
      break;
    case 5:
      bitmask = 0x14;
      break;
    case 6:
      bitmask = 0x18;
      break;
    default:
      ret = FAIL;  // input value unknown, using default
      break;
    }
    writeRegValue(0, bitmask);
    
    return ret;
  }

  /*
   * weird way to do this, but we need to leave the mag time
   * to run tests without disabling the i2c bus with TOSH_uwait
   *
   * read results from readDone event
   */
  command void GyroMagBoard.magSelfTest(){
    switch(testPhase++){
    case 0:
      call testTimer.startPeriodic(5);
      call Leds.led1On();
      call GyroMagBoard.writeReg(0, 0x11);
      break;
    case 1:
      call Leds.led1Off();
      call GyroMagBoard.writeReg(2, 0x01);
      break;
    case 2:
      call Leds.led1On();
      call GyroMagBoard.readMagData();
      break;
    case 3:
      call Leds.led1Off();
      call GyroMagBoard.writeReg(0, 0x10);
      break;
    default:
      call testTimer.stop();
      testPhase = 0;
      break;
    }
  }

  event void testTimer.fired() {
    call GyroMagBoard.magSelfTest();
  }

  // +-0.7, 1.0 (default), 1.5, 2.0, 3.2, 3.8, 4.5Ga
  command error_t GyroMagBoard.setMagGain(uint8_t gain){ 
    uint8_t ret = SUCCESS, bitmask = 0x20;  // default 1.0Ga

    switch(gain){
    case 0:
      bitmask = 0x00;
      break;
    case 1:
      bitmask = 0x20;
      break;
    case 2:
      bitmask = 0x40;
      break;
    case 5:
      bitmask = 0x50;
      break;
    case 10:
      bitmask = 0x80;
      break;
    case 20:
      bitmask = 0x90;
      break;
    case 50:
      bitmask = 0xc0;
      break;
    default:
      ret = FAIL;  // input value unknown, using default
      break;
    }
    writeRegValue(1, bitmask);
    
    return ret;
  }

  command error_t GyroMagBoard.setMagIdle(){
    writeRegValue(2, 0x02);
    return SUCCESS;
  }

  command error_t GyroMagBoard.magGoToSleep(){
    writeRegValue(2, 0x03);
    return SUCCESS;
  }


  command error_t GyroMagBoard.magRunSingleConversion(){
    writeRegValue(2, 0x01);
    return SUCCESS;
  }
    

  command error_t GyroMagBoard.magRunContinuousConversion(){
    writeRegValue(2, 0x00);
    return SUCCESS;
  }

  /*
   * returning the real value doesn't help; 
   * success is measured in the magreaddone event
   */
  command error_t GyroMagBoard.readMagData(){
    readValues(7, readbuff);
    return SUCCESS;
  }
  
  uint16_t mag_to_heading(uint16_t x, uint16_t y, uint16_t z)
  {
    uint16_t heading;

    if(x == 0){
      if(y < 0)
	heading = 270;
      else
	heading = 90;
    }
    else if(z < 0)
      heading = (uint16_t)(180.0 - atanf((float)y/(float)-x));

    else
      heading = (uint16_t)(180.0 - atanf((float)y/(float)x));
    
    return heading;
  }

  int16_t twos_comp_pack(uint8_t up, uint8_t low) 
  {
    int16_t out;
    uint16_t uout;
    
    uout = up;
    uout = uout << 8;
    uout |= low;

    out = (int16_t)uout;

    return out;
  }

  // call this to see three-axis magnetometer values
  command void GyroMagBoard.convertMagRegistersToData(uint8_t * readBuf, int16_t * data){
    uint8_t * src;
    register uint8_t i;

    src = readBuf;

    // this loop is just for the three 16-bit x,y,z values
    for(i = 0; i < 3; i++){
      data[i] = twos_comp_pack(*src, *(src + 1));
      src += 2;
    }
  }    

  // call after readDone event
  command uint16_t GyroMagBoard.readMagHeading(uint8_t * readBuf){
    int16_t realVals[3];
    uint16_t heading;

    call GyroMagBoard.convertMagRegistersToData(readBuf, realVals);

    heading = mag_to_heading(realVals[0], realVals[1], realVals[2]);

    return heading;
  }
  /*
  error_t poke(uint8_t val) {
    return call I2CPacket.writePacket(0x1e, 1, &val);
  }
  error_t peek(uint8_t * val) {
    return call I2CPacket.readPacket(0x1e, 1, val);
  }
  */
  async event void I2CPacket.readDone(error_t success, uint16_t addr, uint8_t length, uint8_t* data) {
    signal GyroMagBoard.magReadDone(data, success);
  }

  async event void I2CPacket.writeDone(error_t success, uint16_t addr, uint8_t length, uint8_t* data) {
    signal GyroMagBoard.magWriteDone(success);
  }
  /*
  // these will trigger from the i2civ, but separate interrupts are available in i2cifg (separate enable, too).
  async event void I2CEvents.arbitrationLost() { }
  async event void I2CEvents.noAck() { }
  async event void I2CEvents.ownAddr() { }
  async event void I2CEvents.readyRegAccess() { }
  async event void I2CEvents.readyRxData() { }
  async event void I2CEvents.readyTxData() { }
  async event void I2CEvents.generalCall() { }
  async event void I2CEvents.startRecv() { }
  */
}
  





