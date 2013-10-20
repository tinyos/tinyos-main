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
using System.IO.Ports;
using System.Management;
using System.Diagnostics;
using tinyos.sdk;

namespace sfsharp
{
  class SFMain
  {
    private TcpListener tcpListener;
    NetworkStream controlClient;
    private Thread tcpClient;
    private Thread stdinClient;
    private int controlPort;
    Prompt prompt;
    Dictionary<uint, SerialForwarder> SFTable = new Dictionary<uint, SerialForwarder>();
    //HashSet<Listener> activeListeneres = new HashSet<Listener>();
    ArrayList activeListeners = new ArrayList();
    uint sfId = 0;
    Boolean exit = false;
    string helloMsg = "Starting SF#. Type 'help' for a list of available commands";

    uint dest {
      get;
      set;
    }

    uint src {
      get;
      set;
    }

    uint group {
      set;
      get;
    }

    uint amtype {
      set;
      get;
    }

    public SFMain() {
      Init();
    }

    public SFMain(int controlPort) {
      this.controlPort = controlPort;
      Init();
      tcpListener = new TcpListener(IPAddress.Any, controlPort);
      tcpClient = new Thread(new ThreadStart(TcpClient));
      tcpClient.Start();
      stdinClient.Join();
      tcpListener.Stop();
      tcpClient.Abort();
      tcpListener.Stop();
    }

    public void Init() {
      prompt = new Prompt("", ">> ", helloMsg, 25);
      SetDefVarValues();
      stdinClient = new Thread(new ThreadStart(StdinClient));
      stdinClient.Start();
    }

    public void SetDefVarValues() {
      this.dest = 0;
      this.src = 0;
      this.group = 0;
      this.amtype = 0;
    }

    private void TcpClient() {
      TcpClient tcpClient;
      byte[] buffer = new byte[250];
      int bytesRead;
      string cmdStr;

      tcpListener.Start();
      prompt.WriteLine("Waiting for control clients on port " + controlPort + ". ");
      while (true) {
        try { tcpClient = tcpListener.AcceptTcpClient(); } catch (Exception) { return; }
        prompt.WriteLine("Control client connected", prompt.eventTextColor);
        controlClient = tcpClient.GetStream();
        prompt.EnableTCPClientEcho(controlClient);
        var encoder = new UTF8Encoding();
        byte[] hello = encoder.GetBytes(helloMsg + '\n');
        controlClient.Write(hello, 0, hello.Length);

        while (true) {
          try {
            bytesRead = controlClient.Read(buffer, 0, 250);
            cmdStr = this.Parse(buffer, 0, bytesRead);
            prompt.ControlClientCmd(cmdStr);
            string cmd = cmdStr.ToLower();
            if (cmd.Equals("exit") && activeListeners.Count == 0) 
              continue;

            ExecCommand(cmd);
          } catch (Exception e) {
            Debug.WriteLine(e.Message);
            CloseControlClient();
            break;
          } 
        }
      }
    }

    private string Parse(byte[] bytes, int index, int count) {
      string str = System.Text.Encoding.UTF8.GetString(bytes, index, count);
      return str.Remove(str.Length - 1);
    }

    private void StdinClient() {

      string cmdStr;
      prompt.writeWelcome();

      while (!exit) {
        cmdStr = prompt.UserInput();
        prompt.LocalClientCmd(cmdStr);
        ExecCommand(cmdStr.ToLower());
      }
    }

    public void ExecCommand(string cmd) {
      ArrayList args = prompt.ParseCommand(cmd);
      if (args.Count == 0)
        return;
      
      string cname = args[0].ToString();

      switch (cname) {
        case "start": LaunchSF(args);
          break;

        case "stop":
          if (args.Count > 1)
            StopSF(args[1].ToString());
          break;

        case "help": PrintHelp(args);
          break;

        case "list": List();
          break;

        case "info": 
          if (args.Count>1)
            Info(args[1].ToString());
          break;

        case "close": CloseControlClient();
          break;

        case "exit": ExitApp();
          break;

        case "ports": PrintPorts();
          break;
        case "clear": prompt.Clear();
          break;
        case "set": setVar(args);
          break;
        case "send":
          Sender s = new Sender(args, prompt);
          // -listen option returns the listener
          Listener l = (Listener)s.SendOne(dest, src, group, amtype);
          if (l != null && l.active) {
            activeListeners.Add(l);
          }
          break;
        case "listen":// listen -comm MOTECOM
          Listener listener = new Listener(args, prompt);
          if (listener.active)
            activeListeners.Add(listener);
          break;

        default:
          prompt.WriteLine("Unknown command '" + cname + "'");
          prompt.WriteLine("Type 'help' for a list of available commands");
          break;
      }
    }

