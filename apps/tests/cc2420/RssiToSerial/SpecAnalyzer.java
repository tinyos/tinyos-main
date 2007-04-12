
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
 * RINCON RESEARCH OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

/**
 * 
 * @author Jared Hill
 */

import net.tinyos.message.Message;
import net.tinyos.message.MessageListener;
import net.tinyos.message.MoteIF;
import net.tinyos.message.SerialPacket;
import net.tinyos.packet.BuildSource;
import net.tinyos.packet.PhoenixSource;
import net.tinyos.util.PrintStreamMessenger;

public class SpecAnalyzer implements MessageListener {

  /** Communication with the mote */
  private MoteIF mote;

  /** Broadcast Address */
  public static final short TOS_BCAST_ADDR = (short) 0xffff;

  /** The message from the mote */
  private RssiSerialMsg rssiMsg;

  /** The total number of characters written last time */
  private int lastCharsWritten = 0;
  
  /** The maximum size of the bar on the command line, in characters */
  private static final int MAX_CHARACTERS = 50;
  
  /**
   * Constructor
   * 
   * @param argv
   */
  public SpecAnalyzer(MoteIF mif) {

    try {
      System.out.println("Connecting to serial forwarder...");
      mote = mif;
      mote.registerListener(new RssiSerialMsg(), this);
    } catch (Exception e) {
      System.err.println("Couldn't contact serial forwarder");
    }

  }

  /**
   * Received a message from the mote
   */
  synchronized public void messageReceived(int dest,
      Message m) {
    rssiMsg = (RssiSerialMsg) m;
    updateSpectrum(rssiMsg.get_rssiLargestValue(), rssiMsg.get_rssiAvgValue());

  }

  /**
   * Overwrites the current command line prompt with blank space
   * 
   */
  void clearSpectrum() {
    for(int i = 0; i < lastCharsWritten; i++) {
      System.out.print('\b');
    }
  }

  /**
   * Prints the magnitude of the spectrum to stdout. Specifically, it prints
   * (largest - average) "+" signs to stdout.
   * 
   * @param largest
   *          the largest rssi value taken during the sample period
   * @param avg
   *          the average rssi value taken during the sample period
   */
  void updateSpectrum(int largest, int avg) {
    clearSpectrum();
    String bar = "[";
    int size = (int) ((float) largest * (float) ((float) MAX_CHARACTERS / (float) (255)));
    
    for(int i = 0; i < size && i < MAX_CHARACTERS; i++) {
      bar += "+";
    }
    
    for(int i = 0; i < (MAX_CHARACTERS - size); i++) {
      bar += " ";
    }
    
    bar += "]";
    
    lastCharsWritten = bar.length();
    System.out.print(bar);
  }
  
  private static void usage() {
    System.err.println("usage: SpecAnalyzer [-comm <source>]");
  }

  /**
   * Main Method
   * 
   * @param argv
   */
  public static void main(String[] args) {
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
    new SpecAnalyzer(mif);
  }
}
