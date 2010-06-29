/*
 * Copyright (c) 2008 Johns Hopkins University.
 * All rights reserved.
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
 * This application is used to test the threaded version of the API for performing
 * block storage.
 * 
 * This application first checks the size of the block storage volume, and
 * erases it. Then, it randomly writes records, followed by a verification
 * with read.
 * 
 * Successful running of this application results in LED0 being ON
 * throughout the duration of the erase, write, and read sequence. Finally,
 * if all tests pass, LED1 is turned ON. Otherwise, all three LEDs are
 * turned ON to indicate problems.
 *
 * @author Chieh-Jan Mike Liang <cliang4@cs.jhu.edu>
 */

#include "StorageVolumes.h"

configuration TestBlockStorageAppC {}

implementation
{
  components MainC,
             TestBlockStorageP,
             LedsC,
             new ThreadC(500) as TinyThread1,
             new BlockingBlockStorageC(VOLUME_TESTBLOCKSTORAGE1) as BlockingBlockStorage1,
             RandomC;
             
  TestBlockStorageP.Boot -> MainC;
  TestBlockStorageP.Leds -> LedsC;
  TestBlockStorageP.BlockingBlock1 -> BlockingBlockStorage1;
  TestBlockStorageP.TinyThread1 -> TinyThread1;
  TestBlockStorageP.Random -> RandomC;
}
