/**
 *  Copyright (c) 2005-2006 Crossbow Technology, Inc.
 *  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holders nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *  @author Martin Turon <mturon@xbow.com>
 *  @author Hu Siquan <husq@xbow.com>
 *
 *  $Id: SensorMts300C.nc,v 1.9 2010-06-29 22:07:56 scipio Exp $
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
