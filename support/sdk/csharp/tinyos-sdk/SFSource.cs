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
using System.Net.Sockets;
using System.Diagnostics;


namespace tinyos.sdk
{
  public class SFSource : MessageSource
  {
    protected byte[] VERSION = { (byte)'U', 
                       (byte)' ' };
    protected NetworkStream stream;
    protected Thread inputListenThread;
    protected Boolean listenInputStream;
    protected TcpClient tcpClient;

    public void Connect(String host, int port) {
      if (tcpClient != null)
        return;
      tcpClient = new TcpClient();
      try {
        tcpClient.Connect(host, port);
        Handshake();
        Start();
      } catch (Exception e) { throw e; }
    }

    protected void Start() {
      try {
        inputListenThread = new Thread(new ThreadStart(ListenInputDataStream));
        StartListeningThread();
      } catch (Exception e) { throw e; }
    }

    protected void Handshake() {
      try {
        stream = tcpClient.GetStream();
        byte[] partnerV = readN(2);
        if (!partnerV.SequenceEqual(VERSION)) {
          throw new Exception("Incompatible version of remote SF server\n");
        }
        stream.Write(VERSION, 0, VERSION.Length);
      } catch (Exception e) { throw e; }
    }

    public void StartListeningThread() {
      if (inputListenThread == null) return;
      if (!inputListenThread.IsAlive) {
        listenInputStream = true;
        try {
          inputListenThread.Start();
        } catch (Exception e) { throw e; }
      }
    }

    public void StopListeningThread() {
      if (inputListenThread == null) return;
      if (inputListenThread.IsAlive) {
        listenInputStream = false;
      }
    }

    public Boolean IsConnectionAlive() {
      return tcpClient.Connected;
    }

    public void ListenInputDataStream() {
      while (listenInputStream) {
        try {
          byte[] size = new byte[1];
          size = readN(1);
          if (size.Length==0) continue;
          byte[] message = readN((int)size[0]);
          if (message.Length == 0) continue;
          RaiseMessageArrived(new EventArgMessage(message));
        } catch (Exception e) {
          listenInputStream = false;
          Debug.WriteLine(e.Message);
        }
      }
    }

    public override int Send(byte[] message) {
      try {
        byte len = (byte)message.Length;
        stream.WriteByte(len);
        stream.Write(message, 0, len);
        RaiseTxPacket();
      } catch (Exception e) { throw e; }
      return 1;
    }

    public override void Close() {
      if (tcpClient!=null)
        try {
          if (this.tcpClient.Connected)
            this.tcpClient.Close();
        } catch (Exception e) {
          Debug.WriteLine(e.Message);
        }
      this.StopListeningThread();
    }

    protected byte[] readN(int n) {
      byte[] data = new byte[n];
      int offset = 0;

      while (offset < n) {
        try {
          int count = stream.Read(data, offset, n - offset);
          if (count == 0) {
            return data;
          }
          offset += count;
        } catch (Exception e) { throw e; }
      }
      return data;
    }
  }
}