    private void CloseControlClient() {
      if (controlClient != null) {
        controlClient.Close();
        prompt.DisableTCPClientEcho(controlClient);
      }
    }

    private void PrintPorts() {
      string[] ports = SerialPort.GetPortNames();
      foreach (string s in ports)
        prompt.WriteLine(s);
    }

    private void LaunchSF(ArrayList args) {
      SerialForwarder sf = new SerialForwarder(args, prompt, sfId);
      if (sf.running) {
        SFTable.Add(sf.id, sf);
        sf.moteConnLost += sf_moteConnLost;
        sfId++;
      }
    }

    void sf_moteConnLost(object sender, EventArgs e) {
      SerialForwarder sf = (SerialForwarder)sender;
      StopSF(sf.port.ToString());
    }

    private void StopSF(string id) {
      uint _id;
      try {
        _id = Convert.ToUInt32(id);
      } catch (Exception e) {
        Debug.WriteLine(e.Message);
        prompt.WriteLine("stop: wrong arguments");
        return;
      }
      SerialForwarder sf = findSF(_id);
      if (sf == null) {
        prompt.WriteLine("SF not found");
        return;
      }
      sf.CloseAll();
      SFTable.Remove(sf.id);
    }

    private void List() {
      if (SFTable.Count == 0) {
        prompt.WriteLine("No running sf servers.");
      }
      IDictionaryEnumerator enu = SFTable.GetEnumerator();
      
      while (enu.MoveNext()) {
        SerialForwarder sf = (SerialForwarder)enu.Value;
        sf.PrintIdMessage();
      }
    }

    /// <summary>
    /// Each time an user enters 'exit', one listener is closed
    /// until the stack is empty, then app is closed.
    /// </summary>
    private void ExitApp() {
      int lcount = activeListeners.Count;
      if (lcount > 0) {
        Listener l = (Listener)activeListeners[lcount - 1];
        activeListeners.RemoveAt(lcount - 1);
        l.stop();
        return;
      }
      CloseControlClient();
      CloseAll();

      exit = true;
    }

    private void CloseAll() {
      IDictionaryEnumerator enu = SFTable.GetEnumerator();
      while (enu.MoveNext()) {
        SerialForwarder sf = (SerialForwarder)enu.Value;
        sf.CloseAll();
      }
    }

    private SerialForwarder findSFByPort(int port) {
      IDictionaryEnumerator enu = SFTable.GetEnumerator();
      while (enu.MoveNext()) {
        SerialForwarder sf = (SerialForwarder)enu.Value;
        if (sf.port == port) return sf;
      }
      return null;
    }

    private SerialForwarder findSF(uint id) {

      SerialForwarder sf;
      if (!SFTable.TryGetValue(id, out sf)) {
        sf = findSFByPort((int)id);
      }
      return sf;
    }

    private void Info(string id) {
      uint _id;
      try {
        _id = Convert.ToUInt32(id);
      } catch (Exception e) {
        Debug.WriteLine(e.Message);
        prompt.WriteLine("info: wrong arguments");
        return;
      }

      SerialForwarder sf = findSF(_id);
      if (sf == null) {
        prompt.WriteLine("SF not found");
        return;
      }
      sf.Info();
    }


    public void PrintHelp(ArrayList args) {
      if (args.Count < 2) {
        PrintMainHelp();
        return;
      }

      string cname = args[1].ToString();

      switch (cname) {
        case "start":SerialForwarder.PrintStartHelp(prompt);
          break;

        case "stop":SerialForwarder.PrintStopHelp(prompt);
          break;

        case "help": PrintHelp(args);
          break;

        case "list": SerialForwarder.PrintListHelp(prompt);
          break;

        case "info": SerialForwarder.PrintInfoHelp(prompt);
          break;

        case "close": PrintHelpClose(prompt);
          break;

        case "exit": PrintHelpExit(prompt);
          break;

        case "ports": PrintHelpPorts(prompt);
          break;

        case "set": PrintSetHelp(prompt);
          break;

        case "listen": Listener.PrintHelp(prompt);
          break;

        case "clear": PrintHelpClear(prompt);
          break;

        case "send": Sender.PrintHelp(prompt);
          break;

        default:
          PrintMainHelp();
          break;
      }
    }

