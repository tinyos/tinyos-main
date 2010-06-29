/* Copyright (c) 2007 Johns Hopkins University.
*  All rights reserved.
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
 * @author Chieh-Jan Mike Liang <cliang4@cs.jhu.edu>
 * @author Razvan Musaloiu-E. <razvanm@cs.jhu.edu>
 */

configuration DelugePageTransferC
{
  provides interface DelugePageTransfer;
  uses {
    interface BlockRead[uint8_t img_num];
    interface BlockWrite[uint8_t img_num];
    
    interface Receive as ReceiveDataMsg;
    interface Receive as ReceiveReqMsg;
    interface AMSend as SendDataMsg;
    interface AMSend as SendReqMsg;
    interface AMPacket;
    interface PacketAcknowledgements;
    interface Leds;
  }
}

implementation
{
  components DelugePageTransferP;
  
  DelugePageTransfer = DelugePageTransferP;
  BlockRead = DelugePageTransferP.BlockRead;
  BlockWrite = DelugePageTransferP.BlockWrite;
  
  ReceiveDataMsg = DelugePageTransferP.ReceiveDataMsg;
  ReceiveReqMsg = DelugePageTransferP.ReceiveReqMsg;
  SendDataMsg = DelugePageTransferP.SendDataMsg;
  SendReqMsg = DelugePageTransferP.SendReqMsg;
  
  AMPacket = DelugePageTransferP.AMPacket;
  PacketAcknowledgements = DelugePageTransferP.PacketAcknowledgements;
  
  components RandomC, BitVecUtilsC, new TimerMilliC() as Timer;
  DelugePageTransferP.Random -> RandomC;
  DelugePageTransferP.Timer -> Timer;
  DelugePageTransferP.BitVecUtils -> BitVecUtilsC;
  
  DelugePageTransferP.Leds = Leds;
  
  // For collecting statistics
  //components StatsCollectorC;
  //DelugePageTransferP.StatsCollector -> StatsCollectorC.StatsCollector;
}
