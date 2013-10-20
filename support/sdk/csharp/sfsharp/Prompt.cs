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
using System.Net;
using System.Net.Sockets;
using System.Threading;
using System.Collections;

namespace sfsharp
{

  class Prompt
  {
    private int CMD_MEMORY_SIZE;
    public string prompt;
    public string prefix;
    ArrayList cmdMem;
    int nextCmd = 0;
    ConsoleKeyInfo cki;
    public String welcome;
    StringBuilder sb = new StringBuilder();
    NetworkStream clientStream;
    EventWaitHandle userTyping = new EventWaitHandle(true, EventResetMode.ManualReset);
    int scursor;
    int cmdTop;

    public ConsoleColor helpTextColor = ConsoleColor.DarkYellow;
    public ConsoleColor errorTextColor = ConsoleColor.Red;
    public ConsoleColor successTextColor = ConsoleColor.DarkGreen;
    public ConsoleColor eventTextColor = ConsoleColor.DarkCyan;
    public ConsoleColor controlClientCommandColor = ConsoleColor.DarkGray;
    public ConsoleColor prefixColor = ConsoleColor.DarkGreen;

    public Prompt(string promptSymbol, string prefixSymbol, string welcome, int histSize) {
      Console.CursorSize = 3;
      prompt = promptSymbol;
      prefix = prefixSymbol;
      this.welcome = welcome;
      CMD_MEMORY_SIZE = histSize;
      cmdMem = new ArrayList(CMD_MEMORY_SIZE);
    }

    public void writeWelcome() {
      WritePrefix();
      Console.WriteLine(welcome);
    }

    public void EnableTCPClientEcho(NetworkStream clientStream) {
      this.clientStream = clientStream;
    }

    public void DisableTCPClientEcho(NetworkStream clientStream) {
      this.clientStream = null;
    }

    public void WriteLineToTCP(string txt) {
      if (clientStream == null) return;
      UTF8Encoding encoder = new UTF8Encoding();
      byte[] text = encoder.GetBytes(txt + '\n');
      clientStream.Write(text, 0, text.Length);
    }

    public void WriteToTCP(string txt) {
      if (clientStream == null) return;
      UTF8Encoding encoder = new UTF8Encoding();
      byte[] text = encoder.GetBytes(txt);
      clientStream.Write(text, 0, text.Length);
    }

    public void ControlClientCmd(string cmd) {
      Console.ForegroundColor = controlClientCommandColor;
      Console.WriteLine(prefix + "Control-client: " + cmd);
      Console.ResetColor();
    }

    public void LocalClientCmd(string cmd) {
      if (this.clientStream == null) return;
      this.WriteLineToTCP(prefix + "Local-client: " + cmd);
    }

    public string UserInput() {
      string command;
      //sb.Clear(); not 3.5 compatible
      sb.Length = 0;
      scursor = prompt.Length;
      cmdTop = Console.CursorTop;
      Console.Write(prompt);
      sb.Append(prompt);
      Console.TreatControlCAsInput = true;

      do {
        if (sb.Length > 0)
          userTyping.Reset();
        else userTyping.Set();
        cki = Console.ReadKey(true);
        cmdTop = Console.CursorTop;
        if ((cki.Modifiers & ConsoleModifiers.Control) != 0 &&
            (cki.Modifiers & ConsoleModifiers.Alt) != 0) {
          AcceptCharacter();
          continue;
        }
        else if ((cki.Modifiers & ConsoleModifiers.Alt) != 0)
          AcceptCharacter();
        else if ((cki.Modifiers & ConsoleModifiers.Shift) != 0)
          AcceptCharacter();

        // ConsoleModifiers.Control not accepted
        else if ((cki.Modifiers & ConsoleModifiers.Control) != 0) {
          return "exit";
        }

        else AcceptCharacter();

      } while (cki.Key != ConsoleKey.Enter);
      //userTyping.Set();
      Console.SetCursorPosition(0, Console.CursorTop + 1);
      command = sb.ToString().Substring(prompt.Length);
      userTyping.Set();
      if (command.Length > 0)
        cmdMem.Add(command);
      nextCmd = cmdMem.Count;
      return command;
    }

