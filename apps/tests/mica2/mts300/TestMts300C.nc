// $Id: TestMts300C.nc,v 1.5 2007-02-15 10:23:30 pipeng Exp $

/*
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Copyright (c) 2004-2006 Crossbow Technology, Inc.
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
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 *  TinyOS 1.x to TinyOS 2.x translation layer.
 *
 *  @author Alif <rlchen@xbow.com.cn>  
 */

#include "XMTS300.h"
#include "mts300.h"

configuration TestMts300C
{
}
implementation
{
  components MainC, TestMts300P, LedsC, NoLedsC;
  components new TimerMilliC() as MTS300Timer;

  components ActiveMessageC as Radio;
  components SerialActiveMessageC as Serial;

// sensorboard devices
  components new SensorMts300C();
  components SounderC;

  TestMts300P -> MainC.Boot;

  TestMts300P.MTS300Timer -> MTS300Timer;
  TestMts300P.Leds -> NoLedsC;

  // communication
  TestMts300P.RadioControl -> Radio;
  TestMts300P.RadioSend -> Radio.AMSend[AM_MTS300MSG];
  TestMts300P.RadioPacket -> Radio;

  TestMts300P.UartControl -> Serial;
  TestMts300P.UartSend -> Serial.AMSend[AM_MTS300MSG];
  TestMts300P.UartPacket -> Serial;

  // sensor components
  MainC.SoftwareInit -> SensorMts300C;
  TestMts300P.MTS300Control -> SensorMts300C.StdControl;
  TestMts300P.Vref -> SensorMts300C.Vref;
  TestMts300P.Light -> SensorMts300C.Light;
  TestMts300P.Temp -> SensorMts300C.Temp;
  TestMts300P.Microphone -> SensorMts300C.Microphone;
  TestMts300P.AccelX -> SensorMts300C.AccelX;
  TestMts300P.AccelY -> SensorMts300C.AccelY;
  TestMts300P.MagX -> SensorMts300C.MagX;
  TestMts300P.MagY -> SensorMts300C.MagY;

  MainC.SoftwareInit -> SounderC;
  TestMts300P.Sounder -> SounderC;
}
