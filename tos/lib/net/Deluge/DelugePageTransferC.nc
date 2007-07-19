/* Copyright (c) 2007 Johns Hopkins University.
*  All rights reserved.
*
*  Permission to use, copy, modify, and distribute this software and its
*  documentation for any purpose, without fee, and without written
*  agreement is hereby granted, provided that the above copyright
*  notice, the (updated) modification history and the author appear in
*  all copies of this source code.
*
*  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS `AS IS'
*  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
*  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
*  ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS
*  BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
*  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, LOSS OF USE, DATA,
*  OR PROFITS) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
*  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
*  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
*  THE POSSIBILITY OF SUCH DAMAGE.
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
  BlockRead[0] = DelugePageTransferP.BlockRead[0];
  BlockWrite[0] = DelugePageTransferP.BlockWrite[0];
  BlockRead[1] = DelugePageTransferP.BlockRead[1];
  BlockWrite[1] = DelugePageTransferP.BlockWrite[1];
  
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
