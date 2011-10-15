/*
* Copyright (c) 2011, University of Szeged
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
* Author: Zsolt Szabo
*/

#include "Bma180.h"
configuration BmaReadC
{
  provides {
    interface StdControl;
    interface Read<bma180_data_t>;
    interface Init;
  }
}

implementation
{
  components BmaReadP, LedsC, new TimerMilliC(), HplBma180C, DiagMsgC, SerialActiveMessageC, Atm128rfa1Usart0SpiC, LocalTimeMilliC;

  StdControl = BmaReadP.BmaControl;
  Read       = BmaReadP;
  Init       = BmaReadP;
  BmaReadP.Leds -> LedsC;
  BmaReadP.Timer -> TimerMilliC;
  BmaReadP.LocalTime -> LocalTimeMilliC;
  BmaReadP.DiagMsg -> DiagMsgC;
  BmaReadP.FastSpiByte -> HplBma180C;
  BmaReadP.Resource -> HplBma180C;
  BmaReadP.CSN -> HplBma180C.CSN;
  BmaReadP.PWR -> HplBma180C.PWR;
}
