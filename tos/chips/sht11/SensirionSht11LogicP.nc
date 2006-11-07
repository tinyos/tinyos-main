/*
 * Copyright (c) 2005-2006 Arch Rock Corporation
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
 * - Neither the name of the Arch Rock Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * ARCHED ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

#include "Timer.h"
#include "SensirionSht11.h"

/**
 * SensirionSht11LogicP contains the actual driver logic needed to
 * read from the Sensirion SHT11 temperature/humidity sensor. It
 * depends on 2 underlying GeneralIO interfaces, one for the data pin
 * and one for the clock pin, and one underlying GpioInterrupt.  It
 * provides the HAL-level SensirionSht11 interface. It's generic, so
 * you can instantiate it multiple times if you have more than one
 * Sensirion SHT11 attached to a node. 
 * 
 * <p>
 * This code assumes that the MCU clock is less than 10 MHz.  If you
 * ever run this on a faster MCU, you'll need to insert a lot of
 * waits to keep the Sensirion happy.
 *
 * @author Gilman Tolle <gtolle@archrock.com>
 * @version $Revision: 1.3 $ $Date: 2006-11-07 19:31:14 $
 */

generic module SensirionSht11LogicP() {
  provides interface SensirionSht11[ uint8_t client ];

  uses interface GeneralIO as DATA;
  uses interface GeneralIO as CLOCK;
  uses interface GpioInterrupt as InterruptDATA;

  uses interface Timer<TMilli>;

  uses interface Leds;
}
implementation {

  typedef enum {
    CMD_MEASURE_TEMPERATURE = 0x3,
    CMD_MEASURE_HUMIDITY = 0x5,
    CMD_READ_STATUS = 0x7,
    CMD_WRITE_STATUS = 0x6,
    CMD_SOFT_RESET = 0x1E,
  } sht_cmd_t;

  enum {
    TIMEOUT_RESET = 11,
    TIMEOUT_14BIT = 250,
    TIMEOUT_12BIT = 250, //70,
    TIMEOUT_8BIT = 250, //15,
  } sht_timeout_t;

  bool on = TRUE;
  bool busy = FALSE;
  uint8_t status = 0;
  sht_cmd_t cmd;
  uint8_t newStatus;
  bool writeFail = FALSE;

  uint8_t currentClient;

  error_t performCommand();
  void initPins();
  void resetDevice();
  void transmissionStart();
  void sendCommand(uint8_t _cmd);
  void writeByte(uint8_t byte);
  error_t waitForResponse();
  void enableInterrupt();
  uint8_t readByte();
  void ack();
  void endTransmission();

  task void readSensor();
  task void signalStatusDone();

  command error_t SensirionSht11.reset[ uint8_t client ]() {
    if ( !on ) { return EOFF; }
    if ( busy ) { return EBUSY; } else { busy = TRUE; }
    cmd = CMD_SOFT_RESET;
    currentClient = client;
    return performCommand();
  }

  command error_t SensirionSht11.measureTemperature[ uint8_t client ]() {
    if ( !on ) { return EOFF; }
    if ( busy ) { return EBUSY; } else { busy = TRUE; }
    cmd = CMD_MEASURE_TEMPERATURE;
    currentClient = client;
    return performCommand();
  }
  
  command error_t SensirionSht11.measureHumidity[ uint8_t client ]() {
    if ( !on ) { return EOFF; }
    if ( busy ) { return EBUSY; } else { busy = TRUE; }
    cmd = CMD_MEASURE_HUMIDITY;
    currentClient = client;
    return performCommand();
  }

  /* FIXME: these don't seem to work */
  command error_t SensirionSht11.readStatusReg[ uint8_t client ]() {
    if ( !on ) { return EOFF; }
    if ( busy ) { return EBUSY; } else { busy = TRUE; }
    cmd = CMD_READ_STATUS;
    currentClient = client;
    return performCommand();
  }
  
  /* FIXME: these don't seem to work */
  command error_t SensirionSht11.writeStatusReg[ uint8_t client ]( uint8_t val ) {
    if ( !on ) { return EOFF; }
    if ( busy ) { return EBUSY; } else { busy = TRUE; }
    cmd = CMD_WRITE_STATUS;
    newStatus = val;
    currentClient = client;
    return performCommand();
  }

  // performCommand() returns both error_t and status reg -- fortunately, error_t is 8bit
  error_t performCommand() {

    initPins();
    resetDevice();
    transmissionStart();
    cmd &= 0x1F; // clear the first 3 address bits to 000
    sendCommand(cmd);

    if ( waitForResponse() != SUCCESS ) {
      busy = FALSE;
      return FAIL;
    }

    switch(cmd) {

    case CMD_SOFT_RESET:
      call Timer.startOneShot( TIMEOUT_RESET );
      break;

    case CMD_MEASURE_TEMPERATURE:
      enableInterrupt();

      if ( status & SHT11_STATUS_LOW_RES_BIT ) {
	call Timer.startOneShot( TIMEOUT_12BIT );
      } else {
	call Timer.startOneShot( TIMEOUT_14BIT );
      }

      break;

    case CMD_MEASURE_HUMIDITY:
      enableInterrupt();

      if ( status & SHT11_STATUS_LOW_RES_BIT ) {
	call Timer.startOneShot( TIMEOUT_8BIT );
      } else {
	call Timer.startOneShot( TIMEOUT_12BIT );
      }

      break;

    case CMD_READ_STATUS: 
    {
      uint8_t tempStatus;
      uint8_t crc;

      tempStatus = readByte();
      crc = readByte();
      endTransmission();

      status = tempStatus; // FIXME: need to check CRC!
      
      post signalStatusDone();
    }
    
    case CMD_WRITE_STATUS:
      writeByte( newStatus );
      
      if ( waitForResponse() != SUCCESS ) {
	writeFail = TRUE;
      } else {
	status = newStatus;
      }
      
      post signalStatusDone();
    }

    // leave the device busy...we're waiting for an interrupt
    return SUCCESS;
  }

  void initPins() {
    call CLOCK.makeOutput();
    call CLOCK.clr();
    call DATA.makeInput();
    call DATA.set();
    call InterruptDATA.disable();
  }
  
  void resetDevice() {
    uint8_t i;
    call DATA.makeOutput();
    call DATA.set();
    call CLOCK.clr();
    for( i = 0; i < 9; i++ ) {
      call CLOCK.set();
      call CLOCK.clr();
    }
  }

  void transmissionStart() {
    call DATA.makeOutput();
    call DATA.set();
    call CLOCK.clr();
    call CLOCK.set();
    call DATA.clr();
    call CLOCK.clr();
    call CLOCK.set();
    call DATA.set();
    call CLOCK.clr();
  }

  void sendCommand(uint8_t _cmd) {
    writeByte(_cmd);
  }

  void writeByte(uint8_t byte) {
    uint8_t i;
    for( i = 0; i < 8; i++ ) {
      if ( byte & 0x80 )
	call DATA.set();
      else
	call DATA.clr();
      byte = byte << 1;
      call CLOCK.set();
      call CLOCK.clr();
    }
  }

  error_t waitForResponse() {
    call DATA.makeInput();
    call DATA.set();
    call CLOCK.set();
    if (call DATA.get()) {
      // the device didn't pull the DATA line low
      // the command wasn't received or acknowledged
      return FAIL;
    }
    call CLOCK.clr();
    return SUCCESS;
  }

  void enableInterrupt() {
    call DATA.makeInput();
    call DATA.set();
    call InterruptDATA.enableFallingEdge();
  }

  event void Timer.fired() {

    switch(cmd) {

    case CMD_SOFT_RESET:
      // driver has waited long enough for device to reset
      busy = FALSE;
      signal SensirionSht11.resetDone[currentClient]( SUCCESS );
      break;

    case CMD_MEASURE_TEMPERATURE:
      // timeout expired with no data interrupt
      busy = FALSE;
      signal SensirionSht11.measureTemperatureDone[currentClient]( FAIL, 0 );
      break;

    case CMD_MEASURE_HUMIDITY:
      // timeout expired with no data interrupt
      busy = FALSE;
      signal SensirionSht11.measureHumidityDone[currentClient]( FAIL, 0 );
      break;

    default:
      // we're in an unexpected state. what to do?
      break;
    }
  }

  async event void InterruptDATA.fired() {
    call InterruptDATA.disable();
    post readSensor();
  }

  task void readSensor() {
    uint16_t data = 0;
    uint8_t crc = 0;

    if ( busy == FALSE ) {
      // the interrupt was received after the timeout. 
      // we've already signaled FAIL to the client, so just give up.
      return;
    }

    call Timer.stop();

    data = readByte() << 8;
    data |= readByte();

    crc = readByte();
    
    endTransmission();

    switch( cmd ) {
    case CMD_MEASURE_TEMPERATURE:
      busy = FALSE;
      signal SensirionSht11.measureTemperatureDone[currentClient]( SUCCESS, data );
      break;

    case CMD_MEASURE_HUMIDITY:
      busy = FALSE;
      signal SensirionSht11.measureHumidityDone[currentClient]( SUCCESS, data );
      break;

    default:
      break; // unknown command - shouldn't reach here
    }
  }

  uint8_t readByte() {
    uint8_t byte = 0;
    uint8_t i;

    for( i = 0; i < 8; i++ ) {
      call CLOCK.set();
      if (call DATA.get())
	byte |= 1;
      if (i != 7) 
	byte = byte << 1;
      call CLOCK.clr();
    }

    ack();
    return byte;
  }

  void ack() {
    call DATA.makeOutput();
    call DATA.clr();
    call CLOCK.set();
    call CLOCK.clr();
    call DATA.makeInput();
    call DATA.set();
  }
  
  void endTransmission() {
    call DATA.makeOutput();
    call DATA.set();
    call CLOCK.set();
    call CLOCK.clr();
  }

  task void signalStatusDone() {
    bool _writeFail = writeFail;
    switch( cmd ) {
    case CMD_READ_STATUS:
      busy = FALSE;
      signal SensirionSht11.readStatusRegDone[currentClient]( SUCCESS, status );
      break;
    case CMD_WRITE_STATUS:
      busy = FALSE;
      writeFail = FALSE;
      signal SensirionSht11.writeStatusRegDone[currentClient]( (_writeFail ? FAIL : SUCCESS) );
      break;
    default:
      // shouldn't happen.
      break;
    }
  }

  default event void SensirionSht11.resetDone[uint8_t client]( error_t result ) { }
  default event void SensirionSht11.measureTemperatureDone[uint8_t client]( error_t result, uint16_t val ) { }
  default event void SensirionSht11.measureHumidityDone[uint8_t client]( error_t result, uint16_t val ) { }
  default event void SensirionSht11.readStatusRegDone[uint8_t client]( error_t result, uint8_t val ) { }
  default event void SensirionSht11.writeStatusRegDone[uint8_t client]( error_t result ) { }
}

