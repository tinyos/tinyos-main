/*
* Copyright (c) 2011, University of Szeged
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions
* are met:
*
* - Redistributions of source code must retain the above copyright
* notice, this list of conditions and the following disclaimer.
* - Redistributions in binary form must reproduce the above
* copyright notice, this list of conditions and the following
* disclaimer in the documentation and/or other materials provided
* with the distribution.
* - Neither the name of University of Szeged nor the names of its
* contributors may be used to endorse or promote products derived
* from this software without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
* "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
* FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
* COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
* INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
* (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
* SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
* HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
* STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
* OF THE POSSIBILITY OF SUCH DAMAGE.
*
* Author: Andras Biro
*/

generic module Ms5607ConversionPressP(){
  provides interface Read<uint32_t>;
  uses interface Read<int32_t> as ReadDt;
  uses interface Read<uint32_t> as ReadRawPress;
  uses interface Get<uint16_t>[uint8_t index];
}
implementation{
  int32_t dT;
  command error_t Read.read(){
    return call ReadDt.read();
  }
  
  event void ReadDt.readDone(error_t err, int32_t value){
    if(err==SUCCESS){
      dT=value;
      err=call ReadRawPress.read();
    }
    if(err!=SUCCESS)
      signal Read.readDone(err, 0);
  }
  
  event void ReadRawPress.readDone(error_t err, uint32_t value){
    if(err!=SUCCESS)
      signal Read.readDone(err, 0);
    else {
      int64_t off=((uint64_t)call Get.get[1]()<<17)+(((int64_t)dT*call Get.get[3]())>>6);
      int64_t sens=((uint32_t)call Get.get[0]()<<16)+(((int64_t)dT*call Get.get[2]())>>7);
      uint32_t p=((((uint64_t)value*sens)>>21)-off)>>15;
      signal Read.readDone(SUCCESS, p);
    }
  }
}

