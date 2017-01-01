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
using System.Collections;
using System.Threading;
using tinyos.sdk;

namespace sfsharp
{
  class Listener
  {
    Prompt prompt;
    //AutoResetEvent evt;
    MoteIF mote;
    string motecom;
    public Boolean active;

    public Listener(ArrayList args, Prompt prompt) {
      if (args.Count != 3) {
        prompt.WriteLine("listen: Wrong arguments", prompt.errorTextColor);
        return;
      }
      this.prompt = prompt;
      motecom = args[2].ToString();
      try {
        mote = new MoteIF(motecom);
      } catch (Exception e) {
        prompt.WriteLine(e.Message, prompt.errorTextColor);
        return;
      }
      active = true;
      prompt.WriteLine("Listening on " + motecom + " (^C or 'exit' returns to prompt)", prompt.successTextColor);
      //Console.TreatControlCAsInput = false;
      //Console.CancelKeyPress += stop;
      mote.onMessageArrived += newMsgHandler;
      //evt = new AutoResetEvent(false);
      //evt.WaitOne();
      //Console.TreatControlCAsInput = true;
      //Console.CancelKeyPress -= stop;
    }

    public Listener(MoteIF mote, Prompt prompt) {

      if (mote == null) {
        return;
      }

      motecom = mote.motecom;
      active = true;
      this.mote = mote;
      this.prompt = prompt;
      prompt.WriteLine("Listening on " +motecom+ " (^C or 'exit' returns to prompt)", prompt.successTextColor);
      //Console.CancelKeyPress += stop;
      mote.onMessageArrived += newMsgHandler;
      //evt = new AutoResetEvent(false);
      //evt.WaitOne();
      //Console.CancelKeyPress -= stop;
    }

    public void stop(/*Object s, ConsoleCancelEventArgs e*/) {
      prompt.WriteLine("Closing listener on " + motecom + "...", prompt.successTextColor);
      //e.Cancel = true;
      mote.onMessageArrived -= newMsgHandler;
      mote.Close();
      //evt.Set();
    }

    private void newMsgHandler(Object sender, EventArgSerialMessage e) {
      prompt.WriteLine(BitConverter.ToString(e.msg.GetMessageBytes(), 0), Console.ForegroundColor);
    }

    static public void PrintHelp(Prompt prompt) {
      prompt.WriteLine("USAGE");
      prompt.WriteLine("  listen -comm <MOTECOM>", prompt.helpTextColor);
      prompt.WriteLine("");
      prompt.WriteLine("DESCRIPTION");
      prompt.WriteLine("  Listen for serial packets from the given MOTECOM");
      prompt.WriteLine("  Ctrl+C closes the listener for the local client. ");
      prompt.WriteLine("  The control client stops the listener with an 'exit' command.");
      prompt.WriteLine("");
      prompt.WriteLine("EXAMPLE");
      prompt.WriteLine("  listen -comm serial@COM25:115200");
      prompt.WriteLine("  listen -comm sf@localhost:9000");
    }
  }
}
