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
using System.IO.Ports;


namespace tinyos.sdk
{
  /*
   *  Esta clase extrae el paquete de una trama serie y realiza la
   *  CRC. Es el argumento del evento de notificación de nuevo paquete
   *  que la clase Framer envía a todos los suscriptores.
   */
  class SerialPacket : EventArgs
  {
    private byte[] packet;
    private Boolean crc = false;

    public SerialPacket(byte[] buffer, int frameSize) {
      // 4: dos bytes SYNC + 2 bytes CRC
      packet = new byte[frameSize - 4];

      // copy packet from frame buffer
      Array.Copy(buffer, 1, packet, 0, frameSize - 4);
      int frameCrc = (buffer[frameSize - 3] & 0xff)
      | (buffer[frameSize - 2] & 0xff) << 8;
      int computedCrc = Escaper.calc(packet, packet.Length);

      if (computedCrc == frameCrc) {
        crc = true;
      }
    }

    public byte[] GetPacket() {
      return packet;
    }

    public Boolean OkCrc() {
      return crc;
    }
  }

  /*
   * Escucha el puerto serie mediante la interfaz estandar C#. Envía
   * un evento a todos los suscriptores cuando ha recibido una trama 
   * completa.
   */
  class Framer
  {
    SerialPort serial;

    byte[] serialBuffer = new byte[MAX_BUFF_SIZE];
    int serialBufferPtr = 0; // puntero del bufer
    Boolean escaped = false;

    private const int MAX_BUFF_SIZE = 256; // tamaño maximo del buffer (MTU=256)
    private const byte SYNC_BYTE = 0x7E; // byte framing
    private const byte ESCAPE_BYTE = 0x7D; // byte de escape
    private const byte MIN_FRAME_SIZE = 6; // tamaño mínimo de una trama
    /* 
     * Manejador de evento de trama recibida. Es una propiedad pública. Si
     * Una clase tiene acceso a la instancia de Framer que ha abierto el puerto serie
     * Puede suscribirse al evento de recepción de trama mediante:
     * framer.frameArrived += nombreMetodoManejador;
     
     Ver FrameListener.cs*/
    public event EventHandler<SerialPacket> packedArrivedEvent;

    public void Open(String comPort, int baudRate) {
      try{
        serial = new SerialPort(comPort, baudRate, Parity.None, 8, StopBits.One);
      } catch(Exception e){throw e;}

      serial.DataReceived += new SerialDataReceivedEventHandler(DataReceived);
      try{
        serial.Open();
      } catch (Exception e) {throw e;}
    }

    public void Close() {
      if (serial.IsOpen)
        serial.Close();
    }

    /*
     * Este método se ejecuta cada vez que hay datos en el puerto serie
     * Lee secuencialmente cada uno de los bytes disponibles y se los pasa
     * al método processByte.
     */
    private void DataReceived(object sender, SerialDataReceivedEventArgs e) {
      byte b = 0x00;
      int bytesToRead = serial.BytesToRead;
      for (int i = 0; i < bytesToRead; i++) {
        try {
          b = (byte)serial.ReadByte();
        } catch (System.Exception ex) {
          Console.WriteLine(ex.Message + " Byte: " + b);
        }
        ProcessByte(b);
      }
    }

    /*
     * Actúa en función del tipo de byte. Hay 3 casos:
     1. Byte de inicio/fin trama (sincronización)
     2. Byte de escape 
     3. Otro byte
     */
    private void ProcessByte(byte b) {
      switch (b) {
        case SYNC_BYTE:
          SyncProtocol(b);
          break;

        case ESCAPE_BYTE:
          EscapeProtocol();
          break;

        default:
          if (serialBufferPtr > 0) {
            if (escaped) {
              b ^= 0x20;
              escaped = false;
            }
            CopyByteToBuffer(b);
          } break;
      }
    }

