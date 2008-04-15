/*
 * "Copyright (c) 2005 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
 * DOCUMENTATION, EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */

/*
 * This is a modified version of TestSerial.java, from apps/tests/TestSerial
 * from TinyOS 2.x (www.tinyos.net)
 */

/**
 * Java-side application for testing the RSSI demo
 *
 * @author Phil Levis <pal@cs.berkeley.edu>
 * @author Dimas Abreu Dutra <dimas@dcc.ufmb.br>
 * @date April 11 2008
 */

import java.io.IOException;

import net.tinyos.message.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;

public class RssiDemo implements MessageListener {

  private MoteIF moteIF;
  
  public RssiDemo(MoteIF moteIF) {
    this.moteIF = moteIF;
    this.moteIF.registerListener(new RssiMsg(), this);
  }
    
  public void messageReceived(int to, Message message) {
    RssiMsg msg = (RssiMsg) message;
    int source = message.getSerialPacket().get_header_src();
    System.out.println("Rssi Message received from node " + source + 
		       ": Rssi = " +  msg.get_rssi());
  }
  
  private static void usage() {
    System.err.println("usage: RssiDemo [-comm <source>]");
  }
  
  public static void main(String[] args) throws Exception {
    String source = null;
    if (args.length == 2) {
      if (!args[0].equals("-comm")) {
	usage();
	System.exit(1);
      }
      source = args[1];
    }
    else if (args.length != 0) {
      usage();
      System.exit(1);
    }
    
    PhoenixSource phoenix;
    
    if (source == null) {
      phoenix = BuildSource.makePhoenix(PrintStreamMessenger.err);
    }
    else {
      phoenix = BuildSource.makePhoenix(source, PrintStreamMessenger.err);
    }

    MoteIF mif = new MoteIF(phoenix);
    RssiDemo serial = new RssiDemo(mif);
  }


}
