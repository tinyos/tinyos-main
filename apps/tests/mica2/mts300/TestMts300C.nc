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
 *
 *  $Id: TestMts300C.nc,v 1.3 2006-11-07 19:30:37 scipio Exp $
 */

/**
 * This application tests the mts300 sensorboard.
 * Specifically, this handles the thermistor and light sensors.
 * 
 * @author  Martin Turon
 * @date    October 19, 2005
 */
configuration TestMts300C {
}
implementation
{
  components MainC, TestMts300P, LedsC, new OskiTimerMilliC(),
      SensorMts300C;

  
  MainC.SoftwareInit -> SensorMts300C;

  TestMts300P -> MainC.Boot;
  TestMts300P.Leds -> LedsC;
  TestMts300P.AppTimer -> OskiTimerMilliC;

  TestMts300P.SensorControl -> SensorMts300C;
  TestMts300P.Temp -> SensorMts300C.Temp;
  TestMts300P.Light -> SensorMts300C.Light;
}

