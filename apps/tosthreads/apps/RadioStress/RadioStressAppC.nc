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
 * This application stresses the blocking send and receive commands for the TinyOS 
 * thread implementation.  Three threads are run, each thread toggling a different 
 * colored LED. If a node has TOS_NODE_ID == 0 it will try and receive in 
 * an infinite loop, toggling one of the three Leds upon reception.  If it has 
 * TOS_NODE_ID == 1, it will try to send in an infinite loop, toggling one of the three
 * Leds upon the completion of a send.  Thread 0 toggles the Led0, Thread 1 toggles 
 * Led1, and Thread 2 toggles Led2.
 *
 * @author Kevin Klues <klueska@cs.stanford.edu>
 */

configuration RadioStressAppC {
}
implementation {
  components MainC, RadioStressC,  LedsC;
  components BlockingActiveMessageC;
  MainC.Boot <- RadioStressC;
  RadioStressC.BlockingAMControl -> BlockingActiveMessageC;
  RadioStressC.Leds -> LedsC;
  
  components new ThreadC(300) as RadioStressThread0;
  components new BlockingAMSenderC(20) as BlockingAMSender0;
  components new BlockingAMReceiverC(20) as BlockingAMReceiver0;
  RadioStressC.RadioStressThread0 -> RadioStressThread0;
  RadioStressC.BlockingAMSend0 -> BlockingAMSender0;
  RadioStressC.BlockingReceive0 -> BlockingAMReceiver0;
  
  components new ThreadC(300) as RadioStressThread1;
  components new BlockingAMSenderC(21) as BlockingAMSender1;
  components new BlockingAMReceiverC(21) as BlockingAMReceiver1;
  RadioStressC.RadioStressThread1 -> RadioStressThread1;
  RadioStressC.BlockingAMSend1 -> BlockingAMSender1;
  RadioStressC.BlockingReceive1 -> BlockingAMReceiver1;
  
  components new ThreadC(300) as RadioStressThread2;
  components new BlockingAMSenderC(22) as BlockingAMSender2;
  components new BlockingAMReceiverC(22) as BlockingAMReceiver2;
  RadioStressC.RadioStressThread2 -> RadioStressThread2;
  RadioStressC.BlockingAMSend2 -> BlockingAMSender2;
  RadioStressC.BlockingReceive2 -> BlockingAMReceiver2;
}

