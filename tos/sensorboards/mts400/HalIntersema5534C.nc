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

configuration HalIntersema5534C {
	provides interface Resource[ uint8_t client ];
  	provides interface Read<uint16_t> as Temp;
  	provides interface Read<uint16_t> as Press;
  	provides interface Calibration as Cal; 
}
implementation {
	components new Intersema5534LogicP();
	Temp = Intersema5534LogicP.Temp;
	Press = Intersema5534LogicP.Press;
	Cal = Intersema5534LogicP.Cal;
 
	components HplIntersema5534C;
	Resource = HplIntersema5534C.Resource;

	components MicaBusC;
	
	Intersema5534LogicP.SPI_CLK -> MicaBusC.USART1_CLK;
	Intersema5534LogicP.SPI_SI -> MicaBusC.USART1_RXD;
	Intersema5534LogicP.SPI_SO -> MicaBusC.USART1_TXD;
	
	components new TimerMilliC() as Timer;
	Intersema5534LogicP.Timer->Timer;
}

