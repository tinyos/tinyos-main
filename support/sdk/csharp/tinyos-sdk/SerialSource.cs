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
using System.Threading;
using System.Diagnostics;

namespace tinyos.sdk
{
  class SerialSource : MessageSource
  {
    Framer framer;

    private const int PACKET_TYPE_OFFSET = 0;
    private const int PACKET_SEQNO_OFFSET = 1;
    private const int PACKET_HEADER_LEN = 2;

    private const byte DISPATCH_CODE = 0x00;

    private const byte SERIAL_PROTO_ACK = 0x43;
    private const byte SERIAL_PROTO_PACKET_ACK = 0x44;
    private const byte SERIAL_PROTO_PACKET_NOACK = 0x45;
    private const byte SERIAL_PROTO_PACKET_UNKNOWN = 0xFF;
    private const byte SERIAL_PACKET_DISPATCH_BYTE = 0;

    public static int MAX_RETRIES_NO_ACK = 0;
    public static int ACK_RECEIVED = 1;
    public static int NO_FRAMER_SET = -1;

    private Boolean waitingACK = false;
    private int retryCount;
    private int ackTimeoutIntvl = 1000; // milisegundos
    public const int MAX_RETRIES = 25;
    private System.Timers.Timer ackTimeout;
    private int seqNo;
    private byte[] packet;// paquete saliente
    private Mutex sendMutex = new Mutex();
    private Mutex ackMutex = new Mutex();
    private Semaphore ackRec;

    public SerialSource(String comPort, int baudRate) {
      framer = new Framer();
      try {
        framer.Open(comPort, baudRate);
      } catch (Exception e) {throw e;}
      framer.packedArrivedEvent += onPacketArrived;
      SetUpTimer();
    }

    public SerialSource() {}

    public void SetFramer(Framer f){
      framer = f;
      framer.packedArrivedEvent += onPacketArrived;
      SetUpTimer();
    }

    public Framer GetFramer(){
      return framer;
    }

    private void SetUpTimer() {
      ackTimeout = new System.Timers.Timer();
      ackTimeout.Elapsed += onAckTimeout;
      ackTimeout.Interval = ackTimeoutIntvl;
      ackTimeout.Enabled = false;
    }

    private void onPacketArrived(object sender, SerialPacket pck) {
      byte[] packet = pck.GetPacket();
      switch (packet[PACKET_TYPE_OFFSET]) {
        case SERIAL_PROTO_ACK:
          if (packet[PACKET_SEQNO_OFFSET] == seqNo) {
            StopWaitingACK();
          }
          break;
        case SERIAL_PROTO_PACKET_UNKNOWN: break;
        case SERIAL_PROTO_PACKET_ACK:
        // En este caso, debería enviarse ACK a la mota, 
        // pero este tipo de mensaje no esta implementado aún
        // en TinyOS (?)
        case SERIAL_PROTO_PACKET_NOACK:
        default:
          RaiseMessageArrived(new EventArgMessage(RemovePacketHeader(packet)));
          break;
      }
      //Console.Write("\nFRAME: " + BitConverter.ToString(packet, 0, packet.Length) + "\n");
    }

    private byte [] RemovePacketHeader(byte [] packet){
      // FIXME
      // La mota no envía el byte Dispatch. Por tanto
      // Se asume que es 0x00 y se añade aqui.
      int DispatchLen = 1;
      // --------------------------------------------
      int len = (packet.Length - PACKET_HEADER_LEN) + DispatchLen;
      int len2 = (packet.Length - PACKET_HEADER_LEN);
      byte[] msg = new byte[len];
      Array.Copy(packet, PACKET_HEADER_LEN, msg, DispatchLen, len2);
      msg[0]=0x00;
      return msg;
    }

    public override int Send(byte[] message) {
      if (framer==null) 
        return NO_FRAMER_SET;

      sendMutex.WaitOne();
      ackRec = new Semaphore(0, 1);
      SetUpPacket(message);
      retryCount = seqNo = 0;
      framer.Send(SERIAL_PROTO_PACKET_ACK, seqNo, packet);
      waitingACK = true;
      ackTimeout.Enabled = true;
      while ((retryCount < MAX_RETRIES) && waitingACK) {
        ackRec.WaitOne();
      }
      int retv = (retryCount == MAX_RETRIES) ? MAX_RETRIES_NO_ACK : ACK_RECEIVED;
      sendMutex.ReleaseMutex();
      if (retv == ACK_RECEIVED) {
        RaiseTxPacket();
      }
      else if (retv == MAX_RETRIES_NO_ACK) {
        RaiseToutPacket();
      }
      return retv;
    }

    public override void Close() {
      if (framer!=null)
        framer.Close();
    }

    // copy packet to outgoing buffer
    private void SetUpPacket(byte[] msg) {
      packet = new byte[msg.Length];
      Array.Copy(msg, 0, packet, 0, msg.Length);
    }

    private void onAckTimeout(object source, EventArgs e) {
      if (++retryCount == MAX_RETRIES) {
        StopWaitingACK();
      }
      else
        framer.Send(SERIAL_PROTO_PACKET_ACK, ++seqNo, packet);
    }

    private void StopWaitingACK() {
      ackMutex.WaitOne();
      waitingACK = false;
      ackTimeout.Enabled = false;
      try { ackRec.Release(); } catch (SemaphoreFullException e) {
       Debug.WriteLine(e.Message); 
      }
      ackMutex.ReleaseMutex();
    }
  }
}