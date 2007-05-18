// $Id: Packetizer.java,v 1.5 2007-05-18 18:27:04 rincon Exp $

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
package net.tinyos.packet;

import net.tinyos.util.*;
import java.io.*;
import java.util.*;
import java.nio.*;

/**
 * The Packetizer class implements the new mote-PC protocol, using a ByteSource
 * for low-level I/O
 */
public class Packetizer extends AbstractSource implements Runnable {
  /*
   * Protocol inspired by, but not identical to, RFC 1663. There is currently no
   * protocol establishment phase, and a single byte ("packet type") to identify
   * the kind/target/etc of each packet.
   * 
   * The protocol is really, really not aiming for high performance.
   * 
   * There is however a hook for future extensions: implementations are required
   * to answer all unknown packet types with a P_UNKNOWN packet.
   * 
   * To summarise the protocol: - the two sides (A & B) are connected by a
   * (potentially unreliable) byte stream - the two sides exchange packets
   * framed by 0x7e (SYNC_BYTE) bytes - each packet has the form <packet type>
   * <data bytes 1..n> <16-bit crc> where the crc (see net.tinyos.util.Crc)
   * covers the packet type and bytes 1..n - bytes can be escaped by preceding
   * them with 0x7d and their value xored with 0x20; 0x7d and 0x7e bytes must be
   * escaped, 0x00 - 0x1f and 0x80-0x9f may be optionally escaped - There are
   * currently 5 packet types: P_PACKET_NO_ACK: A user-packet, with no ack
   * required P_PACKET_ACK: A user-packet with a prefix byte, ack required. The
   * receiver must send a P_ACK packet with the prefix byte as its contents.
   * P_ACK: ack for a previous P_PACKET_ACK packet P_UNKNOWN: unknown packet
   * type received. On reception of an unknown packet type, the receicer must
   * send a P_UNKNOWN packet, the first byte must be the unknown packet type. -
   * Packets that are greater than a (private) MTU are silently dropped.
   */
  final static boolean DEBUG = false;

  final static int SYNC_BYTE = Serial.HDLC_FLAG_BYTE;

  final static int ESCAPE_BYTE = Serial.HDLC_CTLESC_BYTE;

  final static int MTU = 256;

  final static int ACK_TIMEOUT = 1000; // in milliseconds

  final static int P_ACK = Serial.SERIAL_PROTO_ACK;

  final static int P_PACKET_ACK = Serial.SERIAL_PROTO_PACKET_ACK;

  final static int P_PACKET_NO_ACK = Serial.SERIAL_PROTO_PACKET_NOACK;

  final static int P_UNKNOWN = Serial.SERIAL_PROTO_PACKET_UNKNOWN;

  private ByteSource io;

  private boolean inSync;

  private byte[] receiveBuffer = new byte[MTU];

  private int seqNo;

  // Packets are received by a separate thread and placed in a
  // per-packet-type queue. If received[x] is null, then x is an
  // unknown protocol (but P_UNKNOWN and P_PACKET_ACK are handled
  // specially)
  private Thread reader;

  private LinkedList[] received;

  /**
   * Packetizers are built using the makeXXX methods in BuildSource
   */
  Packetizer(String name, ByteSource io) {
    super(name);
    this.io = io;
    inSync = false;
    seqNo = 13;
    reader = new Thread(this);
    received = new LinkedList[256];
    received[P_ACK] = new LinkedList();
    received[P_PACKET_NO_ACK] = new LinkedList();
  }

  synchronized public void open(Messenger messages) throws IOException {
    super.open(messages);
    if(!reader.isAlive()) {
      reader.start();
    }
  }

  protected void openSource() throws IOException {
    io.open();
  }

  protected void closeSource() {
    io.close();
  }

  protected byte[] readProtocolPacket(int packetType, long deadline)
      throws IOException {
    LinkedList inPackets = received[packetType];

    // Wait for a packet on inPackets
    synchronized (inPackets) {
      while (inPackets.isEmpty()) {
        long now = System.currentTimeMillis();
        if (deadline != 0 && now >= deadline) {
          return null;
        }
        try {
          inPackets.wait(deadline != 0 ? deadline - now : 0);
        } catch (InterruptedException e) {
          throw new IOException("interrupted");
        }
      }
      return (byte[]) inPackets.removeFirst();
    }
  }

  // Place a packet in its packet queue, or reject unknown packet
  // types (which don't have a queue)
  protected void pushProtocolPacket(int packetType, byte[] packet) {
    LinkedList inPackets = received[packetType];

    if (inPackets != null) {
      synchronized (inPackets) {
        inPackets.add(packet);
        inPackets.notify();
      }
    } else if (packetType != P_UNKNOWN) {
      try {
        writeFramedPacket(P_UNKNOWN, packetType, ackPacket, 0);
      } catch (IOException e) {
      }
      message(name + ": ignoring unknown packet type 0x"
          + Integer.toHexString(packetType));
    }
  }

  protected byte[] readSourcePacket() throws IOException {
    // Packetizer packet format is identical to PacketSource's
    for (;;) {
      byte[] packet = readProtocolPacket(P_PACKET_NO_ACK, 0);
      if (packet.length >= 1) {
        return packet;
      }
    }
  }

