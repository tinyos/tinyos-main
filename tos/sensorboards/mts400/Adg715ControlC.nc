/*
 * Copyright (c) 2008 Rincon Research Corporation
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
 * - Neither the name of the Rincon Research Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * RINCON RESEARCH OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

/**
 * The adg715 chip has 8 channels that are controlled through the I2C
 * bus.  This configuration provides 8 Channel interfaces corresponding
 * to the 8 physical channels on the chip.  The I2C bus needs to be
 * wired to this configuration through the I2CPacket and Resource
 * interfaces.
 * 
 * @author Danny Park
 */

generic configuration Adg715ControlC(bool pinA1High, bool pinA2High) {
	provides {
		interface Channel as Channel1;
		interface Channel as Channel2;
		interface Channel as Channel3;
		interface Channel as Channel4;
		interface Channel as Channel5;
		interface Channel as Channel6;
		interface Channel as Channel7;
		interface Channel as Channel8;
	}
  
	uses {
		interface I2CPacket<TI2CBasicAddr>;
		interface Resource;
	}
}
implementation {
	components new Adg715ControlP(pinA1High, pinA2High), MainC;
	components LedsC;
  
	Channel1 = Adg715ControlP.Channel[1];
	Channel2 = Adg715ControlP.Channel[2];
	Channel3 = Adg715ControlP.Channel[3];
	Channel4 = Adg715ControlP.Channel[4];
	Channel5 = Adg715ControlP.Channel[5];
	Channel6 = Adg715ControlP.Channel[6];
	Channel7 = Adg715ControlP.Channel[7];
	Channel8 = Adg715ControlP.Channel[8];
	I2CPacket = Adg715ControlP;
	Resource = Adg715ControlP;
	Adg715ControlP.Leds->LedsC;
	MainC.SoftwareInit -> Adg715ControlP.Init;
}
