/* -*- mode:c++; indent-tabs-mode: nil -*-
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
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, 
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY 
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE 
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Description ---------------------------------------------------------
 * provides preamble sampling csma with timestamping
 * - Revision -------------------------------------------------------------
 * $Revision: 1.3 $
 * $Date: 2006-11-07 19:31:22 $
 * @author: Kevin Klues (klues@tkn.tu-berlin.de)
 * ========================================================================
 */

configuration RadioDataLinkC {
    provides {
      interface SplitControl; 
      interface Send;
      interface Receive;
      interface Packet;
      interface PacketAcknowledgements;
    }
}
implementation
{
    components 
        //Change components below as desired
        Tda5250RadioC as Radio,                  //The actual Tda5250 radio over which data is receives/transmitted
        Uart4b6bPhyC as UartPhy,                 //The UartPhy turns Bits into Bytes
        PacketSerializerP  as PacketSerializer,  //The PacketSerializer turns Bytes into Packets
        CsmaMacC as Mac,                         //The MAC protocol to use
        LinkLayerC as Llc;                       //The Link Layer Control module to use
    
    //Don't change wirings below this point, just change which components
    //They are compposed of in the list above             
    
    components MainC;
    MainC.SoftwareInit -> PacketSerializer;
            
    SplitControl = Llc;
    Llc.MacSplitControl -> Mac.SplitControl;
    Llc.RadioSplitControl -> Radio.SplitControl;
  
    Send = Llc.Send;
    Receive = Llc.Receive;
    PacketAcknowledgements = Llc;
    Packet = Mac;
  
    Llc.SendDown->Mac.MacSend;
    Llc.ReceiveLower->Mac.MacReceive;
    Llc.Packet->Mac.Packet;
    Mac.SubPacket->PacketSerializer.Packet;
    
    Mac.PacketSend->PacketSerializer.PhySend;
    Mac.PacketReceive->PacketSerializer.PhyReceive;  
    Mac.Tda5250Control->Radio;
    Mac.UartPhyControl -> UartPhy;

    Mac.RadioTimeStamping -> PacketSerializer.RadioTimeStamping;
    PacketSerializer.RadioByteComm -> UartPhy.SerializerRadioByteComm;
    PacketSerializer.PhyPacketTx -> UartPhy.PhyPacketTx;
    PacketSerializer.PhyPacketRx -> UartPhy.PhyPacketRx;
    
    UartPhy.RadioByteComm -> Radio.RadioByteComm;
}
