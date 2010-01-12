/*
 * Copyright (c) 2008 Stanford University.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Stanford University nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL STANFORD
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */
 
/**
 * This application is used to test the threaded version of the API for accessing
 * sensors on the basicsb sensor board.
 * 
 * This application simply takes sensor readings in an infinite loop from the
 * Photo and Temperature sensors on the basicsb sensor board and forwards them
 * over the serial interface.  Upon successful transmission, LED0 is toggled.
 * 
 * A successful test will result in the TestBasicsbSensors mote constantly
 * flickering LED0. Additionally, messages containing the sensor readings should
 * be forwarded over the serial interface as verified by running the following
 * for the platform of interest:
 *   java net.tinyos.tools.Listen -comm serial@/dev/ttyUSBXXX:<baud_rate>
 * 
 * Once this java application is running, you should see output containing the
 * sensor readings being streamed to your terminal.
 *
 * @author Kevin Klues (klueska@cs.stanford.edu)
 */

configuration TestBasicsbSensorsAppC {
}
implementation {
  components MainC, TestBasicsbSensorsC;
  components new ThreadC(125) as MainThread;
  
  components new BlockingPhotoC();
  components new BlockingTempC();
  components BlockingSerialActiveMessageC;
  components new BlockingSerialAMSenderC(128);

  MainC.Boot <- TestBasicsbSensorsC;
  TestBasicsbSensorsC.MainThread -> MainThread;
  TestBasicsbSensorsC.Photo -> BlockingPhotoC;
  TestBasicsbSensorsC.Temp -> BlockingTempC;
  TestBasicsbSensorsC.AMControl -> BlockingSerialActiveMessageC;
  TestBasicsbSensorsC.BlockingAMSend -> BlockingSerialAMSenderC;
  TestBasicsbSensorsC.Packet -> BlockingSerialAMSenderC;
  
  components LedsC;
  TestBasicsbSensorsC.Leds -> LedsC;
}

