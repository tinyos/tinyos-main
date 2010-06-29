/*
* Copyright (c) 2008 Johns Hopkins University.
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

/**
 * @author JeongGil Ko
 * @author Razvan Musaloiu-E.
 * @author Jong Hyun Lim
 */

module CC2420KeysP
{
  provides interface CC2420Keys;

  uses {
    interface GeneralIO as CSN;
    interface CC2420Ram as KEY0;
    interface CC2420Ram as KEY1;
    interface Resource;
  }
}

implementation
{
  uint8_t *currentKey = NULL;
  bool currentKeyNo;

  task void resourceReq()
  {
    error_t error;
    error = call Resource.immediateRequest();
    if(error != SUCCESS){
      post resourceReq();
    }
  }

  command error_t CC2420Keys.setKey(uint8_t keyNo, uint8_t* key)
  {
    if (currentKey != NULL || keyNo > 1) {
      return FAIL;
    }
    currentKey = key;
    currentKeyNo = keyNo;

    if(call Resource.request() != SUCCESS){
      post resourceReq();
    }

    return SUCCESS;
  }

  event void Resource.granted()
  {
    if (currentKeyNo) {
      call CSN.clr();
      call KEY1.write(0, currentKey, 16);
      call CSN.set();
    } else {
      call CSN.clr();
      call KEY0.write(0, currentKey, 16);
      call CSN.set();
    }
    call Resource.release();
    currentKey = NULL;
    signal CC2420Keys.setKeyDone(currentKeyNo, currentKey);
  }
}
