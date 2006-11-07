/*
 * Copyright (c) 2004, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES {} LOSS OF USE, DATA,
 * OR PROFITS {} OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Description ---------------------------------------------------------
 * - Revision -------------------------------------------------------------
 * $Revision: 1.3 $
 * $Date: 2006-11-07 19:31:15 $
 * @author Kevin Klues (klues@tkn.tu-berlin.de)
 * ========================================================================
 */

module Tda5250RegCommP {
  provides {
    interface Init;
    interface Tda5250RegComm;
    interface Resource;
  }
  uses {
    interface GeneralIO as BusM;
    interface Resource as SpiResource;
    interface SpiByte;
  }
}

implementation {

   command error_t Init.init() {
     // setting pins to output
     call BusM.makeOutput();

     //initializing pin values
     call BusM.set();  //Use SPI for writing to Regs

     return SUCCESS;
   }

   async command error_t Resource.request() {
     return call SpiResource.request();
   }

   async command error_t Resource.immediateRequest() {
     if(call SpiResource.immediateRequest() == EBUSY)
       return EBUSY;
     return SUCCESS;
   }

   async command bool Resource.isOwner() {
     return call SpiResource.isOwner();
   }

   async command error_t Resource.release() {
     return call SpiResource.release();
   }

   event void SpiResource.granted() {
     signal Resource.granted();
   }

   async command error_t Tda5250RegComm.writeByte(uint8_t address, uint8_t data) {
     if(call SpiResource.isOwner() == FALSE) {
       return FAIL;
     }
     call SpiByte.write(address);
     call SpiByte.write(data);
     return SUCCESS;
   }
   
   async command error_t Tda5250RegComm.writeWord(uint8_t address, uint16_t data) {
      if(call SpiResource.isOwner() == FALSE)
        return FAIL;
      call SpiByte.write(address);
      call SpiByte.write(((uint8_t) (data >> 8)));
      call SpiByte.write(((uint8_t) data));
      return SUCCESS;
   }

   async command uint8_t Tda5250RegComm.readByte(uint8_t address){
      if(call SpiResource.isOwner() == FALSE)
        return 0x00;
      call SpiByte.write(address);

      // FIXME: Put SIMO/SOMI in input
      return call SpiByte.write(0x00);
   }

}
