/*
 * Copyright (c) 2008 Rincon Research Corporation
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
 * - Neither the name of the Rincon Research Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * RINCON RESEARCH OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

/**
 * The adg715 hardware provides 8 channels which are controlled using
 * an I2C interface.  The channels here are provided using a
 * parameterized interface but are checked for being out of bounds
 * (ADG715_CH_MIN and ADG715_CH_MAX from the header file).
 * The channels can only be controlled one at a time and they will
 * be controlled through the I2CPacket interface which is used by
 * this module.
 * 
 * @author Danny Park
 */

#include <I2C.h>
#include "Adg715.h"

generic module Adg715ControlP(bool pinA1High, bool pinA0High) {
	uses {
		interface I2CPacket<TI2CBasicAddr>;
		interface Resource;
		interface Leds;
	}
		provides {
		interface Channel[uint8_t channel];
		interface Init;
	}
}
implementation {
	/**************** Global Variables ****************/
	/** TRUE if this module is busy and cannot accept another command */
	bool busy;
	/** In process of opening a channel if TRUE and busy is TRUE */
	bool opening;
	/** In process of closing a channel if TRUE and busy is TRUE */
	bool closing;
	/** Setting of previous command or command currently in process */
	uint8_t mySetting;
	/** Current channel being set if busy is TRUE */
	uint8_t currentChannel;
	/** I2C address that is set based on compile time parameters */
	uint16_t myAddress;
	/**************** Prototypes ****************/
	task void successTask();
	task void failTask();
	/**************** Init Interface Commands ****************/
	/**
	* Initialization command that fires once during boot up.
	*/
	command error_t Init.init() {
		if(pinA1High && pinA0High) {
			myAddress = ADG715_BASE_ADDR | ADG715_PIN_A1_HIGH | ADG715_PIN_A0_HIGH;
		} else if(pinA1High) {
			myAddress = ADG715_BASE_ADDR | ADG715_PIN_A1_HIGH;
		} else if(pinA0High) {
			myAddress = ADG715_BASE_ADDR | ADG715_PIN_A0_HIGH;
		} else {
			myAddress = ADG715_BASE_ADDR;
		}    
		mySetting = 0x00;
		busy = FALSE;
		opening = FALSE;
		closing = FALSE;
		return SUCCESS;
	}
  
	/**************** Channel Interface Commands ****************/
	/**
	* Starts the opening of the given channel or returns an error.
	* If SUCCESS is returned then an openDone event will be signalled.
	* 
	* @param channel The channel to be opened (limited between
	*   ADG715_CH_MIN and ADG715_CH_MAX).
	*/
	command error_t Channel.open[uint8_t channel]() {
		if(channel > ADG715_CH_MAX || channel < ADG715_CH_MIN) {
			return ESIZE;
		} else if(busy) {
			return EBUSY;
		} else {
			busy = TRUE;
			opening = TRUE;
			currentChannel = channel;
			mySetting |= ADG715_CH_OPEN << (channel - 1);
			call Resource.request();
			return SUCCESS;
		}
	}
  
	/**
	* Starts the closing of the given channel or returns an error.
	* If SUCCESS is returned then a closeDone event will be signalled.
	* 
	* @param channel The channel to be closed (limited between
	*   ADG715_CH_MIN and ADG715_CH_MAX).
	*/
	command error_t Channel.close[uint8_t channel]() {
		if(channel > ADG715_CH_MAX || channel < ADG715_CH_MIN) {
			return ESIZE;
		} else if(busy) {
			return EBUSY;
		} else {
			busy = TRUE;
			closing = TRUE;
			currentChannel = channel;
//			mySetting &= ADG715_CH_CLOSE << (channel - 1);
			mySetting ^= ADG715_CH_OPEN << (channel - 1);
			call Resource.request();
			return SUCCESS;
		}
	}
  
	/**
	* Open status of the given channel.
	* 
	* @param channel The channel to be closed (limited between
	*   ADG715_CH_MIN and ADG715_CH_MAX).
	* @return TRUE if the given channel is open, FALSE otherwise.
	*/
	command bool Channel.isOpen[uint8_t channel]() {
		return ((mySetting >> (channel - 1)) & ADG715_CH_OPEN)== ADG715_CH_OPEN;
	}
  
	/**************** Resource Interface Events ****************/
	/**
	* Signalled when the I2CBus is available for use.
	*/
	event void Resource.granted() {
		call I2CPacket.write(I2C_START|I2C_STOP, myAddress, ADG715_CMD_LEN, &mySetting);
	}
  
	/**************** I2CPacket Interface Events ****************/
	async event void I2CPacket.readDone(error_t error, uint16_t addr, uint8_t length, uint8_t* data) {}

	async event void I2CPacket.writeDone(error_t error, uint16_t addr, uint8_t length, uint8_t* data) {
		if(addr == myAddress) {
			if(length == ADG715_CMD_LEN && data == &mySetting) {
				call  Resource.release();	
				if(error == SUCCESS){
					post successTask();
				} else {
					post failTask();
				}
			}
		}
	}
	/**************** Local Tasks ****************/
	task void successTask() {
		if(busy) {
			/**
			* If busy is not released before signalling a *Done() event
			* then a serial call of open/close channels on the same
			* chip will fail with EBUSY.
			*/
			busy = FALSE;
			if(opening) {
				opening = FALSE;
				if(((mySetting >> (currentChannel - 1)) & ADG715_CH_OPEN)== ADG715_CH_OPEN) {
					signal Channel.openDone[currentChannel](SUCCESS);
				} else {
					signal Channel.openDone[currentChannel](FAIL);
				}
			} else if(closing) {
				closing = FALSE;
				if(((mySetting >> (currentChannel - 1)) & ADG715_CH_OPEN)== ADG715_CH_CLOSE) {
					signal Channel.closeDone[currentChannel](SUCCESS);
				} else {
					signal Channel.closeDone[currentChannel](FAIL);
				}
			} 
		}
	}
  
	task void failTask() {
		if(busy) {
			/**
			* If busy is not released before signalling a *Done() event
			* then a serial call of open/close channels on the same
			* chip will fail with EBUSY.
			*/
			busy = FALSE;
			if(opening) {
				opening = FALSE;
				signal Channel.openDone[currentChannel](FAIL);
			}
			if(closing) {
				closing = FALSE;
				signal Channel.closeDone[currentChannel](FAIL);
			}
		}
	}
  
	/**************** Channel Interface Defaults ****************/
	default event void Channel.openDone[uint8_t channel](error_t error) {}
	default event void Channel.closeDone[uint8_t channel](error_t error) {}
}
