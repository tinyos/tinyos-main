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
#include "LcpAutomaton.h"

/** Manage the Link Control Protocol automaton.
 *
 * This interface is subject to change, as it is unclear which actions
 * should be publicly available.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */
interface LcpAutomaton {

  /** Raised upon completion of the transition actions associated with
   * an automaton event.
   *
   * @param state The resulting state of the automaton.  May be the
   * same as the previous state.
   */
  event void transitionCompleted (LcpAutomatonState_e state);

  /** Obtain the current state of the automaton */
  command LcpAutomatonState_e getState ();

  /** Externally indicate that the layer is ready.
   *
   * This command is normally invoked only by the Ppp daemon when
   * bringing up LCP, and by an LCP automaton when a lower layer is
   * ready to carry packets. */
  command error_t up ();

  /** Externally indicate that the layer is ready.
   *
   * This command is normally invoked only by the Ppp daemon when
   * closing down the link, and by an LCP automaton when all upper
   * layers have closed. */
  command error_t down ();

  /** Administratively enable the automaton.
   *
   * This is normally invoked during application initialization, to
   * indicate that the corresponding protocol should be enabled as
   * soon as enough of PPP is up to allow messages to get to it.
   *
   * @return SUCCESS if automaton transition succeeded.  ERETRY if the
   * automaton is busy, and the attempt should repeated. */
  command error_t open ();

  /** Administratively disable the automaton.
   *
   * @return SUCCESS if automaton transition succeeded.  ERETRY if the
   * automaton is busy, and the attempt should repeated. */
  command error_t close ();

  /** Notify the automaton of an event to be executed.
   *
   * @param evt The event that is inducing a state transition.
   *
   * @param params Pointer to an event-specific structure required to
   * complete the actions associated with the transition.  Note that
   * the parameters may include resources, the responsibility for
   * which is normally transferred to the automaton.
   *
   * @note If this command returns ERETRY, any resource included in
   * the params was not accepted by the automaton, and the caller must
   * dispose of it.  For SUCCESS and for all non-ERETRY error returns,
   * the automaton accepts resource parameters and is responsible for
   * releasing them.
   *
   * @return The result of the signal operation.  If ERETRY, the
   * automaton is busy, but the event may be re-signaled later.  For
   * all other returns, the event should not be re-signalled. */
  command error_t signalEvent (LcpAutomatonEvent_e evt,
                               void* params);

  /** Raised by the automaton to indicate to upper layers that the
   * automaton has entered the Opened state.
   *
   * Normally, upper layers should respond by invoking the up()
   * command on themselves.
   */
  event void thisLayerUp ();

  /** Raised by the automaton to indicate to upper layers that the
   * automaton is leaving the Opened state.
   *
   * Normally, upper layers should respond by invoking the down()
   * command on themselves.
   */
  event void thisLayerDown ();

  /** Raised by the automaton to indicate to lower layers that the
   * automaton is entering the Starting state and the lower layer is
   * needed. */
  event void thisLayerStarted ();

  /** Raised by the automaton to indicate to lower layers that the
   * automaton is entering the Initial, Closed, or Stopped states, and
   * the lower layer is no longer needed for the link. */
  event void thisLayerFinished ();
}
