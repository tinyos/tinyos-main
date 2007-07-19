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

#include "DelugePageTransfer.h"
#include "StorageVolumes.h"

configuration ObjectTransferC
{
  provides interface ObjectTransfer;
  uses {
    interface BlockRead[uint8_t img_num];
    interface BlockWrite[uint8_t img_num];
    interface Leds;
  }
}

implementation
{
  components ObjectTransferP, DelugePageTransferC;
  
  ObjectTransfer = ObjectTransferP;
  BlockRead[VOLUME_DELUGE0] = DelugePageTransferC.BlockRead[VOLUME_DELUGE0];
  BlockWrite[VOLUME_DELUGE0] = DelugePageTransferC.BlockWrite[VOLUME_DELUGE0];
  BlockRead[VOLUME_DELUGE1] = DelugePageTransferC.BlockRead[VOLUME_DELUGE1];
  BlockWrite[VOLUME_DELUGE1] = DelugePageTransferC.BlockWrite[VOLUME_DELUGE1];
  ObjectTransferP.DelugePageTransfer -> DelugePageTransferC.DelugePageTransfer;
  
  components CrcP;
  ObjectTransferP.Crc -> CrcP.Crc;
  
  components new AMSenderC(AM_DELUGEADVMSG) as SendAdvMsg, 
             new AMReceiverC(AM_DELUGEADVMSG) as ReceiveAdvMsg,
             new AMSenderC(AM_DELUGEREQMSG) as SendReqMsg, 
             new AMReceiverC(AM_DELUGEREQMSG) as ReceiveReqMsg,
             new AMSenderC(AM_DELUGEDATAMSG) as SendDataMsg, 
             new AMReceiverC(AM_DELUGEDATAMSG) as ReceiveDataMsg;
  
  ObjectTransferP.SendAdvMsg -> SendAdvMsg;
  ObjectTransferP.ReceiveAdvMsg -> ReceiveAdvMsg;
  DelugePageTransferC.SendReqMsg -> SendReqMsg;
  DelugePageTransferC.ReceiveReqMsg -> ReceiveReqMsg;
  DelugePageTransferC.SendDataMsg -> SendDataMsg;
  DelugePageTransferC.ReceiveDataMsg -> ReceiveDataMsg;
  DelugePageTransferC.AMPacket -> SendDataMsg;
  DelugePageTransferC.Leds = Leds;
  
  ObjectTransferP.BlockWrite[VOLUME_DELUGE0] = BlockWrite[VOLUME_DELUGE0];
  ObjectTransferP.BlockWrite[VOLUME_DELUGE1] = BlockWrite[VOLUME_DELUGE1];
  
  components RandomC, new TimerMilliC() as Timer;
  ObjectTransferP.Random -> RandomC;
  ObjectTransferP.Timer -> Timer;
  
  // For collecting statistics
//  components StatsCollectorC;
//  ObjectTransferP.StatsCollector -> StatsCollectorC.StatsCollector;
}
