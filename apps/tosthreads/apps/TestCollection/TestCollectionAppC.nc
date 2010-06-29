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
 * TestCollection is a reimplementation of the Multihop Oscilloscope application
 * using TOSThreads. It periodically samples a universal software-based SineSensor
 * and broadcasts a message every few readings. These readings can be displayed by
 * the Java "Oscilloscope" application found in the the TestCollection/java
 * subdirectory. The sampling rate starts at 4Hz, but can be changed from the Java
 * application.
 * 
 * At least two motes must be used by this application, with one of them installed
 * as a base station.  Base station motes can be created by installing them with
 * NODE_ID % 500 == 0.
 *   i.e. make <platform> threads install.0
 *        make <platform> threads install.500
 *        make <platform> threads install.1000
 * 
 * All other nodes can be installed with arbitrary NODE_IDs.
 *   make <platform> threads install.123
 * 
 * Successful running of this application is verified by all NON-base station motes
 * periodically flashing LED1 upon sending a message, and the base station mote,
 * flashing LED2 upon successful reception of a message.  Additionally, correct
 * operation should be verified by running the java tool described in the following
 * section.
 *
 * @author Chieh-Jan Mike Liang <cliang4@cs.jhu.edu>
 */

#include "MultihopOscilloscope.h"

configuration TestCollectionAppC {}

implementation {
  components TestCollectionC,
             new BlockingSineSensorC(),
             LedsC,
             BlockingActiveMessageC,
             BlockingCollectionControlC,
             new BlockingCollectionSenderC(AM_OSCILLOSCOPE),
             new BlockingCollectionReceiverC(AM_OSCILLOSCOPE),
             new ThreadC(800) as MainThread,
             MainC,
             BlockingSerialActiveMessageC,
             new BlockingSerialAMSenderC(AM_OSCILLOSCOPE);
             
  
  TestCollectionC.MainThread -> MainThread;
  TestCollectionC.Boot -> MainC;
  TestCollectionC.BlockingRead -> BlockingSineSensorC;
  TestCollectionC.Leds -> LedsC;
  TestCollectionC.BlockingRead -> BlockingSineSensorC;
  
  TestCollectionC.RadioStdControl -> BlockingActiveMessageC;
  
  TestCollectionC.RoutingControl -> BlockingCollectionControlC;
  TestCollectionC.RootControl -> BlockingCollectionControlC;
  TestCollectionC.Packet -> BlockingCollectionSenderC;
  TestCollectionC.BlockingSend -> BlockingCollectionSenderC;
  TestCollectionC.BlockingReceive -> BlockingCollectionReceiverC;
  
  TestCollectionC.SerialStdControl -> BlockingSerialActiveMessageC;
  TestCollectionC.SerialBlockingSend -> BlockingSerialAMSenderC;
}
