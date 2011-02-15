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

generic module LcpAutomatonP (uint16_t Protocol,
                              bool InhibitCompression) {
  provides {
    interface Init;
    interface LcpAutomaton;
    interface GetSetOptions<LcpAutomatonOptions_t> as LcpOptions;
  }
  uses {
    interface Ppp;
    interface PppConfigure;
    interface Alarm<TMilli, uint32_t> as RestartTimer;
    interface PppProtocolCodeSupport as ConfigureRequest;
    interface PppProtocolCodeSupport as TerminateAck;
  }
} implementation {

  command error_t Init.init ()
  {
    return SUCCESS;
  }

  /** Convert state values into bits so we can represent sets of
   * states more efficiently */
  enum {
    ASB_Initial = (1 << LAS_Initial),
    ASB_Starting = (1 << LAS_Starting),
    ASB_Closed = (1 << LAS_Closed),
    ASB_Stopped = (1 << LAS_Stopped),
    ASB_Closing = (1 << LAS_Closing),
    ASB_Stopping = (1 << LAS_Stopping),
    ASB_RequestSent = (1 << LAS_RequestSent),
    ASB_AckReceived = (1 << LAS_AckReceived),
    ASB_AckSent = (1 << LAS_AckSent),
    ASB_Opened = (1 << LAS_Opened),
  };

  /** Type adequate to store a complete set of LCP automaton states */
  typedef uint16_t stateBitSet_t;

  /** The states in which the timer should not be running */
  const stateBitSet_t ASB_TimerRunningStates = (ASB_Closing | ASB_Stopping | ASB_RequestSent | ASB_AckReceived | ASB_AckSent);

  /** Action bits for state transitions.
   *
   * The actions taken when transitioning between states sometimes
   * must be executed synchronously, and often are split-phase.
   * Consequently, the actions involved in a transition cannot be done
   * in place, and may in fact take several revisits to complete.  We
   * support this by determining the set of actions in one operation
   * (calculateEventActions_), then working them off in order over in
   * potentially multiple task invocations (processEventActions_).
   *
   * This enumeration specifies actions to be performed during a
   * transition.  The actions are executed as a secondary state
   * machine starting from the low bit of the action set.  If any
   * action fails, the secondary machine stops and the primary state
   * is set to failState_.  If all actions complete successfully, the
   * primary state is set to successState_.
   *
   * Execution of the transition is suspended if the action is split
   * phase.
   *
   * Most of these actions are defined in section 4.4 of RFC1661.
   * Consult processEventActions_ to determine which events might
   * require processing to be suspended. */
  enum TransitionAction_b {
    TA_noop               =        0,
    /** thisLayerFinished */
    TA_tlf                =       0x01,
    TA_tld                =       0x02,
    TA_zrc                =       0x04,
    TA_irc_scr            =       0x10,
    TA_irc_str            =       0x20,
    TA_resetLocalOptions  =       0x40,
    TA_resetRemoteOptions =       0x80,
    TA_scr                =      0x100,
    TA_sca                =      0x200,
    TA_scn                =      0x400,
    TA_str                =     0x1000,
    /** send unsolicited Terminate-Ack */
    TA_sta_uns            =     0x2000,
    /** send Terminate-Ack in response to Terminate-Request */
    TA_sta_rep            =     0x4000,
    TA_scj                =    0x10000,
    TA_ser                =    0x20000,
    /** Extract and apply option values from the payload of a received
     * Configure-Ack message.  Must not co-occur with
     * TA_setRemoteOptions. */
    TA_setLocalOptions    =   0x100000,
    /** Extract and apply option values from the payload of a transmitted
     * Configure-Ack message.  Must not co-occur with TA_setLocalOptions. */
    TA_setRemoteOptions   =   0x200000,
    TA_tlu                = 0x01000000,
    TA_tls                = 0x02000000,

    /** Set of actions which can cause processing to be suspended. */
    TA_SUSPENDABLE = TA_scr | TA_sca | TA_scn | TA_str | TA_sta_uns | TA_sta_rep | TA_scj | TA_ser,
  };
  /** Type adequate to store an arbitrary set of transition actions */
  typedef uint32_t transitionActions_t;
  transitionActions_t pendingActions_;
  transitionActions_t lastAction_;

  /** The state to which the automaton will transition if all pending
   * actions complete successfully. */
  uint8_t successState_;

  /** The state to which the automaton will transition if any pending
   * action fails.  Ideally, that failure will not have changed
   * visible state. */
  uint8_t failState_;
  uint8_t currentState_;

  /** The code for the message that carried a given optionSet_.  When
   * the system is to invoke setRemoteOptions, this should be a
   * Code_ConfigureAck.  When the system is to invoke setLocalOptions,
   * this may be Code_ConfigureAck, Code_ConfigureNak, or
   * Code_ConfigureReject.  The specific code controls what is done
   * with the options.  */
  uint8_t optionMessageCode_;
  /** Storage to communicate an encoded option set between the code
   * that processes the events and the code that executes the
   * actions. */
  const uint8_t* optionSet_;
  /** Length of the option set in octets.  Valid only when optionSet_
   * is not null. */
  const uint8_t* optionSetEnd_;

  /** Store to communicate fact-of a pending transmission between the
   * event and action code.  Required when an event built a
   * Configure-Ack or Configure-Nak message, but correct functioning
   * requires that a Configure-Request message be transmitted
   * first. */
  frame_key_t pendingSxxKey_;

  /* Forward declaration */
  error_t calculateEventActions_ (LcpAutomatonEvent_e evt,
                                  void* arg);

  /* Forward declaration */
  error_t processEventActions_ ();

  /** Options for the automaton.  The default values are taken from
   * section 4.6 of RFC1661. */
  LcpAutomatonOptions_t options_ = { restartTimer_bms: 3 * 1024, // 3 sec
                                     maxTerminate: 2,            // 2
                                     maxConfigure: 10,           // 10
                                     maxFailure: 5 };            // 5
  
  bool changeState (LcpAutomatonState_e new_state)
  {
    return FALSE;
  }
  
  /** The number of retries available. */
  int16_t restartCounter_;
  /** The action that causes the restart timer to be enabled */
  transitionActions_t restartCounterAction_;
  void initializeRestartCounter (transitionActions_t action)
  {
    restartCounterAction_ = action;
    if (TA_scr == action) {
      restartCounter_ = options_.maxConfigure;
    } else if (TA_str == action) {
      restartCounter_ = options_.maxTerminate;
    } else if (TA_sta_rep == action) {
      restartCounter_ = 0;
    } else {
      restartCounterAction_ = TA_noop;
    }
    /* Timer is stopped now.  It will be restarted when the frame
     * associated with this activity is transmitted. */
    call RestartTimer.stop();
  }

  task void resumeAutomaton_task ()
  {
    processEventActions_();
  }

  /** Key which, when the corresponding output frame is transmitted,
   * causes the restart timer to be reset. */
  frame_key_t restartKey_;
  /** Key which, when the corresponding output frame is transmitted,
   * causes the automaton to resume processing. */
  frame_key_t resumeKey_;
  /** Error code archived from most recent transmission completion
   * that causes action execution to resume.  Must be SUCCESS at all
   * times that a split-phase transition is not in progress. */
  error_t resumeResult_;
  
  void restartTimer_ ()
  {
    call RestartTimer.start(options_.restartTimer_bms);
  }

  task void restartTimerFired_task ()
  {
    error_t rc;
    bool have_retries = (0 < restartCounter_);
    rc = calculateEventActions_(LAE_Timeout, &have_retries);
    if (SUCCESS == rc) {
      post resumeAutomaton_task();
    } else {
      /* Event processor is busy: try again soon */
      call RestartTimer.start(1);
    }
  }

  async event void RestartTimer.fired ()
  {
    post restartTimerFired_task();
  }

  event void Ppp.outputFrameTransmitted (frame_key_t key,
                                         error_t result)
  {
    if (restartKey_ == key) {
      restartKey_ = 0;
      restartTimer_();
    }
    if (resumeKey_ == key) {
      resumeResult_ = result;
      resumeKey_ = 0;
      post resumeAutomaton_task();
    }

    //printf("OFT %p: res %d rT %d auto %d\r\n", key, result, do_restart_timer, do_resume);
  }

  command LcpAutomatonState_e LcpAutomaton.getState () { return currentState_; }

  /** Determine the set of actions that must be performed upon receipt
   * of this event.
   *
   * @return ERETRY if the automaton is already processing a set of
   * actions.  Return SUCCESS in all other cases. */
  error_t calculateEventActions_ (LcpAutomatonEvent_e evt,
                                  void* arg)
  {
    stateBitSet_t sb = (1 << currentState_);

    /* If there's already something happening, presumably we're in
     * transient state.  Retry the packet later.
     *
     * @TODO@ We can be in TRANSIENT without any pendingActions_.
     * Clean up the state. */
    if (pendingActions_ || (LAS_TRANSIENT == currentState_)) {
      return ERETRY;
    }
    failState_ = successState_ = currentState_;
    switch (evt) {
      case LAE_Up:
        if ((ASB_Initial) & sb) {
          successState_ = LAS_Closed;
        } else if ((ASB_Starting) & sb) {
          /* For protocols not supporting Configure: tlu/9 */
          pendingActions_ |= TA_irc_scr | TA_scr;
          successState_ = LAS_RequestSent;
        } else {
          /* Invalid: Closed, Stopped, Closing, Stopping, Req-Sent, Ack-Rcvd, Ack-Sent, Opened */
        }
        break;
      case LAE_Down:
        if ((ASB_Closed | ASB_Closing) & sb) {
          successState_ = LAS_Initial;
        } else if ((ASB_Initial | ASB_Starting) & sb) {
          /* illegal */
        } else {
          if (ASB_Stopped & sb) {
            pendingActions_ |= TA_tls;
          } else if (ASB_Opened & sb) {
            pendingActions_ |= TA_tld;
          } else {
            /* Stopping, Req-Sent, Ack-Rcvd, Ack-Sent */
          }
          successState_ = LAS_Starting;
        }
        break;
      case LAE_Open:
        if (ASB_Initial & sb) {
          pendingActions_ |= TA_tls;
          successState_ = LAS_Starting;
        } else if (ASB_Closed & sb) {
          /* For protocols not supporting configure: 9 */
          pendingActions_ |= TA_irc_scr | TA_scr;
          successState_ = LAS_RequestSent;
        } else if ((ASB_Stopped | ASB_Closing | ASB_Stopping | ASB_Opened) & sb) {
          if (options_.restartOption) {
            /* @TODO@ Figure out how to execute nested events */
            /* evt down */
            /* evt up */
          } else {
            if (ASB_Closing & sb) {
              successState_ = LAS_Stopping;
            } else {
              /* No change: Stopped, Stopping, Opened */
            }
          }
        } else {
          /* No change: Starting, RequestSent, AckReceived, AckSent */
        }
        break;
      case LAE_Close:
        if ((ASB_Initial | ASB_Closed | ASB_Closing) & sb) {
          /* No change */
        } else if ((ASB_Starting) & sb) {
          pendingActions_ |= TA_tlf;
          successState_ = LAS_Initial;
        } else if ((ASB_Stopped) & sb) {
          successState_ = LAS_Closed;
        } else {
          if ((ASB_Opened) & sb) {
            pendingActions_ |= TA_tld;
          }
          if ((ASB_RequestSent | ASB_AckReceived | ASB_AckSent | ASB_Opened) & sb) {
            pendingActions_ |= TA_irc_str | TA_str;
          }
          successState_ = LAS_Closing;
        }
        break;
      case LAE_Timeout: {
        bool have_retries = FALSE;
        if (arg) {
          have_retries = *(bool*)arg;
        }
        if ((ASB_Closing | ASB_Stopping) & sb) {
          if (have_retries) {
            pendingActions_ |= TA_str;
          } else {
            pendingActions_ |= TA_tlf;
            if ((ASB_Closing) & sb) {
              successState_ = LAS_Closed;
            } else {
              successState_ = LAS_Stopped;
            }
          }
        } else if ((ASB_RequestSent | ASB_AckReceived | ASB_AckSent) & sb) {
          if (have_retries) {
            pendingActions_ |= TA_scr;
            if ((ASB_AckReceived) & sb) {
              successState_ = LAS_RequestSent;
            }
          } else {
            pendingActions_ |= TA_tlf;
            successState_ = LAS_Stopped;
            /* passive option? */
          }
        }
        break;
      }
      case LAE_ReceiveConfigureRequest: {
        LcpEventParams_rcr_t* params = (LcpEventParams_rcr_t*)arg;

        //printf("RCR good %d disp %d\r\n", params->good, params->disposition);
        if ((ASB_Initial | ASB_Starting) & sb) {
          /* Invalid */
        } else if ((ASB_Closing | ASB_Stopping) & sb) {
          /* No change */
        } else if ((ASB_Closed) & sb) {
          pendingActions_ |= TA_sta_uns;
        } else if ((ASB_Stopped) & sb) {
          pendingActions_ |= TA_irc_scr | TA_scr;
          if (params->good) {
            pendingActions_ |= TA_sca;
            successState_ = LAS_AckSent;
          } else {
            pendingActions_ |= TA_scn;
            successState_ = LAS_RequestSent;
          }
        } else if ((ASB_RequestSent | ASB_AckSent) & sb) {
          if (params->good) {
            pendingActions_ |= TA_sca;
            successState_ = LAS_AckSent;
          } else {
            pendingActions_ |= TA_scn;
            successState_ = LAS_RequestSent;
          }
        } else if ((ASB_AckReceived) & sb) {
          if (params->good) {
            pendingActions_ |= TA_sca | TA_tlu;
            successState_ = LAS_Opened;
          } else {
            pendingActions_ |= TA_scn;
            successState_ = LAS_AckReceived;
          }
        } else if ((ASB_Opened) & sb) {
          pendingActions_ |= TA_tld | TA_scr;
          if (params->good) {
            pendingActions_ |= TA_sca;
            successState_ = LAS_AckSent;
          } else {
            pendingActions_ |= TA_scn;
            successState_ = LAS_RequestSent;
          }
        }

        /* On a new Configure-Request, reset all the remote options.
         * We may immediately set them after transmitting a
         * Configure-Ack, but let's leave them in their reset state
         * between those two phases. */
        pendingActions_ |= TA_resetRemoteOptions;
        if (pendingActions_ & TA_sca) {
          /* Length of the option set is the entire payload minus the
           * code, identifier, and length fields. */
          pendingActions_ |= TA_setRemoteOptions;
          optionMessageCode_ = PppControlProtocolCode_ConfigureAck;
          optionSet_ = params->options;
          optionSetEnd_ = params->options_end;
        }
        pendingSxxKey_ = params->scx_key;
        break;
      }
      case LAE_ReceiveConfigureAck: {
        LcpEventParams_opts_t* params = (LcpEventParams_opts_t*)arg;

        if ((ASB_Closed | ASB_Stopped) & sb) {
          pendingActions_ |= TA_sta_uns;
        } else if ((ASB_Closing | ASB_Stopping) & sb) {
          /* No change */
        } else if ((ASB_RequestSent) & sb) {
          pendingActions_ |= TA_irc_scr;
          successState_ = LAS_AckReceived;
        } else if ((ASB_AckReceived) & sb) {
          pendingActions_ |= TA_scr;
          successState_ = LAS_RequestSent;
        } else if ((ASB_AckSent) & sb) {
          pendingActions_ |= TA_irc_scr | TA_tlu;
          successState_ = LAS_Opened;
        } else if ((ASB_Opened) & sb) {
          pendingActions_ |= TA_tld | TA_scr;
        } else {
          /* Invalid: Initial, Starting */
        }

        /* We apply local options upon receipt of a Configure-Ack (we
         * reset them on transmission of a Configure-Request). */
        pendingActions_ |= TA_setLocalOptions;
        optionMessageCode_ = params->code;
        optionSet_ = params->options;
        optionSetEnd_ = params->options_end;

        break;
      }
      case LAE_ReceiveConfigureNakRej: {
        LcpEventParams_opts_t* params = (LcpEventParams_opts_t*)arg;

        if ((ASB_Closed | ASB_Stopped) & sb) {
          pendingActions_ |= TA_sta_uns;
        } else if ((ASB_Closing | ASB_Stopping) & sb) {
          /* No change */
        } else if ((ASB_RequestSent) & sb) {
          pendingActions_ |= TA_irc_scr | TA_scr;
        } else if ((ASB_AckReceived) & sb) {
          pendingActions_ |= TA_scr;
          successState_ = LAS_RequestSent;
        } else if ((ASB_AckSent) & sb) {
          pendingActions_ |= TA_irc_scr | TA_scr;
        } else if ((ASB_Opened) & sb) {
          pendingActions_ |= TA_tld | TA_scr;
        } else {
          /* Invalid: Initial, Starting */
        }

        /* We apply local options upon receipt of a Configure-Ack (we
         * reset them on transmission of a Configure-Request). */
        pendingActions_ |= TA_setLocalOptions;
        optionMessageCode_ = params->code;
        optionSet_ = params->options;
        optionSetEnd_ = params->options_end;

        break;

      }
      case LAE_ReceiveTerminateRequest: {
        LcpEventParams_term_t* params = (LcpEventParams_term_t*)arg;

        if ((ASB_Closed | ASB_Stopped | ASB_Closing | ASB_Stopping
             | ASB_RequestSent | ASB_AckReceived | ASB_AckSent | ASB_Opened) & sb) {
          if (ASB_Opened & sb) {
            pendingActions_ |= TA_tld | TA_zrc | TA_sta_rep;
            successState_ = LAS_Stopping;
          } else {
            pendingActions_ |= TA_sta_rep;
            if ((ASB_AckReceived | ASB_AckSent) & sb) {
              successState_ = LAS_RequestSent;
            }
          }
          pendingSxxKey_ = params->sta_key;
        }
        break;
      }
      case LAE_ReceiveTerminateAck: {
        break;
      }
      case LAE_ReceveUnknownCode:
      case LAE_ReceiveCodeProtocolReject:
      case LAE_ReceiveEchoDiscardRequestReply:
        break;
    }
    return SUCCESS;
  }

  error_t processEventActions_ ()
  {
    frame_key_t key = 0;
    error_t rc = SUCCESS;
    transitionActions_t action;
    bool suspended = FALSE;
    transitionActions_t in_actions;
    
    in_actions = pendingActions_;
    rc = resumeResult_;
    resumeResult_ = SUCCESS;

    do {
      action = 0;

      if (pendingActions_) {
        action = 1;
        while (action && (! (pendingActions_ & action))) {
          action <<= 1;
        }
      }
      //printf("pAE %lx %lx %d %d %d : %d\r\n", action, pendingActions_, currentState_, successState_, failState_, rc);

      pendingActions_ &= ~action;
      lastAction_ = action;   /* @TODO@ is this needed? */

      /* If the action is one that restarts the timer and decrements
       * the restart counter, do the decrement now.  We'll schedule
       * the timer once the disposition of the corresponding send is
       * known. */
      if (restartCounterAction_ == action) {
        --restartCounter_;
      }

      switch (action) {
        case TA_noop:
          break;
        case TA_tlf:
          signal LcpAutomaton.thisLayerFinished();
          break;
        case TA_tld:
          signal LcpAutomaton.thisLayerDown();
          break;
        case TA_zrc:
          initializeRestartCounter(TA_sta_rep);
          restartKey_ = pendingSxxKey_;
          break;
        case TA_irc_scr:
          initializeRestartCounter(TA_scr);
          break;
        case TA_irc_str: {
          initializeRestartCounter(TA_str);
          break;
        }
        case TA_resetRemoteOptions:
          call PppConfigure.setRemoteOptions(0, 0);
          break;
#if 0
        /* Only and always done in TA_scr. */
        case TA_resetLocalOptions:
          call PppConfigure.setLocalOptions(0, 0);
          break;
#endif
        case TA_scr:
          if (SUCCESS == rc) {
            call PppConfigure.setLocalOptions(PppControlProtocolCode_ConfigureAck, 0, 0);
          }
          if (SUCCESS == rc) {
            rc = call ConfigureRequest.invoke(0, &key);
          }
          if ((SUCCESS == rc) && key) {
            restartKey_ = key;
            resumeKey_ = key;
            suspended = TRUE;
          } else {
            restartTimer_();
          }
          break;
        case TA_sta_uns:
          if (SUCCESS == rc) {
            rc = call TerminateAck.invoke(0, &key);
          }
          if ((SUCCESS == rc) && key) {
            resumeKey_ = key;
            suspended = TRUE;
          }
          break;
        case TA_sta_rep: /*FALLTHRU*/
        case TA_sca: /*FALLTHRU*/
        case TA_scn: {
          if (SUCCESS == rc) {
            rc = call Ppp.sendOutputFrame(pendingSxxKey_);
          }
          if (SUCCESS == rc) {
            resumeKey_ = pendingSxxKey_;
            suspended = TRUE;
          } else {
            resumeKey_ = restartKey_ = 0;
            (void)call Ppp.releaseOutputFrame(pendingSxxKey_);
          }
          pendingSxxKey_ = 0;
          break;
        }
        case TA_str:
        case TA_scj:
        case TA_ser:
          /* @TODO@ */
          break;
        case TA_setLocalOptions:
          /*FALLTHRU*/
        case TA_setRemoteOptions:
          if (TA_setLocalOptions == action) {
            call PppConfigure.setLocalOptions(optionMessageCode_, optionSet_, optionSetEnd_);
          } else {
            call PppConfigure.setRemoteOptions(optionSet_, optionSetEnd_);
          }
          break;
        case TA_tlu:
          signal LcpAutomaton.thisLayerUp();
          break;
        case TA_tls:
          signal LcpAutomaton.thisLayerStarted();
          break;
      }
    } while (action && (SUCCESS == rc) && (! suspended));
    if (suspended) {
      currentState_ = LAS_TRANSIENT;
    } else {
      bool disable_restart_timer;
      LcpAutomatonState_e end_state;
      //printf("FSA %lx %d rc=%d succ=%d fail=%d\r\n", in_actions, currentState_, rc, successState_, failState_);

      if (SUCCESS == rc) {
        currentState_ = successState_;
      } else {
        currentState_ = failState_;
      }
      disable_restart_timer = ! (ASB_TimerRunningStates & (1 << currentState_));
      if (disable_restart_timer) {
        restartKey_ = 0;
      }
      end_state = currentState_;

      optionSet_ = optionSetEnd_ = 0;
      if (pendingSxxKey_) {
        (void)call Ppp.releaseOutputFrame(pendingSxxKey_);
      }

      pendingSxxKey_ = 0;

      signal LcpAutomaton.transitionCompleted(end_state);
      if (disable_restart_timer) {
        call RestartTimer.stop();
      }
    }
    return rc;
  }

  error_t processEvent_ (LcpAutomatonEvent_e evt,
                         void* arg)
  {
    error_t rc;

    rc = calculateEventActions_(evt, arg);
    if (ERETRY == rc) {
      return rc;
    }
    /* In all other cases, we're responsible for resources.
     * processEventActions_ handles them. */
    return processEventActions_();
  }

  command error_t LcpAutomaton.signalEvent (LcpAutomatonEvent_e evt,
                                            void* params)
  {
    return processEvent_(evt, params);
  }

  default event void LcpAutomaton.transitionCompleted (LcpAutomatonState_e state) { }

  command error_t LcpOptions.set (const LcpAutomatonOptions_t* new_options) { return FAIL; }
  command LcpAutomatonOptions_t LcpOptions.get () { return options_; }

  command error_t LcpAutomaton.up () {
    return processEvent_(LAE_Up, 0);
  }
  command error_t LcpAutomaton.down ()
  {
    return processEvent_(LAE_Down, 0);
  }
  command error_t LcpAutomaton.open ()
  {
    return processEvent_(LAE_Open, 0);
  }
  command error_t LcpAutomaton.close ()
  { return processEvent_(LAE_Close, 0);
  }

  default event void LcpAutomaton.thisLayerUp () { }
  default event void LcpAutomaton.thisLayerDown () { }
  default event void LcpAutomaton.thisLayerStarted () { }
  default event void LcpAutomaton.thisLayerFinished () { }
  
}
