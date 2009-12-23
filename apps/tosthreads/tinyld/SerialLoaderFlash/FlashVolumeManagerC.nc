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
 * SerialLoaderFlash is similar to SerialLoader in that it receives
 * loadable programs from the serial port. However, SerialLoaderFlash
 * stores them on the external flash. Then, when it receives the command to
 * load the code, it makes the call to the dynamic loader.
 * 
 * @author Chieh-Jan Mike Liang <cliang4@cs.jhu.edu>
 */

#include "AM.h"

generic configuration FlashVolumeManagerC(am_id_t AMId)
{
  uses {
    interface BlockRead;
    interface BlockWrite;
    interface DynamicLoader;
  }
}

implementation
{
  components MainC,
             SerialActiveMessageC,
             new SerialAMSenderC(AMId),
             new SerialAMReceiverC(AMId),
             new FlashVolumeManagerP(),
             NoLedsC, LedsC;
  
  DynamicLoader = FlashVolumeManagerP;
  BlockRead = FlashVolumeManagerP;
  BlockWrite = FlashVolumeManagerP;
  
  FlashVolumeManagerP.Boot -> MainC;
  FlashVolumeManagerP.SerialSplitControl -> SerialActiveMessageC;

  FlashVolumeManagerP.SerialAMSender -> SerialAMSenderC;
  FlashVolumeManagerP.SerialAMReceiver -> SerialAMReceiverC;
  FlashVolumeManagerP.Leds -> LedsC;
}
