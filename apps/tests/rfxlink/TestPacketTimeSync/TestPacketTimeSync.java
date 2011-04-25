/*
 * Copyright (c) 2002-2011, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * Author: Janos Sallai
 */
 
import java.util.*;
import net.tinyos.message.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;

public class TestPacketTimeSync implements net.tinyos.message.MessageListener {

  private MoteIF moteIF;
  private Map pingMap = new HashMap();

  public TestPacketTimeSync(String source) throws Exception {
    if (source != null) {
      moteIF = new MoteIF(BuildSource.makePhoenix(source, PrintStreamMessenger.err));
    }
    else {
      moteIF = new MoteIF(BuildSource.makePhoenix(PrintStreamMessenger.err));
    }
  }

  public void start() {
  }

  public void messageReceived(int to, Message message) {
    long t = System.currentTimeMillis();

    System.err.println("INFO: received message type = "+message.amType()+ " length=" + message.dataLength());

    if(message instanceof PongMsg) {
      PongMsg pongMsg = (PongMsg)message;
      if(pongMsg.get_ping_counter()==0) return;

      String key= "_"+pongMsg.get_pinger()+"_"+pongMsg.get_ping_counter();
      Ping ping = (Ping)pingMap.get(key);
      if (ping!=null) {
        ping.addPong(new Pong(pongMsg));
      } else {
        System.err.println("ERROR: cannot find ping msg with counter value "+pongMsg.get_ping_counter());
      }

    }

    if(message instanceof PingMsg) {
      PingMsg pingMsg = (PingMsg)message;
      if(pingMsg.get_ping_counter()==0) return;

      String key= "_"+pingMsg.get_pinger()+"_"+pingMsg.get_ping_counter();
      Ping ping = (Ping)pingMap.get(key);
      if (ping==null) {
        ping = new Ping(pingMsg);
        pingMap.put(key,ping);
        String prevKey= "_"+pingMsg.get_pinger()+"_"+pingMsg.get_prev_ping_counter();
        Ping prevPing = (Ping)pingMap.get(prevKey);
        if(prevPing==null) {
          System.err.println("ERROR: cannot find previous ping msg with counter value "+pingMsg.get_prev_ping_counter());
        } else {
            prevPing.set_ping_tx_timestamp_is_valid(pingMsg.get_prev_ping_tx_timestamp_is_valid());
            prevPing.set_ping_tx_timestamp(pingMsg.get_prev_ping_tx_timestamp());
            prevPing.print(System.out);
            pingMap.remove(prevPing);
        }

      } else {
        System.err.println("ERROR: received duplicate ping msg "+pingMsg.get_ping_counter());
      }

    }
  }

  private static void usage() {
    System.err.println("usage: TestPacketTimeSync [-comm <source>]");
  }

  private void addMsgType(Message msg) {
    moteIF.registerListener(msg, this);
  }

  public static void main(String[] args) throws Exception {
    String source = null;
    if (args.length > 0) {
      for (int i = 0; i < args.length; i++) {
        if (args[i].equals("-comm")) {
	      source = args[++i];
	      }
	    }
	  } else if (args.length != 0) {
      usage();
      System.exit(1);
    }

    TestPacketTimeSync me = new TestPacketTimeSync(source);
    me.moteIF.registerListener(new PingMsg(),me);
    me.moteIF.registerListener(new PongMsg(),me);
    me.start();
  }

}
