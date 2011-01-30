/*
 * Copyright (c) 2009 Stanford University.
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
 * Basic app to test thread isolation with system calls.
 * Based on Kevin's TestSineSensorAppC.
 *
 * @author Wanja Hofer <wanja@cs.fau.de>
 */

configuration TestMpuProtectionSyscallAppC
{
}
implementation
{
	components MainC, TestMpuProtectionSyscallC;
	components new ThreadC(0x200) as Thread0;

	components new BlockingSineSensorC();
	components BlockingSerialActiveMessageC;
	components new BlockingSerialAMSenderC(228);

	MainC.Boot <- TestMpuProtectionSyscallC;
	MainC.SoftwareInit -> BlockingSineSensorC;
	TestMpuProtectionSyscallC.Thread0 -> Thread0;
	TestMpuProtectionSyscallC.BlockingRead -> BlockingSineSensorC;
	TestMpuProtectionSyscallC.AMControl -> BlockingSerialActiveMessageC;
	TestMpuProtectionSyscallC.BlockingAMSend -> BlockingSerialAMSenderC;
	//TestMpuProtectionSyscallC.Packet -> BlockingSerialAMSenderC;

	components LedsC;
	TestMpuProtectionSyscallC.Leds -> LedsC;
}
