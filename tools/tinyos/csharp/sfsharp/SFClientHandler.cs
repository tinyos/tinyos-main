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
using System.Net.Sockets;
using System.Threading;
using System.Net;
using tinyos.sdk;

namespace sfsharp
{

  class ClientClosedEvtArg : EventArgs
  {

    public ClientClosedEvtArg(string msg) {
      this.msg = msg;
    }
    public string msg;
  }

  class MoteIFClosedEvtArg : EventArgs
  {

    public MoteIFClosedEvtArg(string msg) {
      this.msg = msg;
    }
    public string msg;
  }

  class SFClientHandler : SFSource
  {
    private MessageSource mote;
    public event EventHandler<ClientClosedEvtArg> ClientClosedEvent;
    public event EventHandler<MoteIFClosedEvtArg> MoteIFClosedEvent;
    public uint id { get; set; }

    public SFClientHandler(TcpClient tcpClient, MessageSource msgSrc, uint id) {
      this.id = id;
      this.mote = msgSrc;
      msgSrc.messageArrivedEvent += OnMoteMessageArrived;
      this.messageArrivedEvent += OnTCPMessageArrived;
      this.tcpClient = tcpClient;
      this.stream = this.tcpClient.GetStream();
      try {
        Handshake();
        Start();
      } catch (Exception e) { Console.Write(e.Message); }
    }

    protected new void Handshake() {
      try {
        stream = tcpClient.GetStream();
        stream.Write(VERSION, 0, VERSION.Length);
        byte[] partnerV = readN(2);
        if (!partnerV.SequenceEqual(VERSION)) {
          throw new Exception("Incompatible version of remote SF client\n");
        }
      } catch (Exception e) { throw e; }
    }

    private void OnMoteMessageArrived(object sender, EventArgMessage msg) {

      if (!tcpClient.Connected) {
        return;
      }
      try {
        this.Send(msg.getMsg());
      } catch (Exception e) {
        RaiseEventClientDC(e.Message);
        this.tcpClient.Close();
      }
    }

    private void RaiseEventClientDC(string msg) {
      EventHandler<ClientClosedEvtArg> handler = ClientClosedEvent;
      if (handler != null) {
        handler(this, new ClientClosedEvtArg(msg));
      }
    }

    private void RaiseEventMoteDC(string msg) {
      EventHandler<MoteIFClosedEvtArg> handler = MoteIFClosedEvent;
      if (handler != null) {
        handler(this, new MoteIFClosedEvtArg(msg));
      }
    }

    private void OnTCPMessageArrived(object sender, EventArgMessage msg) {
      Thread moteMessenger = new Thread(new ParameterizedThreadStart(SendMessageToMote));
      moteMessenger.Start(msg.getMsg());
    }

    private void SendMessageToMote(Object msg) {
      try {
        mote.Send((byte[])msg);
      } catch (Exception e) {
        RaiseEventMoteDC(e.Message);
      }
    }
  }
}
