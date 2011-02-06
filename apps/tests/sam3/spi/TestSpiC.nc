/**
 * Copyright (c) 2009 The Regents of the University of California.
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
 * - Neither the name of the copyright holder nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * COPYRIGHT HOLDER OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * @author Thomas Schmid
 **/

module TestSpiC
{
  uses interface Leds;
  uses interface Boot;
  uses interface SpiByte;
  uses interface SpiPacket;
  uses interface HplSam3SpiConfig as SpiConfig;
  uses interface Resource as SpiResource;

}
implementation
{
  task void transferPacketTask()
  {
    uint8_t tx_buf[10];
    uint8_t rx_buf[10];
    uint8_t i;

    for(i=0; i<10; i++)
    {
      tx_buf[i] = 0xA0 + i;
      rx_buf[i] = 0;
    }


    call SpiPacket.send(tx_buf, rx_buf, 10);
  }

  task void transferTask()
  {
    uint8_t byte;


    byte = call SpiByte.write(0xCD);
    if(byte == 0xCD)
    {
      call Leds.led0Toggle();
    } else {
      call Leds.led1Toggle();
    }
    byte = call SpiByte.write(0xAB);
    if(byte == 0xAB)
    {
      call Leds.led0Toggle();
    } else {
      call Leds.led1Toggle();
    }

    post transferPacketTask();
    //post transferTask();
  }

  event void Boot.booted()
  {
    call SpiResource.request();

  }

  event void SpiResource.granted()
  {
    call SpiConfig.enableLoopBack();

    post transferTask();
    //post transferPacketTask();

  }

  async event void SpiPacket.sendDone(uint8_t* tx_buf, uint8_t* rx_buf, uint16_t len, error_t error)
  {
    uint8_t i;

    if(error == SUCCESS)
    {
      if(len == 10)
      {
        for(i=0; i<10; i++){
          if(rx_buf[i] != 0xCD)
          {
            call Leds.led1Toggle();
          } else {
            call Leds.led2Toggle();
          }
        }
        call Leds.led0Toggle();
      }
    }
    call Leds.led1Toggle();
  }
}
