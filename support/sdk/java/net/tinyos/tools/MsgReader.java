/*									tab:4
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
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
 * Copyright (c) 2002-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/* Authors:	Phil Levis <pal@cs.berkeley.edu>
 * Date:        December 1 2005
 * Desc:        Generic Message reader
 *               
 */

/**
 * @author Phil Levis <pal@cs.berkeley.edu>
 */


package net.tinyos.tools;

import java.util.*;

import net.tinyos.message.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;

public class MsgReader implements net.tinyos.message.MessageListener {

  private MoteIF moteIF;
  
  public MsgReader(String source) throws Exception {
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
    //    Date d = new Date(t);
    System.out.print("" + t + ": ");
    System.out.println(message);
  }

  
  private static void usage() {
    System.err.println("usage: MsgReader [-comm <source>] message-class [message-class ...]");
  }

  private void addMsgType(Message msg) {
    moteIF.registerListener(msg, this);
  }
  
  public static void main(String[] args) throws Exception {
    String source = null;
    Vector v = new Vector();
    if (args.length > 0) {
      for (int i = 0; i < args.length; i++) {
	if (args[i].equals("-comm")) {
	  source = args[++i];
	}
	else {
	  String className = args[i];
	  try {
	    Class c = Class.forName(className);
	    Object packet = c.newInstance();
	    Message msg = (Message)packet;
	    if (msg.amType() < 0) {
		System.err.println(className + " does not have an AM type - ignored");
	    }
	    else {
		v.addElement(msg);
	    }
	  }
	  catch (Exception e) {
	    System.err.println(e);
	  }
	}
      }
    }
    else if (args.length != 0) {
      usage();
      System.exit(1);
    }

    MsgReader mr = new MsgReader(source);
    Enumeration msgs = v.elements();
    while (msgs.hasMoreElements()) {
      Message m = (Message)msgs.nextElement();
      mr.addMsgType(m);
    }
    mr.start();
  }


}
