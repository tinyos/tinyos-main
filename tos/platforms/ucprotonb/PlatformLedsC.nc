/* Copyright (c) 2009, Distributed Computing Group (DCG), ETH Zurich.
*  All rights reserved.
*
*  Redistribution and use in source and binary forms, with or without
*  modification, are permitted provided that the following conditions
*  are met:
*
*  1. Redistributions of source code must retain the above copyright
*     notice, this list of conditions and the following disclaimer.
*  2. Redistributions in binary form must reproduce the above copyright
*     notice, this list of conditions and the following disclaimer in the
*     documentation and/or other materials provided with the distribution.
*  3. Neither the name of the copyright holders nor the names of
*     contributors may be used to endorse or promote products derived
*     from this software without specific prior written permission.
*
*  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS `AS IS'
*  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
*  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
*  ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS
*  BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
*  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, LOSS OF USE, DATA,
*  OR PROFITS) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
*  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
*  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
*  THE POSSIBILITY OF SUCH DAMAGE.
*
*  @author Roland Flury <rflury@tik.ee.ethz.ch>
*  @author Philipp Sommer <sommer@tik.ee.ethz.ch>
*  @author Richard Huber <rihuber@ee.ethz.ch>
*  @author Thomas Fahrni <tfahrni@ee.ethz.ch>
*  @author Gabor Salamon <gabor.salamon@unicomp.hu>
*/

configuration PlatformLedsC
{
  provides
  {
    interface GeneralIO as Led0;
    interface GeneralIO as Led1;
    interface GeneralIO as Led2;
    interface GeneralIO as Led3;
  }

  uses interface Init;
}

implementation
{
  components HplAtm128GeneralIOC as IO;
  
  #ifdef DISABLE_LED3
  components new NoPinC() as NoLed3;
  #endif

  components PlatformC;
  Init = PlatformC.LedsInit;
  Led0 = IO.PortD7;  
  Led1 = IO.PortD6; 
  Led2 = IO.PortE2;
  #ifdef DISABLE_LED3
  #warning LED3 DISABLED TO USE PW6 
  Led3 = NoLed3;
  #else
  Led3 = IO.PortE3;
  #endif
}
