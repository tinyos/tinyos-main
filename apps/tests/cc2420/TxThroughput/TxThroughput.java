
/*
 * Copyright (c) 2005-2006 Rincon Research Corporation
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
 * - Neither the name of the Rincon Research Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * ARCHED ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */
 
/**
 * Java-side application for examining the radio Tx throughput
 * 
 * @author David Moss
 */

import java.io.IOException;

import net.tinyos.message.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;

public class TxThroughput implements MessageListener {

  private MoteIF moteIF;

  public TxThroughput(MoteIF moteIF) {
    this.moteIF = moteIF;
    this.moteIF.registerListener(new ThroughputMsg(), this);
  }

  public void messageReceived(int dest, Message message) {
    System.out.println("[Packets/s]: " + ((ThroughputMsg) message).get_packetsPerSecond() 
        + ";  [(Payload Bytes)/s]: " + ((((ThroughputMsg) message).numElements_fillBytes() + 2) * ((ThroughputMsg) message).get_packetsPerSecond()));
  }

  private static void usage() {
    System.err.println("usage: TxThroughput [-comm <source>]");
  }

  public static void main(String[] args) throws Exception {
    String source = null;
    if (args.length == 2) {
      if (!args[0].equals("-comm")) {
        usage();
        System.exit(1);
      }
      source = args[1];
    } else if (args.length != 0) {
      usage();
      System.exit(1);
    }

    PhoenixSource phoenix;

    if (source == null) {
      phoenix = BuildSource.makePhoenix(PrintStreamMessenger.err);
    } else {
      phoenix = BuildSource.makePhoenix(source, PrintStreamMessenger.err);
    }

    MoteIF mif = new MoteIF(phoenix);
    new TxThroughput(mif);
  }

}