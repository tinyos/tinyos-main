/*
 * Copyright (c) 2006, Technische Universitaet Berlin
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
 * - Neither the name of the Technische Universitaet Berlin nor the names
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
 *
 * - Revision -------------------------------------------------------------
 * $Revision: 1.3 $
 * $Date: 2006-12-12 18:23:41 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

generic module ReadStreamShiftC(uint8_t bits)
{
  provides interface ReadStream<uint16_t> as ReadStreamShifted;
  uses interface ReadStream<uint16_t> as ReadStreamRaw;
}
implementation
{
  command error_t ReadStreamShifted.postBuffer(uint16_t* buf, uint16_t count) 
  {
    return call ReadStreamRaw.postBuffer(buf, count);
  }
  
  command error_t ReadStreamShifted.read(uint32_t usPeriod) 
  { 
    return call ReadStreamRaw.read(usPeriod); 
  }

  event void ReadStreamRaw.bufferDone(error_t result, 
			 uint16_t* buf, uint16_t count)
  {
    uint16_t i;
    if (result == SUCCESS)
      for (i=0; i<count; i++)
        buf[i] <<= bits; 
    signal ReadStreamShifted.bufferDone(result, buf, count);
  }
  
  event void ReadStreamRaw.readDone(error_t result, uint32_t usActualPeriod) 
  { 
    signal ReadStreamShifted.readDone(result, usActualPeriod); 
  }
}
