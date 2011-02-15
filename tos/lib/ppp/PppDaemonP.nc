/* Copyright (c) 2010 People Power Co.
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
 * - Neither the name of the People Power Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * PEOPLE POWER CO. OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 *
 */
#include "lcp.h"

module PppDaemonP {
  uses {
    interface LcpAutomaton;
    interface SplitControl as PppControl;
    interface PppProtocolCodeSupport as ProtocolReject;
  }
  provides {
    interface SplitControl;
    interface PppProtocolReject;
  }
} implementation {
  command error_t SplitControl.start ()
  {
    error_t rc;
    rc = call LcpAutomaton.open();
    if (SUCCESS != rc) {
      return rc;
    }
    return call PppControl.start();
  }
  event void PppControl.startDone (error_t rc)
  {
    if (SUCCESS == rc) {
      call LcpAutomaton.up();
    }
  }
  default event void SplitControl.startDone (error_t error) { }

  event void PppControl.stopDone (error_t rc)
  {
    if (SUCCESS == rc) {
      call LcpAutomaton.down();
    }
  }
  
  command error_t SplitControl.stop ()
  {
    error_t rc;
    rc = call LcpAutomaton.close();
    return call PppControl.stop();
  }
  default event void SplitControl.stopDone (error_t error) { }
  
  command error_t PppProtocolReject.process (unsigned int protocol,
                                             const uint8_t* information,
                                             unsigned int length)
  {
    protocolReject_param_t args;

    args.protocol = protocol;
    args.information = information;
    args.information_length = length;
    return call ProtocolReject.invoke(&args, 0);
  }

  event void LcpAutomaton.transitionCompleted (LcpAutomatonState_e state) { }
  event void LcpAutomaton.thisLayerUp () { }
  event void LcpAutomaton.thisLayerDown () { }
  event void LcpAutomaton.thisLayerStarted () { }
  event void LcpAutomaton.thisLayerFinished () { }

}