    public void WriteLine(string text, ConsoleColor c) {
      userTyping.WaitOne();
      WritePrefix();
      Console.ForegroundColor = c;
      Console.WriteLine(text);
      this.WriteLineToTCP(text);
      Console.ResetColor();
    }

    public void WriteLine(string text) {
      userTyping.WaitOne();
      WritePrefix();
      Console.WriteLine(text);
      this.WriteLineToTCP(text);
    }

    public void Write(string text, ConsoleColor c, Boolean withPrefix) {
      userTyping.WaitOne();
      if (withPrefix)
        WritePrefix();

      Console.ForegroundColor = c;
      Console.Write(text);
      this.WriteToTCP(text);
      Console.ResetColor();
    }

    public void Write(string text, Boolean withPrefix) {
      userTyping.WaitOne();
      if (withPrefix)
        WritePrefix();
      Console.Write(text);
      this.WriteToTCP(text);
    }

    public void WritePrefix() {
      Console.ForegroundColor = prefixColor;
      Console.Write(prefix);
      this.WriteToTCP(prefix);
      Console.ResetColor();
    }

    public ArrayList ParseCommand(string cmd) {
      string[] _tokens = cmd.Split(' ');
      ArrayList tokens = new ArrayList();
      for (int i = 0, l = _tokens.Length; i < l; i++) {
        if (_tokens[i].Length > 0) {
          tokens.Add(_tokens[i]);
        }
      }
      return tokens;
    }

    private void AcceptCharacter() {
      if (cki.Key == ConsoleKey.Enter)
        return;
      char key = cki.KeyChar;
      if (cki.Key == ConsoleKey.Backspace) {
        RemoveOne();
        return;
      }
      if (cki.Key == ConsoleKey.UpArrow) {
        if (cmdMem.Count > 0 && nextCmd > -1) {
          if (--nextCmd > -1)
            SetCommand((string)cmdMem[nextCmd]);
        }
        return;
      }
      if (cki.Key == ConsoleKey.DownArrow) {
        int cmdMemCount = cmdMem.Count;
        if (cmdMemCount > 0 && nextCmd < cmdMemCount) {
          if (nextCmd == -1) nextCmd = 0;
          if (++nextCmd < cmdMem.Count)
            SetCommand((string)cmdMem[nextCmd]);
          else
            SetCommand("");
        }
        return;
      }

      if ((cki.Key == ConsoleKey.RightArrow)) {
        cursorRight();
        return;
      }

      if ((cki.Key == ConsoleKey.LeftArrow)) {
        cursorLeft();
        return;
      }

      if (!AllowedChar()) return;
      else {
        PutOne(key);
      }
    }

    private Boolean AllowedChar() {
      return true;
    }

    private void SetCommand(string str) {
      ClearCommand();
      for (int i = 0, l = str.Length; i < l; i++)
        PutOne(str[i]);
    }

    private void ClearCommand() {
      scursor = sb.Length;
      while (sb.Length > prompt.Length)
        RemoveOne();
    }

    private void PutOne(char key) {
      sb.Insert(scursor, key);
      Console.Write(sb.ToString().Substring(scursor));
      cursorRight();
    }

    private void RemoveOne() {
      if (scursor <= prompt.Length)
        return;
      string str = " ";
      if (scursor < sb.Length)
        str = sb.ToString().Substring(scursor) + str;
      cursorLeft();
      sb.Remove(scursor, 1);
      Console.Write(str);
      SetCursor();
    }

    private void cursorLeft() {
      if (scursor > prompt.Length) {
        scursor--;
        SetCursor();
      }
    }

    private void cursorRight() {
      if (scursor < sb.Length) {
        scursor++;
        SetCursor();
      }
    }

    private void SetCursor() {
      int top = scursor / Console.BufferWidth;
      int left = scursor % Console.BufferWidth;
      Console.SetCursorPosition(left, cmdTop + top);
    }

    public void Clear() {
      Console.Clear();
    }
  }
}
