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
using System.Threading;
using tinyos.sdk;


/* 
 * This example program shows the basic usage of the SDK. 
 * At least 2 telosb motes are required to run this application. 
 * 
 * Follow these steps:
 * 
 * 1. Load TinyOS BaseStation app in one mote
 * 
 * 2. Load TestCM5000 on the second mote 
 *    (code can be found in this page:
 *     http://www.advanticsys.com/wiki/index.php?title=TestCM5000)
 * 
 * 3. Connect BaseStation node to an USB port and find the 
 *    COM port assigned (e.g. COM1)
 * 
 * 4. Launch the app:  ExampleTelosB -comm serial@COM1:115200
 * 
 */


namespace ExampleTelosB
{
  class Program
  {

    private static MoteIF mote;

    static void Main(string[] args) {
      if (args.Length != 2 || !args[0].Equals("-comm")) {
        string exename= System.AppDomain.CurrentDomain.FriendlyName;
        Console.WriteLine("Usage: {0} -comm <source>", exename);
        Console.WriteLine("e.g. {0} -comm serial@com27:115200", exename);
        Console.ReadKey();
        return;
      }
      mote = new MoteIF(args[1]);
      mote.onMessageArrived += mote_onMessageArrived;
      var evt = new AutoResetEvent(false);
      evt.WaitOne();
    }

    static void mote_onMessageArrived(object sender, EventArgSerialMessage e) {
      MoteMessage data = new MoteMessage(e.msg.GetPayload());
      data.Print();
    }
  }
}
