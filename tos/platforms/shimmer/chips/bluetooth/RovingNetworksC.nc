/*
 * Copyright (c) 2007, Intel Corporation
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 * Redistributions of source code must retain the above copyright notice, 
 * this list of conditions and the following disclaimer. 
 *
 * Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution. 
 *
 * Neither the name of the Intel Corporation nor the names of its contributors
 * may be used to endorse or promote products derived from this software 
 * without specific prior written permission. 
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
 * POSSIBILITY OF SUCH DAMAGE.
 *
 *  Author:  Steve Ayer
 *           February, 2007
 */
/**
 * @author Steve Ayer
 * @author Adrian Burns
 * @date February, 2007
 *
 * @author Mike Healy
 * @date April 20, 2009 - ported to TinyOS 2.x 
 */



configuration RovingNetworksC {
   provides {
      interface StdControl;
      interface Bluetooth;
      interface Init;
   }
}
implementation {
   components 
     RovingNetworksP,
     MainC,
     HplMsp430InterruptC,  
     HplMsp430Usart1C,     
     LedsC;

   StdControl = RovingNetworksP;
   Bluetooth = RovingNetworksP;
   Init = RovingNetworksP;

   RovingNetworksP.UARTControl            -> HplMsp430Usart1C.HplMsp430Usart;
   RovingNetworksP.UARTData               -> HplMsp430Usart1C.HplMsp430UsartInterrupts;
   RovingNetworksP.RTSInterrupt           -> HplMsp430InterruptC.Port16;
   RovingNetworksP.ConnectionInterrupt    -> HplMsp430InterruptC.Port15;
   RovingNetworksP.Leds                   -> LedsC;

}
