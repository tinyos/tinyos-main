/*
 * Copyright (c) 2012-2013, Eric B. Decker
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 *
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 *
 * - Neither the name of the copyright holders nor the names of
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

/*
 * Panic: Allow code to signal extreme conditions
 *
 * Panic allows code that implements sanity checking to indicate that
 * something major has gone wrong.  The class of error being checked and/or
 * indicated is fatal and not intended to be recoverable.  Included are things
 * that might happen that are bad but are unexpected and visibility is needed
 * when these failures occur.  Panic provides this mechanism.
 *
 * Modules that use Panic should provide a default handler (typically empty).
 * This avoids forcing a platform providing a Panic handler and makes
 * transitioning simpler.  This preserves exisiting code's behaviour (return
 * an error which typically isn't handled), sit in a tight loop, or ignore the
 * condition.  While the code shouldn't do that, Panic being defined the
 * way it is allows a graceful transition to giving visibility to that
 * condition.
 *
 * If one wants to make sure that Panic stubs are wired into an actual
 * panic handler, define REQUIRE_PANIC.  Typically this would be done
 * in the platform.h file.  Any Panic stubs not wired will throw "not
 * connected" errors.
 *
 * It is intended that Panic processing be defined on a platform by platform
 * basis.  For example, one platform may simply write the panic information
 * out a debugging channel (comm port) while another platform may write the
 * entire machine state to non-volatile storage and restart the machine.
 *
 * Usage: Typically a call to PanicHook.panic will be placed in error
 * detection code that is fatal and not intended to be recovered
 * from.  For example a tight loop waiting for some hardware event.  The
 * event should be timed (infinite loops when the h/w event doesn't happen
 * are bad and hang the machine).  The only recourse at that point is to
 * rely on the watchdog timer going off or similar function.  This is bad,
 * very bad.
 *
 * The first two parmeters (pcode, where) denote the subsystem and where
 * in the subsystem the failure has occured at.  Pcode can be allocated
 * automatically or a platform can specify explicitly what Pcode values
 * corespond to what subsystem.
 *
 * For example, the following is used in the msp430 i2c subsystem, which
 * checks for various h/w conditions that can hang the system:
 *
 * #ifndef PANIC_I2C
 *
 * enum {
 *   __panic_i2c = unique(UQ_PANIC_SUBSYS)
 * };
 *
 * #define PANIC_I2C __panic_i2c
 * #endif
 *
 * "where" is a simple integer (uint8_t) that denotes where in the subsystem
 * the problem has occurred.   This mechanism was chosen to keep things simple
 * and to minimize resources that could be consummed.   For example, the
 * mechanism used by ASSERT typically uses __FILE__ and __LINE__ to denote the
 * failure location but __FILE__ generates a string which in a memory
 * constrained system is too expensive.
 *
 * Typically Panics in h/w modules get wired in via a platform dependent mapping
 * module, ie. PlatformUsciMapC.nc.
 */

interface Panic {
  async command void panic(uint8_t pcode, uint8_t where,
        parg_t arg0, parg_t arg1, parg_t arg2, parg_t arg3);
  async command void  warn(uint8_t pcode, uint8_t where,
        parg_t arg0, parg_t arg1, parg_t arg2, parg_t arg3);
  async event   void  hook();
}
