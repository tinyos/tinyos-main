/*
 * Copyright (c) 2007 Stanford University.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Stanford University nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL STANFORD
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * @author Kevin Klues <klueska@cs.stanford.edu>
 * @date July 24, 2007
 */

import net.tinyos.message.*;
import net.tinyos.util.*;
import java.io.*;
/**
*/

public class LowPowerSensingApp implements MessageListener
{
  MoteIF mote;

  /* Main entry point */
  void run() {
    mote = new MoteIF(PrintStreamMessenger.err);
    mote.registerListener(new SerialSampleMsg(), this);
  }

  synchronized public void messageReceived(int dest_addr, Message msg) {
    if (msg instanceof SerialSampleMsg) {
      System.out.print(msg.toString());
    }
  }

  synchronized public void requestSamples(int addr) {
    SerialRequestSamplesMsg msg = new SerialRequestSamplesMsg();
    msg.set_addr(addr);
    try {
      mote.send(MoteIF.TOS_BCAST_ADDR, msg);
    }
    catch (IOException e) {
      System.err.println("Cannot send message to mote");
    }
  }

  public static void main(String[] args) {
    LowPowerSensingApp me = new LowPowerSensingApp();
    me.run();

    InputStreamReader cin = new InputStreamReader(System.in);
    BufferedReader in = new BufferedReader(cin);
    String input = "";

    System.out.print("Enter 's' to request samples\n");
    System.out.print(">> ");
    for(;;) {
      try {
        input = in.readLine();
        if(input.equals("s")) {
          System.out.print("Enter Address: ");
          input = in.readLine();
          me.requestSamples(Integer.parseInt(input));
        }
        else System.out.println("Invalid Input!!!!: ");
        System.out.print(">> ");
      }
      catch (IOException e) {
        System.out.print("Error On Input!!");
      }
    }
  }
}
