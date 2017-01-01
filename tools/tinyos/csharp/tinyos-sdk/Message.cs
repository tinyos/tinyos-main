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
  public abstract class Message
  {
    /// <summary>
    /// Secuencia de bytes que almacena el mensaje completo, con cabecera incluida.
    /// </summary>
    protected byte[] message;

    /// <summary>
    /// Longitud de la cabecera. También marca la posición 
    /// de inicio del campo de datos (payload) del mensaje.
    /// </summary>
    public abstract int HEADER_LEN { get; }

    protected int[] fieldsLenght;
    public abstract void DefineMessageFieldsLenghts();

    public Message(byte[] message) {
      this.message = new byte[message.Length];
      Array.Copy(message, this.message, message.Length);
    }

    public Message() { }
    

    /// <summary>
    /// Maximo tamaño del campo de datos. Este tamaño viene determinado por la MTU
    /// del protocolo del puerto serie de TinyOS (256 bytes)
    /// </summary>
    //public abstract int MAX_DATA_LEN{get;}

    /// <summary>
    /// Indexador para acceder a los campos de la cabecera del mensaje
    /// </summary>
    /// <param name="field">El campo del mensaje en orden secuencial
    ///  que se desea obtener o establecer</param>
    /// <returns>El valor que almacena el campo requerido en una representación
    /// de entero sin signo</returns>
    public uint this[int field] {
      get {
        int len = FieldLen(field);
        int offset = FieldOffset(field);
        uint ret = 0;
        int start = offset + (len - 1);
        for (int i = 0; i < len; i++) {
          ret |= (uint)message[start - i] << i * 8;
        }
        return ret;
      }

      set {
        int len = FieldLen(field);
        int offset = FieldOffset(field);
        int start = offset + (len - 1);
        for (int i = 0; i < len; i++) {
          message[start - i] = (byte)(0xff & value);
          value = value >> 8;
        }
      }
    }

    /*
    public byte[] GetField(int field) { 
      
    }

    public void SetField(int field, byte[] f) { 
      
    }
     * */

    /// <summary>
    /// Obtiene la secuencia de bytes que representa el mensaje completo
    /// </summary>
    /// <returns>La secuencia de bytes del mensaje</returns>
    public byte[] GetMessageBytes() {
      return message;
    }

    /// <summary>
    /// Obtiene el número de bytes desde el inicio del mensaje hasta la posición
    /// del campo especificado
    /// </summary>
    /// <param name="field">Campo del cual se obtendrá la posición en el mensaje.</param>
    /// <returns>La posición del campo especificado por parámetros</returns>
    protected virtual int FieldOffset(int field) {
      int offset = 0;
      for (int i = 0; i < field; i++) {
        offset += fieldsLenght[i];
      }
      return offset;
    }
    //return offsets[(int)field];


    /// <summary>
    /// Obtiene la longitud en bytes del campo especificado
    /// </summary>
    /// <param name="field">Campo del cual se obtendrá la longitud</param>
    /// <returns>La longitud del campo especificado por parámetros</returns>
    protected virtual int FieldLen(int field) {
      return fieldsLenght[field];
    }
    //return lenghts[(int)field];


    /// <summary>
    /// Copia la secuencia de bytes de datos pasado por parámetros al campo datos
    /// de la secuencia de bytes del mensaje
    /// </summary>
    /// <param name="data">La secuencia de datos origen</param>
    public void SetPayload(byte[] data) {
      if (message == null) return;
      if (data == null)
        throw new ArgumentNullException();
      if ((message.Length - HEADER_LEN) != data.Length)
        throw new ArgumentException();
      try {
        Array.Copy(data, 0, message, HEADER_LEN, data.Length);
      } catch (Exception e) { throw e; }
    }

    /// <summary>
    /// Obtiene una copia de la secuencia de bytes del campo de datos del mensaje
    /// </summary>
    /// <returns>La copia de la secuencia de datos</returns>
    public byte[] GetPayload() {
      int dataLen = message.Length - HEADER_LEN;
      byte[] data = new byte[dataLen];
      Array.Copy(message, HEADER_LEN, data, 0, dataLen);
      return data;
    }
  }
}
