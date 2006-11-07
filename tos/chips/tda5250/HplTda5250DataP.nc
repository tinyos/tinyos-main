/*
 * Copyright (c) 2004, Technische Universitat Berlin
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
 * - Neither the name of the Technische Universitat Berlin nor the names
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
 * - Revision -------------------------------------------------------------
 * $Revision: 1.3 $
 * $Date: 2006-11-07 19:31:15 $
 * ========================================================================
 */

 /**
 * HplTda5250DataP module
 *
 * @author Philipp Hupertz (huppertz@tkn.tu-berlin.de)
 * @author Kevin Klues (klues@tkn.tu-berlin.de)
  */

module HplTda5250DataP {
  provides {
    interface Init;
    interface HplTda5250Data;
    interface HplTda5250DataControl;
    interface Resource;
		interface ResourceRequested;
  }
  uses {
    interface GeneralIO as DATA;
    interface UartStream as Uart;
    interface HplTda5250DataControl as UartDataControl;
    interface Resource as UartResource;
    interface ResourceRequested as UartResourceRequested;
  }
}

implementation {

  /**
   * Initializes the Radio, setting up all Pin configurations
   * to the MicroProcessor that is driving it
   *
   * @return always returns SUCCESS
    */
  command error_t Init.init() {
    call DATA.makeOutput();
    call DATA.clr();

    //Make Rx default
    call DATA.makeInput();
    return SUCCESS;
  }

  async command error_t Resource.request() {
    return call UartResource.request();
  }

  async command error_t Resource.immediateRequest() {
    if(call UartResource.immediateRequest() == EBUSY) {
      return EBUSY;
    }
    return SUCCESS;
  }

  async command error_t Resource.release() {
    return call UartResource.release();
  }

  async command bool Resource.isOwner() {
    return call UartResource.isOwner();
  }

  event void UartResource.granted() {
    signal Resource.granted();
  }
  
  async event void UartResourceRequested.requested() {
    signal ResourceRequested.requested(); 
  }
  
  async event void UartResourceRequested.immediateRequested() {
    signal ResourceRequested.immediateRequested(); 
  }

  async command error_t HplTda5250Data.tx(uint8_t data) {
    if(call UartResource.isOwner() == FALSE)
      return FAIL;
    return call Uart.send(&data, 1);
  }

  async event void Uart.sendDone( uint8_t* buf, uint16_t len, error_t error ) {
    if(call UartResource.isOwner() == FALSE)
      return;
    signal HplTda5250Data.txReady();
  }
  
  async event void Uart.receivedByte( uint8_t data ) {
  	if(call UartResource.isOwner() == FALSE)
   	 return;
  	signal HplTda5250Data.rxDone(data);
	}
  async event void Uart.receiveDone( uint8_t* buf, uint16_t len, error_t error ) {}
  
  async command error_t HplTda5250DataControl.setToTx() {
    if(call UartResource.isOwner() == FALSE)
      return FAIL;
    call UartDataControl.setToTx();
    call Uart.disableReceiveInterrupt();
    return SUCCESS;
  }

  async command error_t HplTda5250DataControl.setToRx() {
    if(call UartResource.isOwner() == FALSE)
      return FAIL;
    call UartDataControl.setToRx();
    call Uart.enableReceiveInterrupt();
    return SUCCESS;
  }
	
  default event void Resource.granted() {}
  default async event void HplTda5250Data.txReady() {}
  default async event void HplTda5250Data.rxDone(uint8_t data) {}
}
