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


namespace tinyos.sdk
{
  public class EventArgSerialMessage : EventArgs {
    public SerialMessage msg { set; get; }  
  }

  public class MoteIF
  {
    MessageSource messageSource;
    public event EventHandler<EventArgSerialMessage> onMessageArrived;
    public string motecom { get; private set; }

    public MoteIF(string motecom) {
      try {
        messageSource = SourceMaker.make(motecom);
        this.motecom = motecom;
        messageSource.messageArrivedEvent += onReceive;
      } catch (Exception e) { throw e; }
    }


    public MoteIF(MessageSource src) {
      messageSource = src;
      messageSource.messageArrivedEvent += onReceive;
    }

    public void Send(Message m) {
      if (messageSource == null) return;
      try{
        messageSource.Send(m.GetMessageBytes());
      } catch(Exception e){ throw e;}
    }

    public void Close() {
      if (messageSource!=null)
        messageSource.Close();
    }

    private void onReceive(object sender, EventArgMessage msg) {
      Message recMsg;
      try {
        recMsg = new SerialMessage(msg.getMsg());
        EventArgSerialMessage eventArgSerialMessage = new EventArgSerialMessage();
        eventArgSerialMessage.msg = (SerialMessage)recMsg;
        EventHandler<EventArgSerialMessage> handler = onMessageArrived;
        if (handler != null) {
          handler(this, eventArgSerialMessage);
        }
      } catch (Exception e) { throw e; }
    }
  }
}
