/*
* Copyright (c) 2008 Johns Hopkins University.
* All rights reserved.
*
* Permission to use, copy, modify, and distribute this software and its
* documentation for any purpose, without fee, and without written
* agreement is hereby granted, provided that the above copyright
* notice, the (updated) modification history and the author appear in
* all copies of this source code.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS  `AS IS'
* AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED  TO, THE
* IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR  PURPOSE
* ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR  CONTRIBUTORS
* BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
* CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, LOSS OF USE,  DATA,
* OR PROFITS) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
* CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR  OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
* THE POSSIBILITY OF SUCH DAMAGE.
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
