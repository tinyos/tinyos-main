/*
 * Copyright (c) 2011 University of Utah
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
 * - Neither the name of the copyright holders nor the names of its
 *   contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
 * AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 * WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#include <sam3uusarthardware.h>
module Sam3uUsart2P {
  provides interface Sam3uUsart;
  uses interface HplSam3uUsartControl as HplUsart;
  uses interface Leds;
}

implementation{

  uint32_t mode_register = AT91C_US_USMODE_NORMAL
    | AT91C_US_CLKS_CLOCK
    | AT91C_US_CHRL_8_BITS
    | AT91C_US_PAR_NONE
    | AT91C_US_NBSTOP_1_BIT
    | AT91C_US_CHMODE_NORMAL;

  bool STREAM = FALSE;
  uint8_t total_send_length, current_length_position;
  uint8_t *sending_data_ptr;

  command void Sam3uUsart.start(uint32_t baud){
    call HplUsart.init();
    call HplUsart.configure(mode_register, baud);

    call HplUsart.enableTx();
    call HplUsart.enableRx();

    signal Sam3uUsart.startDone(SUCCESS);
  }

  command error_t Sam3uUsart.stop(){    
    call HplUsart.disableTx();
    call HplUsart.disableRx();

    signal Sam3uUsart.stopDone(SUCCESS);
  }

  command void Sam3uUsart.sendStream(void* msg, uint8_t length){
    // send data byte by byte
    uint8_t data;
    total_send_length = length;
    current_length_position = 0;
    STREAM = TRUE;
    sending_data_ptr = msg;
    data = sending_data_ptr[0];
    call HplUsart.write(0, data, 0);
  }

  command void Sam3uUsart.send(uint8_t data){
    // send data byte by byte
    STREAM = FALSE;
    call HplUsart.write(0, data, 0);
  }

  command void Sam3uUsart.listen(void* msg, uint8_t length){
  }

  event void HplUsart.writeDone(){
    current_length_position ++ ;
    if(!STREAM){
      signal Sam3uUsart.sendDone(SUCCESS);
      return;
    }else {
      current_length_position ++ ;
      if(total_send_length > current_length_position){
	call HplUsart.write(0, (uint8_t)sending_data_ptr[current_length_position], 0);
      }else{
	STREAM = FALSE;
	signal Sam3uUsart.sendDone(SUCCESS);
	return;
      }
    }
  }

  uint8_t rxdata;
  task void signalReceive(){
    signal Sam3uUsart.receive(SUCCESS, rxdata);
  }

  event void HplUsart.readDone(uint8_t data){
    rxdata = data;
    post signalReceive();
  }

 default event void Sam3uUsart.sendDone(error_t error){}
 default event void Sam3uUsart.receive(error_t error, uint8_t data){}
 default event void Sam3uUsart.startDone(error_t error){}
 default event void Sam3uUsart.stopDone(error_t error){}

}
