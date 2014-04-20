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

// $Id$

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
  //components TossimActiveMessageC;
  components CC2420CsmaP;

}

