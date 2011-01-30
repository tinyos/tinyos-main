/*
 * Copyright (c) 2010 CSIRO
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the University of California nor the names of
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

/**
 * Simple test program for SAM3U's UDPHS HPL interface
 * @author Kevin Klues <kevin.klues@csiro.au>
 */

//#include <sam3uudphshardware.h>
//#include <printf.h>

module MoteP
{
  uses {
    interface Boot;
    interface StdControl;
    interface UartStream;
    interface Leds;
  }
}

implementation
{
  #define READBUFFERSIZE 64
  #define WRITEBUFFERSIZE 100
  int i=0;
  uint8_t readBuffer[READBUFFERSIZE];
  uint8_t writeBuffer[WRITEBUFFERSIZE];

  event void Boot.booted() {
    // Start it up!
    call StdControl.start();

    for(i=0; i<WRITEBUFFERSIZE; i++)
      writeBuffer[i] = i;
    
    while(call UartStream.receive(readBuffer, READBUFFERSIZE) != SUCCESS);
    while(call UartStream.send(writeBuffer, WRITEBUFFERSIZE) != SUCCESS);
  }

  async event void UartStream.sendDone( uint8_t* buf, uint16_t len, error_t error ) {
    while(call UartStream.send(writeBuffer, WRITEBUFFERSIZE) != SUCCESS);
  }

  async event void UartStream.receivedByte( uint8_t byte ) {
  }

  async event void UartStream.receiveDone( uint8_t* buf, uint16_t len, error_t error ) {
    while(call UartStream.receive(readBuffer, READBUFFERSIZE) != SUCCESS);
  }
}