  // Write an ack-ed packet
  protected boolean writeSourcePacket(byte[] packet) throws IOException {
    writeFramedPacket(P_PACKET_ACK, ++seqNo, packet, packet.length);

    long deadline = System.currentTimeMillis() + ACK_TIMEOUT;
    for (;;) {
      byte[] ack = readProtocolPacket(P_ACK, deadline);
      if (ack == null) {
        if (DEBUG) {
          message(name + ": ACK timed out");
        }
        return false;
      }
      if (ack[0] == (byte) seqNo) {
        if (DEBUG) {
          message(name + ": Rcvd ACK");
        }
        return true;
      }
    }

  }

  static private byte ackPacket[] = new byte[0];

  public void run() {
    try {
      for (;;) {
        byte[] packet = readFramedPacket();
        int packetType = packet[0] & 0xff;
        int pdataOffset = 1;

        if (packetType == P_PACKET_ACK) {
          // send ack
          writeFramedPacket(P_ACK, packet[1], ackPacket, 0);
          // And merge with un-acked packets
          packetType = P_PACKET_NO_ACK;
          pdataOffset = 2;
        }
        int dataLength = packet.length - pdataOffset;
        byte[] dataPacket = new byte[dataLength];
        System.arraycopy(packet, pdataOffset, dataPacket, 0, dataLength);
        pushProtocolPacket(packetType, dataPacket);
      }
    } catch (IOException e) {
    }
  }

  // Read system-level packet. If inSync is false, we currently don't
  // have sync
  private byte[] readFramedPacket() throws IOException {
    int count = 0;
    boolean escaped = false;

    for (;;) {
      if (!inSync) {
        message(name + ": resynchronising");
        // re-synchronise
        while (io.readByte() != SYNC_BYTE)
          ;
        inSync = true;
        count = 0;
        escaped = false;
      }

      if (count >= MTU) {
        // Packet too long, give up and try to resync
        message(name + ": packet too long");
        inSync = false;
        continue;
      }

      byte b = io.readByte();
      if (escaped) {
        if (b == SYNC_BYTE) {
          // sync byte following escape is an error, resync
          message(name + ": unexpected sync byte");
          inSync = false;
          continue;
        }
        b ^= 0x20;
        escaped = false;
      } else if (b == ESCAPE_BYTE) {
        escaped = true;
        continue;
      } else if (b == SYNC_BYTE) {
        if (count < 4) {
          // too-small frames are ignored
          count = 0;
          continue;
        }
        byte[] packet = new byte[count - 2];
        System.arraycopy(receiveBuffer, 0, packet, 0, count - 2);

        int readCrc = (receiveBuffer[count - 2] & 0xff)
            | (receiveBuffer[count - 1] & 0xff) << 8;
        int computedCrc = Crc.calc(packet, packet.length);

        if (DEBUG) {
          System.err.println("received: ");
          Dump.printPacket(System.err, packet);
          System.err.println(" rcrc: " + Integer.toHexString(readCrc)
              + " ccrc: " + Integer.toHexString(computedCrc));
        }

        if (readCrc == computedCrc) {
          return packet;
        } else {
          message(name + ": bad packet");
          /*
           * We don't lose sync here. If we did, garbage on the line at startup
           * will cause loss of the first packet.
           */
          count = 0;
          continue;
        }
      }

      receiveBuffer[count++] = b;
    }
  }

  // Class to build a framed, escaped and crced packet byte stream
  static class Escaper {
    byte[] escaped;

    int escapePtr;

    int crc;

    // We're building a length-byte packet
    Escaper(int length) {
      escaped = new byte[2 * length];
      escapePtr = 0;
      crc = 0;
      escaped[escapePtr++] = SYNC_BYTE;
    }

    static private boolean needsEscape(int b) {
      return b == SYNC_BYTE || b == ESCAPE_BYTE;
    }

    void nextByte(int b) {
      b = b & 0xff;
      crc = Crc.calcByte(crc, b);
      if (needsEscape(b)) {
        escaped[escapePtr++] = ESCAPE_BYTE;
        escaped[escapePtr++] = (byte) (b ^ 0x20);
      } else {
        escaped[escapePtr++] = (byte) b;
      }
    }

    void terminate() {
      escaped[escapePtr++] = SYNC_BYTE;
    }
  }

  // Write a packet of type 'packetType', first byte 'firstByte'
  // and bytes 2..'count'+1 in 'packet'
  private synchronized void writeFramedPacket(int packetType, int firstByte,
      byte[] packet, int count) throws IOException {
    if (DEBUG) {
      System.err.println("sending: ");
      Dump.printByte(System.err, packetType);
      Dump.printByte(System.err, firstByte);
      Dump.printPacket(System.err, packet);
      System.err.println();
    }

    Escaper buffer = new Escaper(count + 6);

    buffer.nextByte(packetType);
    buffer.nextByte(firstByte);
    for (int i = 0; i < count; i++) {
      buffer.nextByte(packet[i]);
    }

    int crc = buffer.crc;
    buffer.nextByte(crc & 0xff);
    buffer.nextByte(crc >> 8);

    buffer.terminate();

    byte[] realPacket = new byte[buffer.escapePtr];
    System.arraycopy(buffer.escaped, 0, realPacket, 0, buffer.escapePtr);

    if (DEBUG) {
      Dump.dump("encoded", realPacket);
    }
    io.writeBytes(realPacket);
  }
}
