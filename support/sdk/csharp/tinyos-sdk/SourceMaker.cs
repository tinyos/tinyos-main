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
using System.Diagnostics;

namespace tinyos.sdk
{
  public static class SourceMaker
  {
    public static MessageSource make(string motecom) {
      //string errsrc = "\nUnable to create or connect to {0}\n";
      MessageSource messageSource = null;
      string[] words = motecom.Split('@');
      string[] args;
      if (words.Length != 2)
        throw new Exception("Could not make MessageSource");

      if (words[0].Equals("serial")) {
        args = words[1].Split(':');
        try {
          messageSource = new SerialSource(args[0], Convert.ToInt32(args[1]));
        } catch (Exception e) {
          Debug.WriteLine(e.Message);
          throw new Exception("Could not make serial source (bad port?)");
        }
      }
      else if (words[0].Equals("sf")) {
        args = words[1].Split(':');
        try {
          messageSource = new SFSource();
          ((SFSource)messageSource).Connect(args[0], Convert.ToInt32(args[1]));
        } catch (Exception e) {
          Debug.WriteLine(e.Message);
          throw new Exception("Could not make sf source (bad ip/port?)");
        }
      }
      return messageSource;
    }
  }
}
