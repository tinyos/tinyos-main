/**
 *  Copyright (c) 2005-2006 Crossbow Technology, Inc.
 *  All rights reserved.
 *
 *  Permission to use, copy, modify, and distribute this software and its
 *  documentation for any purpose, without fee, and without written
 *  agreement is hereby granted, provided that the above copyright
 *  notice, the (updated) modification history and the author appear in
 *  all copies of this source code.
 *
 *  Permission is also granted to distribute this software under the
 *  standard BSD license as contained in the TinyOS distribution.
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
 *  @author Hu Siquan <husq@xbow.com>
 *
 *  $Id: MicDeviceP.nc,v 1.1 2007-02-15 10:33:38 pipeng Exp $
 */

#include "mts300.h"
#include "I2C.h"
configuration MicDeviceP {
  provides {
    interface Init;
    interface StdControl;
    interface Mic;
    interface MicInterrupt;
    interface ResourceConfigure;
    interface Atm128AdcConfig;
  }
}
implementation {
  components MicP, MicaBusC, HplAtm128GeneralIOC as Pins,
      HplAtm128InterruptC as IntPins, LedsC, NoLedsC,
  		new Atm128I2CMasterC() as I2CPot;

	Init = MicP;
	StdControl = MicP;
	ResourceConfigure = MicP;
	Atm128AdcConfig = MicP;
	Mic = MicP;
	MicInterrupt = MicP;

  MicP.MicPower  -> MicaBusC.PW3;
  MicP.MicMuxSel -> MicaBusC.PW6;
  MicP.MicAdc -> MicaBusC.Adc2;
  MicP.I2CPacket -> I2CPot;
  MicP.Resource -> I2CPot;
  MicP.AlertInterrupt -> IntPins.Int7;
  MicP.DebugLeds -> NoLedsC;
}
