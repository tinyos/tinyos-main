// $Id: SerialForwarder.java,v 1.6 2010-06-29 22:07:41 scipio Exp $

/*									tab:4
 * Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the University of California nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
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
