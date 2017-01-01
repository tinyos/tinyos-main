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
using System.Text;
using System.Linq;
using System.Net.Sockets;
using System.Threading;
using System.Net;
using System.Collections;
using System.Collections.Generic;
using System.Diagnostics;
using tinyos.sdk;

namespace sfsharp
{
  class SerialForwarder
  {
    private TcpListener tcpListener;
    private Thread connectionReceiver;
    MessageSource mote;
    string motecom;
    public int port = 0;
    //int maxClients;
    //int expirationTimeout;
    Prompt prompt;
    public uint id;
    uint clientId = 0;
    List<SFClientHandler> clients = new List<SFClientHandler>();
    private static Mutex mutex = new Mutex();
    public bool running = false;
    object op = new Object();
    uint totalRx = 0;
    uint totalTx = 0;
    uint moteTx = 0;
    uint moteRx = 0;
    uint moteTout = 0;
    public event EventHandler<EventArgs> moteConnLost;

    public SerialForwarder(ArrayList args, Prompt prompt, uint id) {
      this.id = id;
      this.prompt = prompt;
      for (int i = 1, l = args.Count; i < l; i++) {
        switch (args[i].ToString()) {
          case "-c":
            if (++i == l) {
              WriteLine("start: wrong arguments", prompt.errorTextColor);
              return;
            }
            else
              // TODO
              //maxClients = Convert.ToInt32(args[i].ToString());
            break;

          case "-e":
            if (++i == l) {
              WriteLine("start: wrong arguments", prompt.errorTextColor);
              return;
            }
            else
              //TODO
              //expirationTimeout = Convert.ToInt32(args[i].ToString());
            break;

          case "-comm":
            if (++i == l) {
              prompt.WriteLine("start: wrong arguments", prompt.errorTextColor);
              return;
            }
            else motecom = args[i].ToString();
            break;

          case "-port":
            if (++i == l) {
              WriteLine("start: wrong arguments", prompt.errorTextColor);
              return;
            }
            else
              try {
                port = Convert.ToUInt16(args[i].ToString());
              } catch (Exception) {
                port = 0;
              }
              
            break;

          default:
            WriteLine("start: wrong arguments", prompt.errorTextColor);
            return;
        }
      }
      try {
        mote = SourceMaker.make(motecom);
      } catch (Exception e) {
        Debug.WriteLine(e.Message);
        WriteLine("start: unable to open " + motecom, prompt.errorTextColor);
        return;
      }

      if (mote == null || port == 0) {
        WriteLine("start: wrong arguments", prompt.errorTextColor);
        return;
      }
      mote.RxPacket += mote_RxPacket;
      mote.TxPacket += mote_TxPacket;
      mote.ToutPacket += mote_ToutPacket;
      tcpListener = new TcpListener(IPAddress.Any, port);

      try {
        tcpListener.Start();
      } catch (SocketException se) {
        Debug.WriteLine(se.Message);
        WriteLine("Unable to open socket on port " + port + "( port in use?)", prompt.errorTextColor);
        mote.Close();
        return;
      }

      connectionReceiver = new Thread(new ThreadStart(ListenForClients));
      connectionReceiver.Start();
      running = true;
      WriteLine("Serial forwarder started (id = " + id.ToString() + "). Waiting for clients on port " 
        + port.ToString(), prompt.successTextColor);
    }

    void mote_ToutPacket(object sender, EventArgs e) {
      moteTout++;
    }

    void mote_TxPacket(object sender, EventArgs e) {
      moteTx++;
    }

    void mote_RxPacket(object sender, EventArgs e) {
      moteRx++;
    }

    private enum msgType
    {
      ERROR,
      SUCCESS,
    }
    private void WriteLine(string msg, ConsoleColor c) {
      if (prompt != null) {
        prompt.WriteLine(msg, c);
        return;
      }
      Console.WriteLine(msg);
    }

    private void ListenForClients() {
      bool listen = true;
      while (listen) {
        try {
          //Esperar conexion de cliente
          TcpClient newTCPClient = tcpListener.AcceptTcpClient();
          WriteLine("New client connected to Serial forwarder (id = " + id.ToString() + ") on port " 
            + port.ToString(), prompt.eventTextColor);
          SFClientHandler newClient = new SFClientHandler(newTCPClient, mote, clientId);
          newClient.RxPacket += newClient_RxPacket;
          newClient.TxPacket += newClient_TxPacket;
          AddClient(newClient);
          newClient.ClientClosedEvent += ClientDC;
          newClient.MoteIFClosedEvent += newClient_MoteIFClosedEvent;
        } catch (Exception e) {
          // WSACancelBlockingCall issue:
          // When tcpListener.Close() is called from another
          // thread, WSACancelBlockingCall exception is thrown
          // from the AcceptTcpClient() method.
          // Catching the exception is just a 'workaround', as this
          // shouldn't happen.
          listen = false;
          Debug.WriteLine(e.Message);
        }
      }
    }

    void newClient_MoteIFClosedEvent(object sender, MoteIFClosedEvtArg e) {
      WriteLine(motecom + " is not responding. Closing Serial forwarder (id = " + id.ToString() + ")", prompt.errorTextColor);
      //CloseAll();
      if (moteConnLost != null) moteConnLost(this, null);
    }

