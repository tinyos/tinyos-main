/*
 * Copyright (c) 2008 Johns Hopkins University.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the (updated) modification history and the author appear in
 * all copies of this source code.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS `AS IS'
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, LOSS OF USE, DATA,
 * OR PROFITS) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
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
