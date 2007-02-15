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
 *  @author Martin Turon <mturon@xbow.com>
 *  @author Hu Siquan <husq@xbow.com>
 *
 *  $Id: SensorMts300C.nc,v 1.5 2007-02-15 10:28:46 pipeng Exp $
 */

//configuration SensorMts300C
generic configuration SensorMts300C()
{
  provides
  {
   	interface Init;                 //!< Standard Initialization
   	interface StdControl;           //!< Start/Stop for Power Management
   	interface Read<uint16_t> as Vref; //!< voltage
   	interface Read<uint16_t> as Temp; //!< Thermister
  	interface Read<uint16_t> as Light; //!< Photo sensor
   	interface Read<uint16_t> as Microphone; //!< Mic sensor
   	interface Read<uint16_t> as AccelX; //!< Accelerometer sensor
   	interface Read<uint16_t> as AccelY; //!< Accelerometer sensor
   	interface Read<uint16_t> as MagX; //!< magnetometer sensor
   	interface Read<uint16_t> as MagY; //!< magnetometer sensor
  }
}
implementation
{
    components 	SensorMts300P,	HplAtm128GeneralIOC as IO,
    new VoltageC(),
    new PhotoC(),
    new TempC(),
    new MicC(),
    new MagC(),
    new AccelC(),
	  new TimerMilliC() as WarmUpTimer;

    Init       = SensorMts300P.Init;
    Init       = PhotoC.Init;
    Init       = MicC.Init;
    StdControl = SensorMts300P.StdControl;
    Vref       = SensorMts300P.Vref;
    Temp       = SensorMts300P.Temp;
    Light      = SensorMts300P.Light;
    Microphone = SensorMts300P.Microphone;
    AccelX     = SensorMts300P.AccelX;
    AccelY     = SensorMts300P.AccelY;
    MagX       = SensorMts300P.MagX;
    MagY       = SensorMts300P.MagY;

    SensorMts300P.WarmUpTimer -> WarmUpTimer;

    SensorMts300P.VrefRead -> VoltageC.Read;
    SensorMts300P.PhotoControl -> PhotoC.StdControl;
    SensorMts300P.TempRead -> TempC.Read;
    SensorMts300P.LightRead -> PhotoC.Read;
    SensorMts300P.LightPower -> IO.PortE5;
    SensorMts300P.TempPower -> IO.PortE6;

    SensorMts300P.MicControl -> MicC.StdControl;
    SensorMts300P.Mic -> MicC.Mic;
    SensorMts300P.MicRead -> MicC.Read;

    SensorMts300P.MagControl -> MagC.StdControl;
    SensorMts300P.Mag -> MagC.Mag;
    SensorMts300P.MagXRead -> MagC.MagX;
    SensorMts300P.MagYRead -> MagC.MagY;

    SensorMts300P.AccelControl -> AccelC.StdControl;
    SensorMts300P.AccelXRead -> AccelC.AccelX;
    SensorMts300P.AccelYRead -> AccelC.AccelY;
    
}
