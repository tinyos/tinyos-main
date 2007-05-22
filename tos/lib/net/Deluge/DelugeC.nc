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

configuration DelugeC {}

implementation
{
  components DelugeStorageC;

#ifdef DELUGE_BASESTATION
  components SerialStarterC;
  components new FlashVolumeManagerC(0xAB);

  DelugeP.ReprogNotify -> FlashVolumeManagerC;
  FlashVolumeManagerC.BlockRead[0] -> DelugeStorageC.BlockRead[0];
  FlashVolumeManagerC.BlockWrite[0] -> DelugeStorageC.BlockWrite[0];
  FlashVolumeManagerC.StorageMap[0] -> DelugeStorageC.StorageMap[0];
  FlashVolumeManagerC.BlockRead[1] -> DelugeStorageC.BlockRead[1];
  FlashVolumeManagerC.BlockWrite[1] -> DelugeStorageC.BlockWrite[1];
  FlashVolumeManagerC.StorageMap[1] -> DelugeStorageC.StorageMap[1];
#endif
  
  components ObjectTransferC;
  ObjectTransferC.BlockRead[0] -> DelugeStorageC.BlockRead[0];
  ObjectTransferC.BlockWrite[0] -> DelugeStorageC.BlockWrite[0];
  ObjectTransferC.BlockRead[1] -> DelugeStorageC.BlockRead[1];
  ObjectTransferC.BlockWrite[1] -> DelugeStorageC.BlockWrite[1];
  
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
