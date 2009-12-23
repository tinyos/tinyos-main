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
 * SerialLoader receives loadable programs from the serial port and stores
 * it in a byte array. Then, when it receives the command to load the code,
 * it makes the call to the dynamic loader.
 * 
 * @author Chieh-Jan Mike Liang <cliang4@cs.jhu.edu>
 * @author Jeongyeup Paek <jpaek@enl.usc.edu>
 */

#include "AM.h"
#include "SerialLoader.h"

configuration SerialLoaderAppC {}
implementation
{
  components MainC,
             SerialActiveMessageC,
             new SerialAMSenderC(0xAB),
             new SerialAMReceiverC(0xAB),
             SerialLoaderP,
             BigCrcC,
             LedsC;
  
  SerialLoaderP.Boot -> MainC;
  SerialLoaderP.SerialSplitControl -> SerialActiveMessageC;
  SerialLoaderP.SerialAMSender -> SerialAMSenderC;
  SerialLoaderP.SerialAMReceiver -> SerialAMReceiverC;
  SerialLoaderP.Leds -> LedsC;
  SerialLoaderP.BigCrc -> BigCrcC;

  components DynamicLoaderC;
  SerialLoaderP.DynamicLoader -> DynamicLoaderC;
}

