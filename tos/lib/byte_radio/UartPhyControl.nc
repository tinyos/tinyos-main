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
 */
 
/**
 * This interface provides commands to control the structure of 
 * transmitted (physical) packets and provides commands and events
 * to control the physical layer of byte radios.
 *
 * @author Philipp Huppertz (huppertz@tkn.tu-berlin.de)
 */ 
interface UartPhyControl {
  
  /**
  * Sets the number of transmitted preamble bytes.
  *
  * @param numPreambleBytes the numbeof preamble bytes.
  *
  * @return SUCCESS if it could be set (no current receiving/transmitting)
            FALSE otherwise.
  */
  async command error_t setNumPreambles(uint16_t numPreambleBytes);
    
  /**
  * Sets the timeout after the byte-stream is considered dead if no more
  * bytes occur on the sending or receiving side. This means isBusy()
  * returns FALSE.
  *
  * @param byteTimeout timeout in ms.
  *
  * @return SUCCESS if it could be set (no current receiving/transmitting)
  *         FALSE otherwise.
  */
  command error_t setByteTimeout(uint8_t byteTimeout);
  
  /** 
  * Tests if the UartPhy is busy with sending or receiving a packet. 
  *
  * @return TRUE if active
  *         FALSE otherwise.
  */
  async command bool isBusy();

}
