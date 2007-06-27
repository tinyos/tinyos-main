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

#include "Deluge.h"
#include "StorageVolumes.h"

configuration DelugeC {}

implementation
{
  components DelugeStorageC;
  
#ifdef DELUGE_BASESTATION
  components SerialStarterC;
  components new FlashVolumeManagerC(0xAB);
  
  DelugeP.ReprogNotify -> FlashVolumeManagerC;
  FlashVolumeManagerC.BlockRead[VOLUME_DELUGE0] -> DelugeStorageC.BlockRead[VOLUME_DELUGE0];
  FlashVolumeManagerC.BlockWrite[VOLUME_DELUGE0] -> DelugeStorageC.BlockWrite[VOLUME_DELUGE0];
  FlashVolumeManagerC.DelugeStorage[VOLUME_DELUGE0] -> DelugeStorageC.DelugeStorage[VOLUME_DELUGE0];
  FlashVolumeManagerC.BlockRead[VOLUME_DELUGE1] -> DelugeStorageC.BlockRead[VOLUME_DELUGE1];
  FlashVolumeManagerC.BlockWrite[VOLUME_DELUGE1] -> DelugeStorageC.BlockWrite[VOLUME_DELUGE1];
  FlashVolumeManagerC.DelugeStorage[VOLUME_DELUGE1] -> DelugeStorageC.DelugeStorage[VOLUME_DELUGE1];
#endif
  
  components ObjectTransferC;
  ObjectTransferC.BlockRead[VOLUME_DELUGE0] -> DelugeStorageC.BlockRead[VOLUME_DELUGE0];
  ObjectTransferC.BlockWrite[VOLUME_DELUGE0] -> DelugeStorageC.BlockWrite[VOLUME_DELUGE0];
  ObjectTransferC.BlockRead[VOLUME_DELUGE1] -> DelugeStorageC.BlockRead[VOLUME_DELUGE1];
  ObjectTransferC.BlockWrite[VOLUME_DELUGE1] -> DelugeStorageC.BlockWrite[VOLUME_DELUGE1];
  
  components new DisseminatorC(DelugeDissemination, 0xDE00), DisseminationC;
  components ActiveMessageC;
  components NetProgC, DelugeP;
  components new TimerMilliC() as Timer;
  components LedsC, NoLedsC;
  DelugeP.Leds -> LedsC;  
  DelugeP.DisseminationValue -> DisseminatorC;
  DelugeP.DisseminationUpdate -> DisseminatorC;
  DelugeP.StdControlDissemination -> DisseminationC;
  DelugeP.ObjectTransfer -> ObjectTransferC;
  DelugeP.NetProg -> NetProgC;
  DelugeP.StorageReadyNotify -> DelugeStorageC;
  DelugeP.DelugeMetadata -> DelugeStorageC;
  DelugeP.RadioSplitControl -> ActiveMessageC;
  
  components InternalFlashC as IFlash;
  DelugeP.IFlash -> IFlash;
}
