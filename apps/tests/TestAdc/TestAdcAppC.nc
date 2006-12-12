/*
 * Copyright (c) 2004, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Revision -------------------------------------------------------------
 * $Revision: 1.4 $
 * $Date: 2006-12-12 18:22:49 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

/**
 * Tests the AdcC subsystem and switches on leds 0, 1 and 2
 * if the test is successful:
 * LED0 denotes a successful Read operation,
 * LED1 denotes a successful ReadNow operation,
 * LED2 denotes a successful ReadStream operation.
 *
 * Requires a platform-specific DemoSensorC component that provides
 * Read<uint16_t>, a platform-specific DemoSensorStreamC component that provides
 * ReadStream<uint16_t> and a platform-specific DemoSensorNowC component that provides
 * ReadNow<uint16_t> and Resource
 *
 * @author Jan Hauer
 */
configuration TestAdcAppC {
}
implementation
{
  components MainC,
             TestAdcC,
             new DemoSensorC() as Sensor,
             new DemoSensorNowC() as SensorNow,
             new DemoSensorStreamC() as SensorStream,
             LedsC;

  TestAdcC -> MainC.Boot;
  
  TestAdcC.Leds -> LedsC;
  TestAdcC.Read -> Sensor;
  TestAdcC.ReadNow -> SensorNow;
  TestAdcC.ReadNowResource -> SensorNow;
  TestAdcC.ReadStream -> SensorStream;
}

