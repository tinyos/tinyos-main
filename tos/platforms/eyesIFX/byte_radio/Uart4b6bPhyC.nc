/* -*- mode:c++; indent-tabs-mode: nil -*-
* Copyright (c) 2006, Technische Universitaet Berlin
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
*/

/**
 * Configuration for the byte radio physical layer. Together with the
 * PacketSerializerP the UartPhyP module turns byte streams into packets.
 * This one 4b6b encodes/decodes a byte stream
 *
 * @see PacketSerializerP
 *
 * @author Philipp Huppertz <huppertz@tkn.tu-berlin.de>
 */
 
configuration Uart4b6bPhyC
{
  provides{
    interface PhyPacketTx;
    interface RadioByteComm as SerializerRadioByteComm;
    interface PhyPacketRx;
    interface UartPhyControl;
  }
  uses {
    interface RadioByteComm;
  }
}
implementation
{
    components 
        new Alarm32khz16C() as RxByteTimer,
        Uart4b6bPhyP,
        MainC;
    
    MainC.SoftwareInit -> Uart4b6bPhyP;
    PhyPacketRx = Uart4b6bPhyP;
    SerializerRadioByteComm = Uart4b6bPhyP;
    RadioByteComm = Uart4b6bPhyP;
    PhyPacketTx = Uart4b6bPhyP;
    UartPhyControl = Uart4b6bPhyP;
    
    Uart4b6bPhyP.RxByteTimer -> RxByteTimer;
    
#ifdef UART_DEBUG
    components new SerialDebugC() as SD;
    Uart4b6bPhyP.SerialDebug -> SD;
#endif

}
