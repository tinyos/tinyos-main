/** Copyright (c) 2009, University of Szeged
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions
* are met:
*
* - Redistributions of source code must retain the above copyright
* notice, this list of conditions and the following disclaimer.
* - Redistributions in binary form must reproduce the above
* copyright notice, this list of conditions and the following
* disclaimer in the documentation and/or other materials provided
* with the distribution.
* - Neither the name of University of Szeged nor the names of its
* contributors may be used to endorse or promote products derived
* from this software without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
* "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
* FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
* COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
* INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
* (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
* SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
* HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
* STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
* OF THE POSSIBILITY OF SUCH DAMAGE.
*
* Author: Zoltan Kincses
*/

#include"Taos2550.h"

configuration HplTaos2550C {
  provides interface Resource[ uint8_t id ];
}
implementation {
	components HplTaos2550P;
	components new FcfsArbiterC( UQ_TAOS2550 ) as Arbiter;
	Resource = Arbiter;
  
	components new SplitControlPowerManagerC();
	SplitControlPowerManagerC.SplitControl -> HplTaos2550P;
	SplitControlPowerManagerC.ArbiterInfo -> Arbiter.ArbiterInfo;
	SplitControlPowerManagerC.ResourceDefaultOwner -> Arbiter.ResourceDefaultOwner;
	
	components Adg715PowerC;
	HplTaos2550P.ChannelLightPower -> Adg715PowerC.ChannelLightPower;

	components new TimerMilliC()as Timer;
	HplTaos2550P.Timer -> Timer;

	components new Atm128I2CMasterC();
	HplTaos2550P.I2CPacket -> Atm128I2CMasterC;
	HplTaos2550P.I2CResource -> Atm128I2CMasterC;
}
