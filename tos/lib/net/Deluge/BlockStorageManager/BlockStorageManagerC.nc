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
 * @author Razvan Musaloiu-E. <razvanm@cs.jhu.edu>
 * @author Chieh-Jan Mike Liang <cliang4@cs.jhu.edu>
 */

#include "BlockStorageManager.h"

configuration BlockStorageManagerC
{
  provides {
    interface BlockRead[uint8_t client];
    interface BlockWrite[uint8_t client];
    interface StorageMap[uint8_t volume_id];
  }
  uses interface VolumeId[uint8_t client];
}

implementation
{
  enum {
    NUM_CLIENTS = uniqueCount(UQ_BSTORAGEM_CLIENT)
  };

  components new BlockStorageManagerP(NUM_CLIENTS);

  BlockRead  = BlockStorageManagerP;
  BlockWrite = BlockStorageManagerP;
  VolumeId   = BlockStorageManagerP;
  StorageMap = BlockStorageManagerP;

  components new BlockStorageC(VOLUME_GOLDENIMAGE) as BlockStorageC_Golden;
  components new BlockStorageC(VOLUME_DELUGE1)     as BlockStorageC_1;
  components new BlockStorageC(VOLUME_DELUGE2)     as BlockStorageC_2;
  components new BlockStorageC(VOLUME_DELUGE3)     as BlockStorageC_3;

  BlockStorageManagerP.SubBlockRead[VOLUME_GOLDENIMAGE] -> BlockStorageC_Golden;
  BlockStorageManagerP.SubBlockRead[VOLUME_DELUGE1]     -> BlockStorageC_1;
  BlockStorageManagerP.SubBlockRead[VOLUME_DELUGE2]     -> BlockStorageC_2;
  BlockStorageManagerP.SubBlockRead[VOLUME_DELUGE3]     -> BlockStorageC_3;

  BlockStorageManagerP.SubBlockWrite[VOLUME_GOLDENIMAGE] -> BlockStorageC_Golden;
  BlockStorageManagerP.SubBlockWrite[VOLUME_DELUGE1]     -> BlockStorageC_1;
  BlockStorageManagerP.SubBlockWrite[VOLUME_DELUGE2]     -> BlockStorageC_2;
  BlockStorageManagerP.SubBlockWrite[VOLUME_DELUGE3]     -> BlockStorageC_3;

#if defined(PLATFORM_TELOSB)
  BlockStorageManagerP.SubStorageMap[VOLUME_GOLDENIMAGE] -> BlockStorageC_Golden;
  BlockStorageManagerP.SubStorageMap[VOLUME_DELUGE1]     -> BlockStorageC_1;
  BlockStorageManagerP.SubStorageMap[VOLUME_DELUGE2]     -> BlockStorageC_2;
  BlockStorageManagerP.SubStorageMap[VOLUME_DELUGE3]     -> BlockStorageC_3;
#elif defined(PLATFORM_MICAZ) || defined(PLATFORM_IRIS) || defined(PLATFORM_EPIC) || defined(PLATFORM_MULLE) || defined(PLATFORM_TINYNODE)
  components At45dbStorageManagerC;
  BlockStorageManagerP.At45dbVolume -> At45dbStorageManagerC;
#endif
}
