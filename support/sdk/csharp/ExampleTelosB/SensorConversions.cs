/*
 * Copyright (c) 2013, ADVANTIC Sistemas y Servicios S.L.
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
 * - Neither the name of ADVANTIC Sistemas y Servicios S.L. nor the names 
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
 */
/**
 * @author Eloy Díaz Álvarez <eldial@gmail.com>
 */

using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace ExampleTelosB
{
  public static class SensorConversions
  {
    public static double GetTemperature(uint raw) {
      // return Math.Round((-42.1 + 0.01 * raw), 2);// calibrated
      return Math.Round((-39.9 + 0.01 * raw), 2);
    }


    public static double GetVcc(uint raw) {
      return Math.Round((((double)raw / 4096.0) * 1.5 * 2), 2);
    }

    public static double GetHum(uint raw) {
      return Math.Round((-2.0468 + 0.0367 * raw + (-1.5955 * 10e-6) * (raw ^ 2)), 2);
    }

    public static double GetPhoto(uint raw) {
      double vRef = 1.5;
      double k11 = 0.625;
      double R11 = 100000.0;
      double c1 = 10e6;
      double c2 = 1000.0;

      double Vs = ((double)raw / 4096.0) * vRef;
      return Math.Round((k11 * c1 * (Vs / R11) * c2), 2);
    }

    public static double GetRadiation(uint raw) {
      double vRef = 1.5;
      double k12 = 0.769;
      double R12 = 100000.0;
      double c1 = 10e5;
      double c2 = 1000.0;
      double Vs = ((double)raw / 4096.0) * vRef;
      return Math.Round((k12 * c1 * (Vs / R12) * c2), 2);
    }
  }
}
