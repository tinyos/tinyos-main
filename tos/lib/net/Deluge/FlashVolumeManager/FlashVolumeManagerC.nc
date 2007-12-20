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

#include "AM.h"
#include "StorageVolumes.h"

generic configuration FlashVolumeManagerC(am_id_t AMId)
{
#ifdef DELUGE  
  provides interface Notify<uint8_t> as DissNotify;
  provides interface Notify<uint8_t> as ReprogNotify;
#endif
  uses {
    interface BlockRead[uint8_t img_num];
    interface BlockWrite[uint8_t img_num];
#ifdef DELUGE
    interface DelugeStorage[uint8_t img_num];
#endif
  }
}

implementation
{
  components new SerialAMSenderC(AMId),
             new SerialAMReceiverC(AMId),
             new FlashVolumeManagerP(),
             NoLedsC, LedsC;
  
  FlashVolumeManagerP.BlockRead[VOLUME_GOLDENIMAGE] = BlockRead[VOLUME_GOLDENIMAGE];
  FlashVolumeManagerP.BlockWrite[VOLUME_GOLDENIMAGE] = BlockWrite[VOLUME_GOLDENIMAGE];
  FlashVolumeManagerP.BlockRead[VOLUME_DELUGE1] = BlockRead[VOLUME_DELUGE1];
  FlashVolumeManagerP.BlockWrite[VOLUME_DELUGE1] = BlockWrite[VOLUME_DELUGE1];
  FlashVolumeManagerP.BlockRead[VOLUME_DELUGE2] = BlockRead[VOLUME_DELUGE2];
  FlashVolumeManagerP.BlockWrite[VOLUME_DELUGE2] = BlockWrite[VOLUME_DELUGE2];
  FlashVolumeManagerP.BlockRead[VOLUME_DELUGE3] = BlockRead[VOLUME_DELUGE3];
  FlashVolumeManagerP.BlockWrite[VOLUME_DELUGE3] = BlockWrite[VOLUME_DELUGE3];
 
  FlashVolumeManagerP.SerialAMSender -> SerialAMSenderC;
  FlashVolumeManagerP.SerialAMReceiver -> SerialAMReceiverC;
  FlashVolumeManagerP.Leds -> NoLedsC;

#ifdef DELUGE  
  components NetProgC, new TimerMilliC();
  
  FlashVolumeManagerP.NetProg -> NetProgC;
  FlashVolumeManagerP.Timer -> TimerMilliC;
  FlashVolumeManagerP.DelugeStorage[VOLUME_GOLDENIMAGE] = DelugeStorage[VOLUME_GOLDENIMAGE];
  FlashVolumeManagerP.DelugeStorage[VOLUME_DELUGE1] = DelugeStorage[VOLUME_DELUGE1];
  FlashVolumeManagerP.DelugeStorage[VOLUME_DELUGE2] = DelugeStorage[VOLUME_DELUGE2];
  FlashVolumeManagerP.DelugeStorage[VOLUME_DELUGE3] = DelugeStorage[VOLUME_DELUGE3];
  DissNotify = FlashVolumeManagerP.DissNotify;
  ReprogNotify = FlashVolumeManagerP.ReprogNotify;
#endif
}
