/**
 *  Copyright (c) 2004-2005 Crossbow Technology, Inc.
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
 *  @author Martin Turon <mturon@xbow.com>
 *  @author Miguel Freitas
 *
 *  $Id: SensorMts300C.nc,v 1.3 2006-11-07 19:31:27 scipio Exp $
 */

configuration SensorMts300C
{
    provides {
	interface Init;                 //!< Standard Initialization
	interface StdControl;           //!< Start/Stop for Power Management
	interface Read<uint16_t> as Temp;  //!< Thermister
	interface Read<uint16_t> as Light; //!< Photo sensor
    }
}
implementation 
{
    components 
	SensorMts300P,
	SensorMts300DeviceP,
	HplAtm128GeneralIOC as IO,
	new AdcReadClientC() as SensorADC,
	new TimerMilliC() as WarmUpTimer
	;

    Init       = SensorMts300P.Init;
    StdControl = SensorMts300P.StdControl;
    Temp       = SensorMts300P.Temp;
    Light      = SensorMts300P.Light;

    SensorADC.Atm128AdcConfig -> SensorMts300DeviceP;
    SensorADC.ResourceConfigure -> SensorMts300DeviceP;

    SensorMts300P.SensorADC -> SensorADC;
    SensorMts300P.TempPower -> IO.PortE6;
    SensorMts300P.LightPower -> IO.PortE5;
    SensorMts300P.WarmUpTimer -> WarmUpTimer;
}