    void newClient_TxPacket(object sender, EventArgs e) {
      // lock increment as this event handler
      // is called by multiple client threads
      lock (op) {
        totalTx++;
      }
    }

    void newClient_RxPacket(object sender, EventArgs e) {
      lock (op) {
        totalRx++;
      }
    }

    private void ClientDC(Object src, ClientClosedEvtArg arg) {
      WriteLine("Client disconnected from Serial forwarder (id = " + id.ToString() + ") on port " 
        + port.ToString(), prompt.eventTextColor);
      SFClientHandler c = (SFClientHandler)src;
      RemoveClient(c);
    }

    private void AddClient(SFClientHandler newClient) {
      mutex.WaitOne();
      clients.Add(newClient);
      clientId++;
      mutex.ReleaseMutex();
    } 

    private void RemoveClient(SFClientHandler client) {
      mutex.WaitOne();
      clients.Remove(client);
      mutex.ReleaseMutex();
    }

    public void PrintIdMessage() {
      ConsoleColor c = prompt.helpTextColor;
      prompt.Write("SF id ", true);
      prompt.Write(id.ToString(), c, false);
      prompt.Write(" port ", false);
      prompt.Write(port.ToString(), c, false);
      prompt.Write(" comm ", false);
      prompt.Write(motecom + "\n", c, false);
    }

    public void Info() {
      // TODO mutex on Prompt.Write methods
      PrintIdMessage();
      ConsoleColor c = prompt.helpTextColor;
      prompt.Write("Client interface:", true);
      prompt.Write(" port ", false);
      prompt.Write(port.ToString(), c, false);
      prompt.Write(" clients ", false);
      prompt.Write(clients.Count.ToString(), c, false);
      prompt.Write(" RX packets ", false);
      prompt.Write(totalRx.ToString(), c, false);
      prompt.Write(" TX packets ", false);
      prompt.Write(totalTx.ToString()+ "\n", c, false);

      prompt.Write("Mote interface:", true);
      prompt.Write(" comm ", false);
      prompt.Write(motecom, c, false);
      prompt.Write(" RX packets ", false);
      prompt.Write(moteRx.ToString(), c, false);
      prompt.Write(" TX packets ", false);
      prompt.Write(moteTx.ToString(), c, false);
      prompt.Write(" Tout ", false);
      prompt.Write(moteTout.ToString() + "\n", c, false);
    }

    public void CloseAll() {
      mutex.WaitOne();
      for (int i = 0, l = clients.Count; i < l; i++)
        clients[i].Close();
      mutex.ReleaseMutex();
      mote.Close();
      tcpListener.Stop();
      WriteLine("Serial forwarder (id = " + this.id + ") stopped", prompt.successTextColor);
    }

    public static void PrintStartHelp(Prompt prompt) {

      prompt.WriteLine("USAGE");
      prompt.WriteLine("  start -port <TCP_PORT> -comm <MOTECOM>", prompt.helpTextColor);
      prompt.WriteLine("");
      prompt.WriteLine("DESCRIPTION");
      prompt.WriteLine("  Starts a new sf-server listening for clients on the specified TCP Port,");
      prompt.WriteLine("  with the specified MOTECOM as packets source, which can be a serial");
      prompt.WriteLine("  device or a serial forwarder.");
      prompt.WriteLine("");
      /* TODO
      prompt.WriteLine("OPTIONS");
      prompt.WriteLine("  -c MAX_CLIENTS: Maximum number of clients allowed to connect to ");
      prompt.WriteLine("                  the created sf-server. No client limit if no specified.");
      prompt.WriteLine("  -e TIME: Time (in seconds) after which the created sf-server will be");
      prompt.WriteLine("           destroyed. No sf-expiration if no specified.");
      prompt.WriteLine("");
       * */
      prompt.WriteLine("EXAMPLE");
      prompt.WriteLine("  start -port 9000 -comm serial@COM9:115200");
      prompt.WriteLine("  start -port 9001 -comm sf@localhost:9000");
      prompt.WriteLine("  start -port 7777 -comm serial@/dev/ttyUSB0:115200");
      prompt.WriteLine("  start -port 7778 -comm sf@198.168.0.101:9000");
    }

    public static void PrintStopHelp(Prompt prompt) {

      prompt.WriteLine("USAGE");
      prompt.WriteLine("  stop <ID | PORT>", prompt.helpTextColor);
      prompt.WriteLine("");
      prompt.WriteLine("DESCRIPTION");
      prompt.WriteLine("  Stops the specified sf server.");
    }

    public static void PrintListHelp(Prompt prompt) {
      prompt.WriteLine("Lists all running sf-servers.");
    }

    public static void PrintInfoHelp(Prompt prompt) {
      prompt.WriteLine("USAGE");
      prompt.WriteLine("  info <ID | PORT>", prompt.helpTextColor);
      prompt.WriteLine("");
      prompt.WriteLine("DESCRIPTION");
      prompt.WriteLine("  Prints out stats about the specified sf-server.");
    }
  }
}
