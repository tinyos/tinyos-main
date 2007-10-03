/*
 * "Copyright (c) 2005 Stanford University. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 * 
 * IN NO EVENT SHALL STANFORD UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF STANFORD UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 * 
 * STANFORD UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND STANFORD UNIVERSITY
 * HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES,
 * ENHANCEMENTS, OR MODIFICATIONS."
 */

/**
 * This version of Main is the system interface the TinyOS boot
 * sequence in TOSSIM. It wires the boot sequence implementation to
 * the scheduler and hardware resources. Unlike the standard Main,
 * it does not actually define the <tt>main</tt> function, as a
 * TOSSIM simulation is triggered from Python.
 *
 * @author Philip Levis
 * @author Chad Metcalf
 * @date   Sep 14 2007
 */

// $Id: MainC.nc,v 1.1 2007-10-03 01:50:20 hiro Exp $

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

  // These components may not be used by the application, but must
  // be included. This is because there are Python calls that deliver
  // packets, and those python calls must terminate somewhere. If
  // the application does not wire this up to, e.g., ActiveMessageC,
  // the default handlers make sure nothing happens when a script
  // tries to deliver a packet to a node that has no radio stack.
  components TossimActiveMessageC;
  components SerialActiveMessageC;
  
}

