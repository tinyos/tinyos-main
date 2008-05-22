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
 * $Revision: 1.5 $
 * $Date: 2008-05-22 14:56:33 $
 * ========================================================================
 */

#include "msp430usart.h"
#include "tda5250BusResourceSettings.h"

 /**
 * Wrapper module for the Msp430 Uart abstraction.
 *
 * @author Philipp Hupertz (huppertz@tkn.tu-berlin.de)
  */
module HplTda5250DataIOP {
  provides {
    interface HplTda5250DataControl as UartDataControl;
    interface Msp430UartConfigure as UartResourceConfigure;
  }
}

implementation {
  
  async command error_t UartDataControl.setToTx() {
        atomic {
      tda5250_uart_config.uartConfig.utxe = 1;
      tda5250_uart_config.uartConfig.urxe = 0;
    }
    return SUCCESS;
  }

  async command error_t UartDataControl.setToRx() {
    atomic {
      tda5250_uart_config.uartConfig.utxe = 0;
      tda5250_uart_config.uartConfig.urxe = 1;
    }
    return SUCCESS;
  }
	
  async command msp430_uart_union_config_t* UartResourceConfigure.getConfig() {
    return &tda5250_uart_config;
  }

}
