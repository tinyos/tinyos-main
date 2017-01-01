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
using System.Collections;
using System.Linq;
using System.Text;


namespace tinyos.sdk
{

  /// <summary>
  /// Esta clase representa un mensaje del puerto serie de TinyOS
  /// Incluye cabecera y datos
  /// </summary>
  public class SerialMessage : Message
  {
    public const int DISPATCH_BYTE = 0;
    public const int DEST = 1;
    public const int SRC = 2;
    public const int LEN = 3;
    public const int GROUP = 4;
    public const int AMTYPE = 5;

    public override void DefineMessageFieldsLenghts() {
      fieldsLenght = new int[]{1,2,2,1,1,1};
    }

    public const int SERIAL_HEADER_LEN = 8;

    public override int HEADER_LEN {
      get { return  SERIAL_HEADER_LEN; }
    }

    /// <summary>
    /// Maximo tamaño del campo de datos. Este tamaño viene determinado por la MTU
    /// del protocolo del puerto serie de TinyOS (256 bytes)
    /// </summary>
    public const int MAX_DATA_LEN = 244;

    /// <summary>
    /// Constructor que especifica todos los parámetros de la cabecera y
    /// el campo de datos
    /// </summary>
    /// <param name="dest">Valor del campo destino del mensaje</param>
    /// <param name="src">Valor del campo fuente del mensaje</param>
    /// <param name="group">Valor del campo grupo</param>
    /// <param name="amtype">Valor del campo de tipo de mensaje o entidad receptora</param>
    /// <param name="data">Datos del mensaje</param>
    public SerialMessage(int dest, int src, byte group, byte amtype, byte[] data) {
      if (data == null)
        throw new ArgumentNullException();

      if (data.Length > MAX_DATA_LEN)
        throw new ArgumentException();

      DefineMessageFieldsLenghts();

      message = new byte[data.Length + HEADER_LEN];
      this[(int)DEST] = (uint)dest;
      this[(int)SRC] = (uint)src;
      this[(int)LEN] = (uint)data.Length;
      this[(int)GROUP] = (uint)group;
      this[(int)AMTYPE] = (uint)amtype;
      SetPayload(data);
    }

    /// <summary>
    /// Constructor
    /// </summary>
    /// <param name="data">Campo de datos del mensaje</param>
    /// <param name="amtype">Valor del campo de tipo de mensaje o entidad receptora</param>
    public SerialMessage(byte[] data, byte amtype) {
      if (data == null)
        throw new ArgumentNullException();

      if (data.Length > MAX_DATA_LEN)
        throw new ArgumentException();

      DefineMessageFieldsLenghts();
      message = new byte[data.Length + HEADER_LEN];
      this[(int)LEN] = (uint)data.Length;
      this[(int)AMTYPE] = (uint)amtype;
      SetPayload(data);
    }

    /// <summary>
    /// Construye el mensaje a partir de la secuencia de bytes de otro mensaje
    /// </summary>
    /// <param name="msg">El mensaje que se copiara en esta instancia</param>
    public SerialMessage(byte[] msg) {
      if (msg == null)
        throw new ArgumentNullException();

      int dataLen = msg.Length - (HEADER_LEN);
      if (dataLen < 0)
        throw new ArgumentException();

      if (dataLen > MAX_DATA_LEN)
        throw new ArgumentException();

      message = new byte[msg.Length];
      Array.Copy(msg, 0, this.message, 0, msg.Length);
    }

    /// <summary>
    /// Obtiene el número de bytes desde el inicio del mensaje hasta la posición
    /// del campo especificado
    /// </summary>
    /// <param name="field">Campo del cual se obtendrá la posición en el mensaje.</param>
    /// <returns>La posición del campo especificado por parámetros</returns>
    protected override int FieldOffset(int field) {
      int offset = 0;
      for (int i = 0; i < field; i++) {
        offset += fieldsLenght[i];
      }
      return offset;
    }

    /// <summary>
    /// Obtiene la longitud en bytes del campo especificado
    /// </summary>
    /// <param name="field">Campo del cual se obtendrá la longitud</param>
    /// <returns>La longitud del campo especificado por parámetros</returns>
    protected override int FieldLen(int field) {
      return fieldsLenght[field];
    }

    public static byte[] HexStringToByteArray(string hex) {
      if (hex.Length % 2 != 0) {
        hex=hex.Insert(hex.Length-1, "0");
      }
        
      byte[] hexArray = new byte[hex.Length/2];
      
      for (int i=0,l=hex.Length;i<l;i+=2) {
        string hexByte = hex[i].ToString()+hex[i+1].ToString();
        hexArray[i / 2] = Convert.ToByte(hexByte, 16);
      }
      return hexArray;
    }
  }
}
