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

  public class EventArgMessage : EventArgs
  {
    byte[] msg;
    public EventArgMessage(byte[] msg) {
      int len = msg.Length;
      this.msg = new byte[len];
      Array.Copy(msg, 0, this.msg, 0, len);
    }
    public byte[] getMsg() {
      return msg;
    }
  }

  public abstract class MessageSource
  {
    public event EventHandler<EventArgs> TxPacket;
    public event EventHandler<EventArgs> RxPacket;
    public event EventHandler<EventArgs> ToutPacket;
    public event EventHandler<EventArgMessage> messageArrivedEvent;
    public abstract int Send(byte[] message);
    public abstract void Close();
    protected void RaiseMessageArrived(EventArgMessage msg) {
      RaiseRxPacket(); 
      EventHandler<EventArgMessage> handler = messageArrivedEvent;
      if (handler != null) {
        handler(this, msg);
      }
    }

    protected virtual void RaiseToutPacket() {
      if (ToutPacket != null) ToutPacket(this, null);
    }

    protected virtual void RaiseTxPacket() {
      if (TxPacket != null) TxPacket(this, null);
    }

    protected virtual void RaiseRxPacket() {
      if (RxPacket != null) RxPacket(this, null);
    }
  }
}
