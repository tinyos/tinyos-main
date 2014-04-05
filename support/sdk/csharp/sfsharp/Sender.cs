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
using tinyos.sdk;

namespace sfsharp
{
  class Sender
  {
    string motecom;
    string payload;
    Boolean listen = false;
    Prompt prompt;
    MoteIF mote;

    public Sender(ArrayList args, Prompt prompt) {
      this.prompt = prompt;
      if (!ParseArgs(args)) {
        prompt.WriteLine("send: wrong arguments", prompt.errorTextColor);
        return;
      }
      try{
        mote = new MoteIF(motecom);
      }
      catch(Exception e){
        prompt.WriteLine(e.Message, prompt.errorTextColor);
        return;
      }
    }

    public Object SendOne(uint dest, uint src, uint group, uint amtype) {
      if (mote==null)
        return null;
      byte[] bpayload = SerialMessage.HexStringToByteArray(payload);
      SerialMessage msg = new SerialMessage(bpayload, (byte)amtype);
      msg[SerialMessage.DEST] = dest;
      msg[SerialMessage.SRC] = src;
      msg[SerialMessage.GROUP] = group;
      mote.Send(msg);
      prompt.WriteLine("Packet sent", prompt.successTextColor);

      if (listen) {
        return new Listener(mote, prompt);
      }
      mote.Close();
      return null;
    }

    public Object SendOne(SerialMessage msg) {
      if (mote==null)
        return null;
      mote.Send(msg);
      prompt.WriteLine("Packet sent", prompt.successTextColor);

      if (listen) {
        return new Listener(mote, prompt);
      }

      mote.Close();
      return null;
    }

    private bool ParseArgs(ArrayList args) {
      if (args.Count < 5 || args.Count > 6)
        return false;

      for (int i = 1; i < args.Count; i += 1) {
        switch (args[i].ToString()) {
          case "-comm":
            if (++i < args.Count) {
              motecom = args[i].ToString();
              break;
            }
            else prompt.WriteLine("send: wrong arguments", prompt.errorTextColor);
            return false;

          case "-m":
            if (++i < args.Count) {
              payload = args[i].ToString();
              break;
            }
            else prompt.WriteLine("send: wrong arguments", prompt.errorTextColor);
            return false;

          case "-listen":
            listen = true;
            break;
        }
      }
      if (motecom == null || payload == null) {
        return false;
      }
      return true;
    }

    static public void PrintHelp(Prompt prompt) {
      prompt.WriteLine("USAGE");
      prompt.WriteLine("  send -comm <MOTECOM> -m <MESSAGE> [-listen]", prompt.helpTextColor);
      prompt.WriteLine("");
      prompt.WriteLine("DESCRIPTION");
      prompt.WriteLine("  Sends a MESSAGE in hex format throught the");
      prompt.WriteLine("  specified MOTECOM. Optionally a listen connection");
      prompt.WriteLine("  can be opened right after the send command ends.");
      prompt.WriteLine("  MESSAGE is the payload of the serial packet. Use");
      prompt.WriteLine("  the SET command to specify AM, DEST, SRC and GROUP.");
      prompt.WriteLine("  See also 'help set'.");
      prompt.WriteLine("");
      prompt.WriteLine("EXAMPLE");
      prompt.WriteLine("  set am 137");
      prompt.WriteLine("  set dest 5");
      prompt.WriteLine("  send -comm serial@COM25:115200 -m B0047C04E1");
      prompt.WriteLine("  send -comm sf@localhost:9000 -m 0001 -listen");
    }
  }
}
