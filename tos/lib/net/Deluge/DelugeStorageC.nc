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

  BlockRead[VOLUME_GOLDENIMAGE] = DelugeStorageP.BlockRead[VOLUME_GOLDENIMAGE];
  BlockWrite[VOLUME_GOLDENIMAGE] = DelugeStorageP.BlockWrite[VOLUME_GOLDENIMAGE];
  BlockRead[VOLUME_DELUGE1] = DelugeStorageP.BlockRead[VOLUME_DELUGE1];
  BlockWrite[VOLUME_DELUGE1] = DelugeStorageP.BlockWrite[VOLUME_DELUGE1];
  BlockRead[VOLUME_DELUGE2] = DelugeStorageP.BlockRead[VOLUME_DELUGE2];
  BlockWrite[VOLUME_DELUGE2] = DelugeStorageP.BlockWrite[VOLUME_DELUGE2];
  BlockRead[VOLUME_DELUGE3] = DelugeStorageP.BlockRead[VOLUME_DELUGE3];
  BlockWrite[VOLUME_DELUGE3] = DelugeStorageP.BlockWrite[VOLUME_DELUGE3];
  DelugeMetadata = DelugeStorageP.DelugeMetadata;

  components new BlockStorageC(VOLUME_GOLDENIMAGE) as BlockStorageC_Golden;
  DelugeStorageP.SubBlockRead[VOLUME_GOLDENIMAGE] -> BlockStorageC_Golden;
  DelugeStorageP.SubBlockWrite[VOLUME_GOLDENIMAGE] -> BlockStorageC_Golden;
 
  components new BlockStorageC(VOLUME_DELUGE1) as BlockStorageC_1;
  DelugeStorageP.SubBlockRead[VOLUME_DELUGE1] -> BlockStorageC_1;
  DelugeStorageP.SubBlockWrite[VOLUME_DELUGE1] -> BlockStorageC_1;

  components new BlockStorageC(VOLUME_DELUGE2) as BlockStorageC_2;
  DelugeStorageP.SubBlockRead[VOLUME_DELUGE2] -> BlockStorageC_2;
  DelugeStorageP.SubBlockWrite[VOLUME_DELUGE2] -> BlockStorageC_2;

  components new BlockStorageC(VOLUME_DELUGE3) as BlockStorageC_3;
  DelugeStorageP.SubBlockRead[VOLUME_DELUGE3] -> BlockStorageC_3;
  DelugeStorageP.SubBlockWrite[VOLUME_DELUGE3] -> BlockStorageC_3;
  
#if defined(PLATFORM_TELOSB)
  DelugeStorageP.StorageMap[VOLUME_GOLDENIMAGE] -> BlockStorageC_Golden;
  DelugeStorageP.StorageMap[VOLUME_DELUGE1] -> BlockStorageC_1;
  DelugeStorageP.StorageMap[VOLUME_DELUGE2] -> BlockStorageC_2;
  DelugeStorageP.StorageMap[VOLUME_DELUGE3] -> BlockStorageC_3;
#elif defined(PLATFORM_MICAZ)
  components At45dbStorageManagerC;
  DelugeStorageP.At45dbVolume[VOLUME_GOLDENIMAGE] -> At45dbStorageManagerC.At45dbVolume[VOLUME_GOLDENIMAGE];
  DelugeStorageP.At45dbVolume[VOLUME_DELUGE1] -> At45dbStorageManagerC.At45dbVolume[VOLUME_DELUGE1];
  DelugeStorageP.At45dbVolume[VOLUME_DELUGE2] -> At45dbStorageManagerC.At45dbVolume[VOLUME_DELUGE2];
  DelugeStorageP.At45dbVolume[VOLUME_DELUGE3] -> At45dbStorageManagerC.At45dbVolume[VOLUME_DELUGE3];
#else
  #error "Target platform is not currently supported by Deluge T2"
#endif

  DelugeStorage[VOLUME_GOLDENIMAGE] = DelugeStorageP.DelugeStorage[VOLUME_GOLDENIMAGE];
  DelugeStorage[VOLUME_DELUGE1] = DelugeStorageP.DelugeStorage[VOLUME_DELUGE1];
  DelugeStorage[VOLUME_DELUGE2] = DelugeStorageP.DelugeStorage[VOLUME_DELUGE2];
  DelugeStorage[VOLUME_DELUGE3] = DelugeStorageP.DelugeStorage[VOLUME_DELUGE3];
  
  components LedsC, MainC;
  DelugeStorageP.Leds -> LedsC;
  DelugeStorageP.Boot -> MainC;
  
  Notify = DelugeStorageP.Notify;
}