    private void SyncProtocol(byte sync) {
      if (escaped) {
        // sync byte despues de escape es error
        serialBufferPtr = 0;
        escaped = false;
        return;
      }
      if (serialBufferPtr == 0) {
        // Inicio de trama
        CopyByteToBuffer(sync);
        return;
      }
      else if (CopyByteToBuffer(sync) >= MIN_FRAME_SIZE) {
        // Fin de trama
        SerialPacket pck = new SerialPacket(serialBuffer, serialBufferPtr);
        if (pck.OkCrc())
          RaiseEventFrameArrived(pck);
      }
      serialBufferPtr = 0;
    }

    private void EscapeProtocol() {
      escaped = true;
    }

    /*
     * Copia un byte al buffer de entrada e incrementa el puntero
     * del buffer. MAX_BUFF_SIZE coincide con el MTU de protocolo.
     */
    private int CopyByteToBuffer(byte b) {
      serialBuffer[serialBufferPtr] = b;
      serialBufferPtr = ++serialBufferPtr % MAX_BUFF_SIZE;
      return serialBufferPtr;
    }

    /*
     * Publica un evento pasando el paquete de la trama como argumento a 
     * todos los suscriptores
     * del mismo
     */
    protected virtual void RaiseEventFrameArrived(SerialPacket frm) {
      EventHandler<SerialPacket> handler = packedArrivedEvent;
      if (handler != null) {
        handler(this, frm);
      }
    }

    public void Send(int packetType, int firstByte, byte[] packet) {
      if (!serial.IsOpen)
        return;
      int count = packet.Length;
      Escaper outBuff = new Escaper(count + 7);
      outBuff.nextByte(packetType);
      outBuff.nextByte(firstByte);
      for (int i = 0; i < count; i++) {
        outBuff.nextByte(packet[i]);
      }
      int crc = outBuff.crc;
      outBuff.nextByte(crc & 0xff);
      outBuff.nextByte(crc >> 8);

      outBuff.terminate();
      byte[] frame = new byte[outBuff.escapePtr];
      Array.Copy(outBuff.escaped, 0, frame, 0, outBuff.escapePtr);
      serial.Write(frame, 0, frame.Length);
      //Console.Write("\nSENT: " + BitConverter.ToString(frame, 0, frame.Length) + "\n");
    }
  }

  // Class to build a framed, escaped and crced packet byte stream
  // Reutilizada [Packetizer.java]
  class Escaper
  {
    private const byte SYNC_BYTE = 0x7E; // byte framing
    private const byte ESCAPE_BYTE = 0x7D; // byte de escape
    public byte[] escaped;

    public int escapePtr;

    public int crc;

    public Escaper(int length) {
      escaped = new byte[2 * length];
      escapePtr = 0;
      crc = 0;
      escaped[escapePtr++] = SYNC_BYTE;
    }

    static private Boolean needsEscape(int b) {
      return b == SYNC_BYTE || b == ESCAPE_BYTE;
    }

    public void nextByte(int b) {
      b = b & 0xff;
      crc = calcByte(crc, b);
      if (needsEscape(b)) {
        escaped[escapePtr++] = ESCAPE_BYTE;
        escaped[escapePtr++] = (byte)(b ^ 0x20);
      }
      else {
        escaped[escapePtr++] = (byte)b;
      }
    }

    public static int calcByte(int crc, int b) {
      crc = crc ^ (int)b << 8;
      for (int i = 0; i < 8; i++) {
        if ((crc & 0x8000) == 0x8000)
          crc = crc << 1 ^ 0x1021;
        else
          crc = crc << 1;
      }
      return crc & 0xffff;
    }

    public static int calc(byte[] packet, int index, int count) {
      int crc = 0;

      while (count > 0) {
        crc = calcByte(crc, packet[index++]);
        count--;
      }
      return crc;
    }

    public static int calc(byte[] packet, int count) {
      return calc(packet, 0, count);
    }

    public void terminate() {
      escaped[escapePtr++] = SYNC_BYTE;
    }
  }
}
