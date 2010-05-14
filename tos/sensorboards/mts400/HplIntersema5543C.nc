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

#include"Intersema5543.h"

configuration HplIntersema5543C {
  provides interface Resource[ uint8_t id ];
}
implementation {
	components HplIntersema5543P;
	components new FcfsArbiterC( UQ_INTERSEMA5543 ) as Arbiter;
	Resource = Arbiter;
  
	components new SplitControlPowerManagerC();
	SplitControlPowerManagerC.SplitControl -> HplIntersema5543P;
	SplitControlPowerManagerC.ArbiterInfo -> Arbiter.ArbiterInfo;
	SplitControlPowerManagerC.ResourceDefaultOwner -> Arbiter.ResourceDefaultOwner;
	
	components Adg715PowerC;
	HplIntersema5543P.ChannelPressurePower -> Adg715PowerC.ChannelPressurePower;
	
	components Adg715CommC;
	HplIntersema5543P.ChannelPressureClock -> Adg715CommC.ChannelPressureClock;
	HplIntersema5543P.ChannelPressureDin -> Adg715CommC.ChannelPressureDin;
	HplIntersema5543P.ChannelPressureDout -> Adg715CommC.ChannelPressureDout;
	
	components HplAtm128GeneralIOC;
    
	HplIntersema5543P.SPI_CLK -> HplAtm128GeneralIOC.PortD5;
	HplIntersema5543P.SPI_SI -> HplAtm128GeneralIOC.PortD2;
	HplIntersema5543P.SPI_SO -> HplAtm128GeneralIOC.PortD3;
	
	components new TimerMilliC() as Timer;
	
	HplIntersema5543P.Timer -> Timer;
	 
}
