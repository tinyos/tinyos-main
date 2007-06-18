// $Id: SerialForwarder.java,v 1.5 2007-06-18 20:36:36 rincon Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * File: SerialForwarder.java
 *
 * Description:
 * The SerialForwarder class provides many static functions
 * that handle the initialization of the serialforwarder
 * and/or the associated gui.
 *
 * @author <a href="mailto:bwhull@sourceforge.net">Bret Hull</a>
 * @author <a href="mailto:dgay@intel-research.net">David Gay</a>
 */
package net.tinyos.sf;

import java.io.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;

public class SerialForwarder implements Messenger {
  public static final int DEFAULT_PORT = 9002;

  // appication defaults
  public SFRenderer renderer;

  public SFListen listenServer;

  public String motecom = "serial@com1:57600";

  public boolean logDB;

  public int serverPort = DEFAULT_PORT;

  private boolean displayHelp = false;

  private int nClients = 0;

  private int nPacketsRead = 0;

  private int nPacketsWritten = 0;

  private SFListen listener = null;

  SFMessenger verbose = new SFMessenger(true);

  SFMessenger debug = new SFMessenger(false);

  class SFMessenger implements Messenger {
    boolean on;

    SFMessenger(boolean on) {
      this.on = on;
    }

    public void message(String message) {
      if (on) {
        SerialForwarder.this.message(message);
      }
    }
  }

  public static void main(String[] args) throws IOException {
    new SerialForwarder(args);
  }

  public SerialForwarder(String[] args) throws IOException {
    ProcessCommandLineArgs(args);

    if (displayHelp) {
      printHelp();
      System.exit(2);
    }
    
    if(renderer == null) {
      // Default is GUI
      renderer = SFWindow.createGui(this, "TinyOS 2.x Serial Forwarder");
    }
    
    startListenServer();
  }

  private void ProcessCommandLineArgs(String[] args) {
    for (int i = 0; i < args.length; i++) {
      debug.message(args[i]);
    }
    for (int i = 0; i < args.length; i++) {
      if (args[i].equals("-no-gui") && renderer == null) {
        renderer = new SFConsoleRenderer();
        
      } else if(args[i].equals("-no-output") && renderer == null) {
        renderer = new SFNullRenderer();
        
      } else if (args[i].equals("-comm")) {
        i++;
        if (i < args.length) {
          motecom = args[i];
        } else {
          displayHelp = true;
        }
        
      } else if (args[i].equals("-port")) {
        i++;
        if (i < args.length) {
          serverPort = Integer.parseInt(args[i]);
        } else {
          displayHelp = true;
        }
      } else if (args[i].equals("-log")) {
        logDB = true;
      } else if (args[i].equals("-quiet")) {
        verbose.on = false;
      } else if (args[i].equals("-debug")) {
        debug.on = true;
      } else {
        displayHelp = true;
      }
    }
  }

  private static void printHelp() {
    System.err.println("optional arguments:");
    System.err.println("-port [server port] (default " + DEFAULT_PORT + ")");
    System.err.println("-comm [motecom spec] (default serial@com1:57600)");
    System.err.println("-packetsize [size] (default 36)");
    System.err.println("-no-gui      = do not display graphic interface");
    System.err.println("-no-output");
    System.err.println("-quiet       = non-verbose mode");
    System.err.println("-debug       = display debug messages");
    System.err.println("-log         = log to database");
  }

  private void createGui() {
    renderer = SFWindow.createGui(this, "SerialForwarder");
  }

  public void message(String msg) {
    renderer.message(msg);
  }

  synchronized public void incrementPacketsRead() {
    nPacketsRead++;
    renderer.updatePacketsRead(nPacketsRead);
  }

  synchronized public void incrementPacketsWritten() {
    nPacketsWritten++;
    renderer.updatePacketsWritten(nPacketsWritten);
  }

  synchronized public void incrementClients() {
    nClients++;
    renderer.updateNumClients(nClients);
  }

  synchronized public void decrementClients() {
    nClients--;
    renderer.updateNumClients(nClients);
  }

  public synchronized void clearCounts() {
    nPacketsRead = nPacketsWritten = 0;
    renderer.updatePacketsWritten(nPacketsWritten);
    renderer.updatePacketsRead(nPacketsRead);
  }

  public synchronized void startListenServer() {
    if (listenServer == null) {
      nClients = 0;
      listenServer = new SFListen(this);
      listenServer.start();
    }
    renderer.updateListenServerStatus(true);
    renderer.updateNumClients(nClients);
    clearCounts();
  }

  public void stopListenServer() {
    SFListen lserver;

    // We can't just make stopSFListen synchronized because
    // listenServerStopped must be synchronized too
    synchronized (this) {
      lserver = listenServer;
      if (lserver != null)
        listenServer.shutdown();
    }
    if (lserver != null) {
      try {
        lserver.join(2000);
      } catch (InterruptedException ex) {
      }
    }
  }

  public synchronized void listenServerStopped() {
    listenServer = null;
    renderer.updateListenServerStatus(false);
  }
}
