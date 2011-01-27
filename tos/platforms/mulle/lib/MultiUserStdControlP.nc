/*
 * Copyright (c) 2009 Communication Group and Eislab at
 * Lulea University of Technology
 *
 * Contact: Laurynas Riliskis, LTU
 * Mail: laurynas.riliskis@ltu.se
 * All rights reserved.
 *
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
 * - Neither the name of Communication Group at Lulea University of Technology
 *   nor the names of its contributors may be used to endorse or promote
 *    products derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL STANFORD
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * A module creating multiple StdControls from one shared StdControl.
 * The shared StdControl will only be turned off once all of the
 * StdControls provided by this module are turned off.
 *
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 */
generic module MultiUserStdControlP()
{
  provides interface StdControl[uint8_t client];

  uses interface StdControl as SharedStdControl;
  uses interface BitVector;
}
implementation
{

  command error_t StdControl.start[uint8_t client]()
  {
    call BitVector.set(client);
    return call SharedStdControl.start();
  }

  command error_t StdControl.stop[uint8_t client]()
  {
    uint16_t i;
    call BitVector.clear(client);
    for (i = 0; i < call BitVector.size(); ++i)
    {
      if (call BitVector.get(i))
      {
        // There is some other resource that still is
        // using the module controlled by this StdControl.
        // We cant turn off now, so return SUCCESS.
        return SUCCESS;
      }
    }
    return call SharedStdControl.stop();
  }
}
