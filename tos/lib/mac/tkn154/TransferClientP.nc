/* 
 * Copyright (c) 2008, Technische Universitaet Berlin
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
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Revision -------------------------------------------------------------
 * $Revision: 1.3 $
 * $Date: 2008-10-21 17:29:00 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */
generic module TransferClientP(uint8_t myUserId)
{
  provides
  {
    interface ResourceTransfer;
    interface ResourceTransferred;
    interface ResourceTransferConnector as TransferredFrom;
  } uses {
    interface ResourceTransferConnector as TransferTo;
    interface ResourceTransferControl;
    interface Leds;
  }
}
implementation
{
  async command error_t ResourceTransfer.transfer()
  {
    error_t result;
    uint8_t toClient = call TransferTo.getUserId();
    atomic {
      result = call ResourceTransferControl.transfer(myUserId, toClient);
      if (result == SUCCESS)
        call TransferTo.transfer();
    }
    return result;
  }

  async command uint8_t TransferredFrom.getUserId(){ return myUserId;}

  async command void TransferredFrom.transfer()
  {
    signal ResourceTransferred.transferred();
  }
  default async command uint8_t TransferTo.getUserId(){ call Leds.led0On(); return 0xFF;}
  default async command void TransferTo.transfer(){ call Leds.led0On(); }
  default async event void ResourceTransferred.transferred(){}
}
