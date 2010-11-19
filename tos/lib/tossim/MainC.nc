/*
 * Copyright (c) 2005 Stanford University. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holder nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * This version of Main is the system interface the TinyOS boot
 * sequence in TOSSIM. It wires the boot sequence implementation to
 * the scheduler and hardware resources. Unlike the standard Main,
 * it does not actually define the <tt>main</tt> function, as a
 * TOSSIM simulation is triggered from Python.
 *
 * @author Philip Levis
 * @date   August 6 2005
 */

// $Id: MainC.nc,v 1.6 2010-06-29 22:07:51 scipio Exp $

#include "hardware.h"

configuration MainC {
  provides interface Boot;
  uses interface Init as SoftwareInit;
}
implementation {
  components PlatformC, SimMainP, TinySchedulerC;
  
  // SimMoteP is not referred to by any component here.
  // It is included to make sure nesC loads it, as it
  // includes functionality many other systems depend on.
  components SimMoteP;
  
  SimMainP.Scheduler -> TinySchedulerC;
  SimMainP.PlatformInit -> PlatformC;

  // Export the SoftwareInit and Booted for applications
  SoftwareInit = SimMainP.SoftwareInit;
  Boot = SimMainP;

  // This component may not be used by the application, but it must
  // be included. This is because there are Python calls that deliver
  // packets, and those python calls must terminate somewhere. If
  // the application does not wire this up to, e.g., ActiveMessageC,
  // the default handlers make sure nothing happens when a script
  // tries to deliver a packet to a node that has no radio stack.
  components ActiveMessageC;
  
}

