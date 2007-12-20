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

configuration DelugeC
{
  uses interface Leds;
}

implementation
{
  components DelugeStorageC;
  
#ifdef DELUGE_BASESTATION
  components SerialStarterC;
  components new FlashVolumeManagerC(0xAB);
  
  DelugeP.DissNotify -> FlashVolumeManagerC.DissNotify;
  DelugeP.ReprogNotify -> FlashVolumeManagerC.ReprogNotify;

  FlashVolumeManagerC.BlockRead[VOLUME_GOLDENIMAGE] -> DelugeStorageC.BlockRead[VOLUME_GOLDENIMAGE];
  FlashVolumeManagerC.BlockWrite[VOLUME_GOLDENIMAGE] -> DelugeStorageC.BlockWrite[VOLUME_GOLDENIMAGE];
  FlashVolumeManagerC.DelugeStorage[VOLUME_GOLDENIMAGE] -> DelugeStorageC.DelugeStorage[VOLUME_GOLDENIMAGE];
  
  FlashVolumeManagerC.BlockRead[VOLUME_DELUGE1] -> DelugeStorageC.BlockRead[VOLUME_DELUGE1];
  FlashVolumeManagerC.BlockWrite[VOLUME_DELUGE1] -> DelugeStorageC.BlockWrite[VOLUME_DELUGE1];
  FlashVolumeManagerC.DelugeStorage[VOLUME_DELUGE1] -> DelugeStorageC.DelugeStorage[VOLUME_DELUGE1];

  FlashVolumeManagerC.BlockRead[VOLUME_DELUGE2] -> DelugeStorageC.BlockRead[VOLUME_DELUGE2];
  FlashVolumeManagerC.BlockWrite[VOLUME_DELUGE2] -> DelugeStorageC.BlockWrite[VOLUME_DELUGE2];
  FlashVolumeManagerC.DelugeStorage[VOLUME_DELUGE2] -> DelugeStorageC.DelugeStorage[VOLUME_DELUGE2];

  FlashVolumeManagerC.BlockRead[VOLUME_DELUGE3] -> DelugeStorageC.BlockRead[VOLUME_DELUGE3];
  FlashVolumeManagerC.BlockWrite[VOLUME_DELUGE3] -> DelugeStorageC.BlockWrite[VOLUME_DELUGE3];
  FlashVolumeManagerC.DelugeStorage[VOLUME_DELUGE3] -> DelugeStorageC.DelugeStorage[VOLUME_DELUGE3];
#endif
  
  components ObjectTransferC;
  ObjectTransferC.BlockRead[VOLUME_DELUGE1] -> DelugeStorageC.BlockRead[VOLUME_DELUGE1];
  ObjectTransferC.BlockWrite[VOLUME_DELUGE1] -> DelugeStorageC.BlockWrite[VOLUME_DELUGE1];
  ObjectTransferC.BlockRead[VOLUME_DELUGE2] -> DelugeStorageC.BlockRead[VOLUME_DELUGE2];
  ObjectTransferC.BlockWrite[VOLUME_DELUGE2] -> DelugeStorageC.BlockWrite[VOLUME_DELUGE2];
  ObjectTransferC.BlockRead[VOLUME_DELUGE3] -> DelugeStorageC.BlockRead[VOLUME_DELUGE3];
  ObjectTransferC.BlockWrite[VOLUME_DELUGE3] -> DelugeStorageC.BlockWrite[VOLUME_DELUGE3];
  ObjectTransferC.Leds = Leds;
  
  components new DisseminatorC(DelugeDissemination, 0xDE00), DisseminationC;
  components ActiveMessageC;
  components NetProgC, DelugeP;
  components new TimerMilliC() as Timer;
  DelugeP.Leds = Leds;  
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