    private void PrintSetHelp(Prompt prompt) {
      prompt.WriteLine("USAGE");
      prompt.WriteLine("  set [<DEST | SRC | GROUP | AM> [0x]<VALUE>] ", prompt.helpTextColor);
      prompt.WriteLine("");
      prompt.WriteLine("DESCRIPTION");
      prompt.WriteLine("  Sets serial packet header fields values for packets sent");
      prompt.WriteLine("  with the SEND command. Invoke without arguments");
      prompt.WriteLine("  to print the current assigned values. See also 'help send'.");
      prompt.WriteLine("");
      prompt.WriteLine("EXAMPLE");
      prompt.WriteLine("  set am 137");
      prompt.WriteLine("  set am 0x89");
    }

    private void PrintHelpClear(Prompt prompt) {
      prompt.WriteLine("Clears the local console.");
    }

    private void PrintHelpPorts(Prompt prompt) {
      prompt.WriteLine("Displays a list of available serial ports.");
    }

    private void PrintHelpExit(Prompt prompt) {
      prompt.WriteLine("Stops all running sf-servers and exit.");
    }

    private void PrintHelpClose(Prompt prompt) {
      prompt.WriteLine("Closes the connection to the control client.");
    }

    private void setVar(ArrayList args) {
      // set var value
      if (args.Count != 3) {
        printVars("X");
        printVars("");
        return;
      }

      int fromBase;
      if (args[2].ToString().StartsWith("0x"))
        fromBase = 16;
      else fromBase = 10;

      try {
        switch (args[1].ToString()) {
          case "dest": dest = Convert.ToUInt16(args[2].ToString(), fromBase);
            break;
          case "src": src = Convert.ToUInt16(args[2].ToString(), fromBase);
            break;
          case "group": group = Convert.ToUInt16(args[2].ToString(), fromBase);
            break;
          case "am": amtype = Convert.ToUInt16(args[2].ToString(), fromBase);
            break;
          default: prompt.WriteLine("Unknown variable");
            return;
        }
      } catch (Exception e) {
        prompt.WriteLine(e.Message, prompt.errorTextColor);
        return;
      }
      prompt.WriteLine("ok", prompt.successTextColor);
    }

    private void printVars(string f) {
      ConsoleColor valueColor = prompt.helpTextColor;
      if (f.Equals("X")) {
        prompt.Write("HEX: { ", true);
      }
      else {
        f = "";
        prompt.Write("DEC: { ", true);
      }

      prompt.Write("dest = ", false);
      prompt.Write(this.dest.ToString(f), valueColor, false);
      prompt.Write(", ", false);

      prompt.Write("src = ", false);
      prompt.Write(this.src.ToString(f), valueColor, false);
      prompt.Write(", ", false);

      prompt.Write("am = ", false);
      prompt.Write(this.amtype.ToString(f), valueColor, false);
      prompt.Write(", ", false);

      prompt.Write("group = ", false);
      prompt.Write(this.group.ToString(f), valueColor, false);
      prompt.Write(" } \n", false);
    }

    public void PrintMainHelp() {
      prompt.Write("start   ", prompt.helpTextColor, true);
      prompt.Write(": starts a new sf-server\n", false);
      prompt.Write("stop    ", prompt.helpTextColor, true);
      prompt.Write(": stops the specified sf-server\n", false);
      prompt.Write("list    ", prompt.helpTextColor, true);
      prompt.Write(": lists all running sf-servers\n", false);
      prompt.Write("info    ", prompt.helpTextColor, true);
      prompt.Write(": prints out stats about the specified sf-server\n", false);
      prompt.Write("close   ", prompt.helpTextColor, true);
      prompt.Write(": closes the connection to the control client\n", false);
      prompt.Write("ports   ", prompt.helpTextColor,true);
      prompt.Write(": displays a list of available serial ports\n",false);
      prompt.Write("exit    ", prompt.helpTextColor, true);
      prompt.Write(": stops all sf-servers and exit\n", false);
      prompt.Write("clear   ", prompt.helpTextColor, true);
      prompt.Write(": clears local console\n", false);
      prompt.Write("send    ", prompt.helpTextColor, true);
      prompt.Write(": sends a packet\n", false);
      prompt.Write("set     ", prompt.helpTextColor, true);
      prompt.Write(": sets TOS serial packet header fields (for send command)\n", false);
      prompt.Write("listen  ", prompt.helpTextColor, true);
      prompt.Write(": listens for packets\n", false);
      prompt.WriteLine("");
      prompt.Write("Type 'help <command>' for more info\n", true);
    }
  }
}
