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
 * @author Razvan Musaloiu-E. <razvanm@cs.jhu.edu>
 * @author Chieh-Jan Mike Liang <cliang4@cs.jhu.edu>
 */

#include "StorageVolumes.h"

generic configuration DelugeManagerC(am_id_t AMId)
{
   uses interface DisseminationUpdate<DelugeCmd>;
}

implementation
{
  components new SerialAMSenderC(AMId);
  components new SerialAMReceiverC(AMId);  
  components new TimerMilliC() as Timer;
  components NoLedsC, LedsC;
  components new DelugeManagerP();
  components NetProgC;
  components BlockStorageManagerC;
  components ObjectTransferC;
  components new DelugeMetadataClientC();
  components new DelugeVolumeManagerClientC();
  components new BlockStorageLockClientC();

  DelugeManagerP.DelayTimer -> Timer;
  DelugeManagerP.SerialAMSender -> SerialAMSenderC;
  DelugeManagerP.SerialAMReceiver -> SerialAMReceiverC;
  DelugeManagerP.Leds -> LedsC;
  DelugeManagerP.DisseminationUpdate = DisseminationUpdate;
  DelugeManagerP.NetProg -> NetProgC;
  DelugeManagerP.ObjectTransfer -> ObjectTransferC;

  DelugeManagerP.StorageMap -> BlockStorageManagerC;
  DelugeManagerP.DelugeMetadata -> DelugeMetadataClientC;
  DelugeManagerP.DelugeVolumeManager -> DelugeVolumeManagerClientC;
  DelugeManagerP.Resource -> BlockStorageLockClientC;

  components DelugeP;
  DelugeManagerP.stop -> DelugeP;
}
