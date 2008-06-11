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
 *  $Id: SensorMts300C.nc,v 1.8 2008-06-11 00:42:14 razvanm Exp $
 */

//configuration SensorMts300C
generic configuration SensorMts300C()
{
  provides
  {
   	interface Mts300Sounder as Sounder; //!< sounder
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
    components SounderC,
    new VoltageC(),
    new AccelXC(),
    new AccelYC(),
    new PhotoC(),
    new TempC(),
    new MicC(),
    new MagXC(),
    new MagYC();

    Sounder    = SounderC;
    Vref       = VoltageC;
    Temp       = TempC;
    Light      = PhotoC;
    Microphone = MicC;
    AccelX     = AccelXC;
    AccelY     = AccelYC;
    MagX       = MagXC;
    MagY       = MagYC;
}
