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

#include "StorageVolumes.h"

configuration DelugeStorageC
{
  provides {
    interface BlockRead[uint8_t img_num];
    interface BlockWrite[uint8_t img_num];
    interface DelugeStorage[uint8_t img_num];
    interface DelugeMetadata;
    
    interface Notify<uint8_t>;
  }
}

implementation
{
  components DelugeStorageP;

  BlockRead[VOLUME_DELUGE0] = DelugeStorageP.BlockRead[VOLUME_DELUGE0];
  BlockWrite[VOLUME_DELUGE0] = DelugeStorageP.BlockWrite[VOLUME_DELUGE0];
  BlockRead[VOLUME_DELUGE1] = DelugeStorageP.BlockRead[VOLUME_DELUGE1];
  BlockWrite[VOLUME_DELUGE1] = DelugeStorageP.BlockWrite[VOLUME_DELUGE1];
  DelugeMetadata = DelugeStorageP.DelugeMetadata;
 
  components new BlockStorageC(VOLUME_DELUGE0) as BlockStorageC_0;
  components new BlockStorageC(VOLUME_DELUGE1) as BlockStorageC_1;
  DelugeStorageP.SubBlockRead[VOLUME_DELUGE0] -> BlockStorageC_0;
  DelugeStorageP.SubBlockWrite[VOLUME_DELUGE0] -> BlockStorageC_0;
  DelugeStorageP.SubBlockRead[VOLUME_DELUGE1] -> BlockStorageC_1;
  DelugeStorageP.SubBlockWrite[VOLUME_DELUGE1] -> BlockStorageC_1;
  
#if defined(PLATFORM_TELOSB)
  DelugeStorageP.StorageMap[VOLUME_DELUGE0] -> BlockStorageC_0;
  DelugeStorageP.StorageMap[VOLUME_DELUGE1] -> BlockStorageC_1;
#elif defined(PLATFORM_MICAZ)
  components At45dbStorageManagerC;
  DelugeStorageP.At45dbVolume[VOLUME_DELUGE0] -> At45dbStorageManagerC.At45dbVolume[VOLUME_DELUGE0];
  DelugeStorageP.At45dbVolume[VOLUME_DELUGE1] -> At45dbStorageManagerC.At45dbVolume[VOLUME_DELUGE1];
#else
  #error "Target platform is not currently supported by Deluge T2"
#endif

  DelugeStorage[VOLUME_DELUGE0] = DelugeStorageP.DelugeStorage[VOLUME_DELUGE0];
  DelugeStorage[VOLUME_DELUGE1] = DelugeStorageP.DelugeStorage[VOLUME_DELUGE1];
  
  components LedsC, MainC;
  DelugeStorageP.Leds -> LedsC;
  DelugeStorageP.Boot -> MainC;
  
  Notify = DelugeStorageP.Notify;
}
