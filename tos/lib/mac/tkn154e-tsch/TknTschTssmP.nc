/*
 * Copyright (c) 2014, Technische Universitaet Berlin
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
 * @author Moksha Birk <birk@tkn.tu-berlin.de>
 * @author Jasper Büsch <buesch@tkn.tu-berlin.de>
 * ========================================================================
 */

#include "Timer.h"
//#include "Timer62500hz.h"
#include "TimerSymbol.h"

#ifndef APP_RADIO_CHANNEL
#define APP_RADIO_CHANNEL RADIO_CHANNEL
#endif

#include "tkntsch_pib.h"
#include "static_config.h" // slotframe and template
#include "tssm_utils.h"    // TSSM_* macros (Alarm, State)

#include "plain154_message_structs.h"
#include "plain154_values.h"
#include "TknTschConfig.h"

#include "TknTschConfigLog.h"
//#ifndef TKN_TSCH_LOG_ENABLED_TSSMP
//#undef TKN_TSCH_LOG_ENABLED
//#endif
#include "tkntsch_log.h"

module TknTschTssmP
{
  provides {
    interface SplitControl;
    interface TknTschMcpsData as MCPS_DATA;
    interface TknTschMlmeBeacon as MLME_BEACON;
    interface TknTschMlmeBeaconNotify as MLME_BEACON_NOTIFY;
    interface McuPowerOverride;
    interface TknTschEvents;
  }
  uses {
//    interface Timer<TMilli> as Timer0;
//    interface Alarm<T32khz,uint32_t> as TssmAlarm32;

    interface McuPowerState;

    // PIB, Template, Schedule
    interface TknTschPib as Pib;
    interface TknTschTemplate as Template;
    interface TknTschSchedule as Schedule;
    interface Init as InitPib;
    interface Init as InitTemplate;
    interface Init as InitSchedule;

    // Radio
    //interface Plain154PhyTx<T32khz,uint32_t> as PhyTx;
    interface Plain154PhyTx<TSymbol,uint32_t> as PhyTx;
    interface Plain154PhyOff as PhyOff;
//    interface GetSet<uint8_t> as RadioChannel;
    interface Plain154PlmeSet as PLME_SET;

    // Frame handling
    interface Plain154Frame as Frame;
    interface Packet;
    interface Plain154Metadata as Metadata;
    interface TknTschMlmeSet as MLME_SET;
    interface TknTschMlmeGet as MLME_GET;
    interface TknTschFrames;
    interface TknTschInformationElement;

    interface Queue<message_t*> as AdvQueue;
    interface Queue<message_t*> as TxQueue;
    interface Queue<message_t*> as RxDataQueue;
    interface Queue<message_t*> as RxBeaconQueue;

    interface Pool<message_t> as AdvMsgPool;
    interface Pool<message_t> as RxMsgPool @safe();

    interface TknTschDebugHelperTssm as DebugHelper;

    // FSM event handlers
    interface TknFsmStateHandler as FsmInitHandler;
    interface TknFsmStateHandler as FsmInitDoneHandler;
    interface TknFsmStateHandler as IdleHandler;
    interface TknFsmStateHandler as SlotStartHandler;
    interface TknFsmStateHandler as SlotEndHandler;
    interface TknEventEmit as EventEmitter;
    interface TknTschSlotContext as SlotContextTx;
    interface TknTschSlotContext as SlotContextRx;
    interface TknFsm as fsm;
  }
}
implementation
{
  // Variables
  tkntsch_pib_t *MacPib;
  struct {
    uint32_t time;
    uint8_t error;
  } ErrorReport;
  tkntsch_slot_context_t context @safe();
  // TODO replace this with a beacon queue and pool
  //struct {
  //  message_t msg;
  //  plain154_txframe_t frame;
  //} m_beacon;
  uint8_t m_beaconstatus;
  struct {
    //message_t* msg;
    //plain154_txframe_t frame;
    uint8_t status;
    uint8_t handle;
  } m_data;
  const tknfsm_state_entry_t eventhandler_table[] = TSSM_EVENT_TABLE_INIT;

  bool m_mcuSleepAllowedNext = FALSE;
  bool m_mcuSleepAllowed = FALSE;

  // constants

  // Prototypes
  task void init();
  task void reportError();
  task void signalBeaconConfirm();
  task void signalDataConfirm();
  task void signalDataIndicate();
  task void signalBeaconIndicate();

  // Interface commands and events
  command error_t SplitControl.start()
  {
    T_LOG_INIT("TknTschTssmP starting...\n"); T_LOG_FLUSH;
    post init();
    return SUCCESS;
  }

  command error_t SplitControl.stop()
  {
    // TODO implement stopping the TSSM
    return FAIL;
  }

  static uint8_t get_slot_type(macLinkEntry_t* link) {
    // TODO check combinations
    if (link == NULL) {
      return TSCH_SLOT_TYPE_OFF;
    }
    if (link->macLinkType & PLAIN154E_LINK_TYPE_ADVERTISING) {
      if (call AdvQueue.empty() == FALSE)
        return TSCH_SLOT_TYPE_ADVERTISEMENT;
    }

    if (link->macLinkOptions & PLAIN154E_LINK_OPTION_TX) {
      if (call TxQueue.empty() == FALSE) {
        if (link->macLinkOptions & PLAIN154E_LINK_OPTION_SHARED) {
          return TSCH_SLOT_TYPE_SHARED;
        }
        else {
          return TSCH_SLOT_TYPE_TX;
        }
      }
    }

    if (link->macLinkOptions & PLAIN154E_LINK_OPTION_RX) {
      return TSCH_SLOT_TYPE_RX;
    }

    atomic T_LOG_ERROR("getSlotType(%u): Unhandled link option combination!\n",
        link->macTimeslot);
    return TSCH_SLOT_TYPE_OFF;
  }

  static uint8_t getSlotType(uint16_t timeslot)
  {
    macLinkEntry_t* link;

    link = call Schedule.getLink(timeslot);
    return get_slot_type(link);
  }

  uint16_t getCurrentTimeslot()
  {
    // TODO determine slotframe handle !
    atomic return MacPib->macASN % call Schedule.getSlotframeSize(0);
  }

  //TSSM_REPORT_ERROR(call TssmAlarm32.getNow(), TSCH_ERROR_UNHANDLED_ALARM_STATE); // TODO extend

  task void init()
  {
    uint8_t ret;
    ret = call fsm.setEventHandlerTable((tknfsm_state_entry_t*) eventhandler_table,
      sizeof(eventhandler_table) / sizeof(tknfsm_state_entry_t));
    if (ret != TKNFSM_STATUS_SUCCESS) {
      T_LOG_ERROR("Could not set the EventHandler table! Status: %d\n", ret);
      return;
    }

    atomic {
      m_mcuSleepAllowedNext = FALSE;
      m_mcuSleepAllowed = FALSE;
    }

    T_LOG_INIT("Size of the FSM table: %i\n", sizeof(eventhandler_table));

    call fsm.forceState(TKNFSM_STATE_INIT);
    call EventEmitter.emit(TKNFSM_EVENT_INIT);
  }

  async event void PhyTx.transmitDone(plain154_txframe_t *frame, error_t result) {}

  task void reportError()
  {
    call DebugHelper.setErrorIndicator();
    atomic {
      T_LOG_ERROR("ErrorReport [%lu] %u\n", ErrorReport.time, ErrorReport.error);
      ErrorReport.time = 0;
      ErrorReport.error = TSCH_ERROR_NONE;
    }
    T_LOG_FLUSH;
  }


  // FSM handlers

  task void initTssm() {
    // TODO these need to be called in a global one time init
    //call InitPib.init();
    call InitTemplate.init();
    call InitSchedule.init();
    // ...

    call DebugHelper.init();

    call EventEmitter.emit(TSCH_EVENT_INIT_DONE);
  }

  async event void FsmInitHandler.handle() {
    // TODO lock
    // TODO init variables
    atomic {
      ErrorReport.time = 0;
      ErrorReport.error = TSCH_ERROR_NONE;
    }
    // TODO need to set channel hopping method from the outside    call RadioChannel.set(APP_RADIO_CHANNEL);

    atomic {
      MacPib = call Pib.getPib();

      context.num_transmissions = 0;
    }

    post initTssm();
  }

  task void signalStartDone() {
    // TODO catch failures during init
    signal SplitControl.startDone(SUCCESS);
  }

  inline uint32_t getDt(uint32_t t0, uint32_t t1) {
    if (t0 < t1)
      return t1 - t0;
    else
      return ~(t0 - t1) + 1;

  }

  async event void FsmInitDoneHandler.handle() {
    bool isCoord;
    uint32_t slotlength_us;
    macTimeslotTemplate_t* tmpl;

    // print PIB and schedule
    T_LOG_FLUSH;
    //call Pib.printPib();
    //call Template.printTemplate();
    //call Schedule.printSchedule();

    // acquire current timeslot template (may change in SLOT_IDLE)
    tmpl = call Template.acquire(); // locks the template
    if (tmpl == NULL) {
      T_LOG_ERROR("Could not acquire the timeslot template!\n");
      T_LOG_FLUSH;
      return;
    }

    // schedule first slot
    // we're in SLOT_IDLE and coming from INIT

    // if this is a joining device
    atomic {
      isCoord = call MLME_GET.isCoordinator();
      slotlength_us = tmpl->macTsTimeslotLength;
    }

    if (isCoord == FALSE) {
      uint16_t txTemplateDelay_us, startDt_us;
      uint32_t syncTSStartReference_symbols;
      uint32_t syncTSStartToNowDt_symbols;
      uint32_t now_symbols;
      uint32_t timeIntoCurrentSlot_symbols;
      tkntsch_asn_t sync_asn, current_asn, start_asn;

      call EventEmitter.acquireReferenceTime();
      now_symbols = call PhyTx.getNow();

      txTemplateDelay_us = tmpl->macTsTxOffset;
      call Template.release();

      // This calculation is happening somewhere in the TS schedule of the beaconing device we synchronize to
      // thus we need to adjust to this running TS and therefore find out how much time passed in this TS until now

      // getting the TS start reference time by substracting the TS-TX offset time from RX time
      syncTSStartReference_symbols = (call MLME_GET.macBeaconSyncRxTimestamp()) - TSSM_SYMBOLS_FROM_US(txTemplateDelay_us);
      // next getting the delay between TS start reference and now
      syncTSStartToNowDt_symbols = getDt(syncTSStartReference_symbols, now_symbols);
      sync_asn = call MLME_GET.macASN();
      // with modulo operator we get the time that passed between the last TS start till now
      timeIntoCurrentSlot_symbols = syncTSStartToNowDt_symbols % TSSM_SYMBOLS_FROM_US(slotlength_us);
      // next get the current ASN of the TS we are in right now
      current_asn = sync_asn + (syncTSStartToNowDt_symbols / TSSM_SYMBOLS_FROM_US(slotlength_us));
      // defining the ASN and the start time delay (between reference time and the start TS)
      start_asn = current_asn + 2;  // +2 to be on the safe side if there is little time left in the current TS
      startDt_us = slotlength_us * 2;

      // the reference time (in us) that was set in the beginning needs to be adjusted to the actual TS start time
      // the -200 [us] is a compensation for delays that cannot be determined (delay between timestamps etc)
      call EventEmitter.substractFromReferenceTime(TSSM_SYMBOLS_TO_US(timeIntoCurrentSlot_symbols) + 200);
      // finally the ASN for the first needs to be set; since it is increased at slot start time it is decreased by 1
      call MLME_SET.macASN(start_asn - 1);

      call EventEmitter.scheduleEvent(TSCH_EVENT_START_SLOT, TSCH_DELAY_SHORT, startDt_us);
      call EventEmitter.addToReferenceTime(startDt_us);
    }

    // if this is the coordinator / DAG root
    else {
      // TODO implement coordinator behavior
      call EventEmitter.acquireReferenceTime();
      call EventEmitter.scheduleEvent(TSCH_EVENT_START_SLOT, TSCH_DELAY_SHORT, 101000);
    }

    call Template.release();
    post signalStartDone();
  }

  async event void IdleHandler.handle() {
    // just entered the idle state, coming from slot end
    uint32_t slotlength;
    int16_t correction;
    //uint8_t slottype;

    uint16_t slotFrameLength;
    uint16_t currSlotIndex;
    uint16_t slotIndex;
    uint16_t runningIndex = 0;
    uint16_t idleSlotCounter = 0;
    macLinkEntry_t* link;

    atomic {
      //slottype = context.slottype;
      correction = context.time_correction;
      slotlength = context.tmpl->macTsTimeslotLength;
      slotlength -= correction;
    }
    call Template.release();

    #ifdef TKN_TSCH_DISABLE_ACTIVE_FOR_ALL_SLOTS
      slotFrameLength = call Schedule.getSlotframeSize(0);
      currSlotIndex = getCurrentTimeslot();
      slotIndex = currSlotIndex + 1;

      while (runningIndex++ < TKN_TSCH_MAX_NUM_INACTIVE_SLOTS) {
        if (slotIndex >= slotFrameLength)
          slotIndex = 0;
        link = call Schedule.getLink(slotIndex++);
        if (link != NULL)
          break;
        idleSlotCounter++;
      }
      if (idleSlotCounter > 1) {
        atomic {
          idleSlotCounter -= 1; // TODO: waking up one slot early to allow clcks to stabilize
          slotlength += context.tmpl->macTsTimeslotLength * idleSlotCounter;
          MacPib->macASN += idleSlotCounter;
          m_mcuSleepAllowedNext = TRUE;
        }
      } else
        atomic m_mcuSleepAllowedNext = FALSE;
    #endif

    if (correction != 0)
      T_LOG_TIME_CORRECTION("TimeCorrection: %dus\n", correction);

    call EventEmitter.scheduleEvent(TSCH_EVENT_START_SLOT, TSCH_DELAY_SHORT, slotlength);
    call EventEmitter.addToReferenceTime(slotlength);
    // NOTE later power management could be done here
    // NOTE also changes to the PIB and some MLME handling should happen here

    T_LOG_FLUSH;

    atomic {
      if (m_mcuSleepAllowed != m_mcuSleepAllowedNext)
        call McuPowerState.update();
      m_mcuSleepAllowed = m_mcuSleepAllowedNext;
    }
  }

  async event void SlotStartHandler.handle() {
    uint32_t tsStartRadio_symbols;
    int32_t nowToTsStartDt_us;
    macLinkEntry_t* link;
    uint16_t timeslot;
    uint8_t slottype;
    macTimeslotTemplate_t* tmpl;
    uint8_t ret;

    // reference time stamps
    tsStartRadio_symbols = call PhyTx.getNow();
    // difference between scheduled TS start time and now (interrupt delay, etc)
    nowToTsStartDt_us = call EventEmitter.getReferenceToNowDt();
    call DebugHelper.startOfSlotStart();
    // correct radio timestamp to exact start of TS
    tsStartRadio_symbols = tsStartRadio_symbols - TSSM_SYMBOLS_FROM_US(nowToTsStartDt_us);

    atomic {
      MacPib = call Pib.getPib();// context.macpib;
      TKNTSCH_ACQUIRE_LOCK(MacPib->lock, ret);
    }
    if (ret == FALSE) {
      // TODO log
      atomic T_LOG_ERROR("SLOT_START: Couldn't acquire the MacPib lock!\n");
      call EventEmitter.scheduleEvent(TSCH_EVENT_END_SLOT,
          TSCH_DELAY_IMMEDIATE, 0);
      call DebugHelper.endOfSlotStart();
      return;
    }

    // acquire current timeslot template (may change in SLOT_IDLE)
    tmpl = call Template.acquire(); // locks the template
    if (tmpl == NULL) {
      // TODO handle error when trying to acquire the template
      // TODO log error
      call EventEmitter.scheduleEvent(TSCH_EVENT_END_SLOT,
          TSCH_DELAY_IMMEDIATE, 0);
      call DebugHelper.endOfSlotStart();
      return;
    }

    atomic MacPib->macASN++;
    timeslot = getCurrentTimeslot();
    link = call Schedule.getLink(timeslot);
    slottype = get_slot_type(link);

    if (slottype != TSCH_SLOT_TYPE_OFF) {
      atomic {
        uint32_t asn = (uint32_t) (MacPib->macASN);
        signal TknTschEvents.asn(&asn);
        T_LOG_ACTIVE_SLOT_INFO("@\n");
        T_LOG_FLUSH;
        T_LOG_ACTIVE_SLOT_INFO("ASN: %u\n", (uint32_t) (MacPib->macASN));
      }
    }

    if (timeslot == 0) {
      call DebugHelper.startOfSlotZero();
    }

    // write data to the context
    // TODO lock the context instead?
    atomic {
      context.frame = NULL;
      context.radio_t0 = tsStartRadio_symbols;
      context.timeslot = timeslot;
      context.link = link;
      context.slottype = slottype;
      context.tmpl = tmpl;
      context.time_correction = 0;
      context.macpib = MacPib;
      context.macASN = MacPib->macASN;
      context.joinPriority = call MLME_GET.macJoinPriority();

      // clear all flags to false
      for (ret = 0; ret < sizeof(context.flags); ret++) {
        ((uint8_t*)&context.flags)[ret] = 0x0;
      }
    }

    // Backoff scheme for shared slots
    atomic {
      if ((link != NULL) && (link->macLinkOptions & PLAIN154E_LINK_OPTION_SHARED)) {
        // link options necessary because all transmissions need to be delayed in shared slots (also advertisements)
        if (context.numBackoffSlots == INVALID_BACKOFF) {
          uint8_t be = context.macBE;
          context.numBackoffSlots = tsStartRadio_symbols % (((1 << be) -1) + 1);  // TODO: improve this pseudo random function
        }
        if (context.numBackoffSlots == 0) {
          context.numBackoffSlots = INVALID_BACKOFF;
        } else {
          T_LOG_COLLISION_AVOIDANCE("==>> %u (be: %u) \n", context.numBackoffSlots, context.macBE);
          context.numBackoffSlots -= 1;
          // Backoff active, overriding slot purpose to RX only
          slottype = TSCH_SLOT_TYPE_RX;
          context.slottype = slottype;
        }
      }
    }

    // Radio channel setting
    if (link != NULL) {
      atomic {
        context.channel = MacPib->macHoppingSequenceList[(context.macASN + link->macChannelOffset) % MacPib->macHoppingSequenceLength];
        call PLME_SET.phyCurrentChannel(context.channel);
      }
    }

    switch (slottype) {
      case TSCH_SLOT_TYPE_OFF:
        call DebugHelper.clearActiveSlotIndicator();
        call EventEmitter.scheduleEvent(TSCH_EVENT_END_SLOT,
            TSCH_DELAY_IMMEDIATE, 0);
        call DebugHelper.endOfSlotStart();
        return;
        break;

      case TSCH_SLOT_TYPE_ADVERTISEMENT:
        call DebugHelper.setActiveSlotIndicator();
        call EventEmitter.scheduleEvent(TSCH_EVENT_INIT_ADV,
            TSCH_DELAY_IMMEDIATE, 0);

        // the next handler will be in another module
        ret = call SlotContextTx.passContext(&context);
        if (ret != TKNTSCH_SUCCESS) {
          // end the slot
          // TODO log error
          call EventEmitter.scheduleEvent(TSCH_EVENT_END_SLOT,
              TSCH_DELAY_IMMEDIATE, 0);
        }

        // TODO pass the radio token
        break;

      case TSCH_SLOT_TYPE_SHARED:
      case TSCH_SLOT_TYPE_TX:
        call DebugHelper.setActiveSlotIndicator();
        call EventEmitter.scheduleEvent(TSCH_EVENT_INIT_TX,
            TSCH_DELAY_IMMEDIATE, 0);

        // the next handler will be in another module
        ret = call SlotContextTx.passContext(&context);
        if (ret != TKNTSCH_SUCCESS) {
          // end the slot
          // TODO log error
          call EventEmitter.scheduleEvent(TSCH_EVENT_END_SLOT,
              TSCH_DELAY_IMMEDIATE, 0);
        }

        // TODO pass the radio token
        break;

      case TSCH_SLOT_TYPE_RX:
        call DebugHelper.setActiveSlotIndicator();
        call EventEmitter.scheduleEvent(TSCH_EVENT_INIT_RX,
            TSCH_DELAY_IMMEDIATE, 0);

        // the next handler will be in another module
        ret = call SlotContextRx.passContext(&context);
        if (ret != TKNTSCH_SUCCESS) {
          // end the slot
          // TODO log error
          call EventEmitter.scheduleEvent(TSCH_EVENT_END_SLOT,
              TSCH_DELAY_IMMEDIATE, 0);
        }

        // TODO pass the radio token
        break;

      default:
        // TODO use error report instead of printf
        atomic T_LOG_WARN("handleSlotStart: ASN: %lu, timeslot: %u, slottype: %u -> slottype is unknown -> OFF\n", (uint32_t) MacPib->macASN, timeslot, slottype);
        call EventEmitter.scheduleEvent(TSCH_EVENT_END_SLOT, TSCH_DELAY_IMMEDIATE, 0);
        break;
    }

    call DebugHelper.endOfSlotStart();
  }

  async event void PhyOff.offDone() {
    ;
  }

  async event void SlotEndHandler.handle() {
    uint8_t slottype;
    bool confirm_beacon;
    bool confirm_data;
    error_t status;
    // TODO revoke all slot contexts to be sure
    call SlotContextTx.revokeContext();

    status =  call PhyOff.off();
    if (status != SUCCESS) {
      if (status == EALREADY)
        T_LOG_WARN("Switching radio off failed (already off)!\n");
      else {
        T_LOG_ERROR("Radio off error!!!\n");
      }
    }

    // call Template.release(); -> happens in the idle handler

    atomic {
      TKNTSCH_RELEASE_LOCK(MacPib->lock);

      if (context.timeslot == 0) {
        call DebugHelper.endOfSlotZero();
      }
      slottype = context.slottype;
    }


    switch (slottype) {
      case TSCH_SLOT_TYPE_OFF:
        // nothing to do
        //atomic T_LOG_INFO("OFF ended [0x%X]\n", (uint32_t)asn);
        break;

      case TSCH_SLOT_TYPE_ADVERTISEMENT:
        atomic {
          confirm_beacon = context.flags.confirm_beacon;
          if (confirm_beacon) {
            if (context.flags.success == TRUE) {
              m_beaconstatus = TKNTSCH_SUCCESS;
            }
            else {
              // TODO check what to return
              m_beaconstatus = TKNTSCH_INTERNAL_ERROR;
            }
            // Adv. messages are generated by the TSCH layer, so free the buffer
            if ((context.flags.inactive_slot == FALSE) && (context.frame != NULL)) {
              call AdvMsgPool.put(context.frame);
            }
          }
        }
        if (confirm_beacon) post signalBeaconConfirm();
        //atomic T_LOG_INFO("ADV ended [0x%X]\n", (uint32_t)asn);
        break;

      case TSCH_SLOT_TYPE_SHARED:
        //atomic T_LOG_SLOT_STATE("Shared ");
      case TSCH_SLOT_TYPE_TX:
        //atomic T_LOG_SLOT_STATE("TX ended [0x%X]\n", (uint32_t)asn);
        // TODO handle TX slots
        atomic {
          confirm_data = context.flags.confirm_data;
          if (confirm_data) {
            m_data.handle = 0; // TODO pass TX frame handle !
            if (context.flags.success == TRUE) {
              m_data.status = TKNTSCH_SUCCESS;
            }
            else {
              // TODO check what to return
              m_data.status = TKNTSCH_INTERNAL_ERROR;
            }
          }
        }
        if (confirm_data) post signalDataConfirm();
        break;

      case TSCH_SLOT_TYPE_RX:
        //atomic T_LOG_SLOT_STATE("RX ended [0x%X]\n", (uint32_t)asn);
        // TODO handle RX slots
        atomic {
          if (context.flags.indicate_data) {
            post signalDataIndicate();
          } else if (context.flags.indicate_beacon) {
            post signalBeaconIndicate();
          }
        }
        break;

      default:
        atomic T_LOG_WARN("SLOT_END: Unhandled slot type 0x%x\n", slottype);
    }

    //atomic {LOG_DEBUG("Ending test run at SLOT_END...\n"); T_LOG_FLUSH;} return;

    call EventEmitter.scheduleEvent(TSCH_EVENT_SLOT_ENDED,
        TSCH_DELAY_IMMEDIATE, 0);

    call DebugHelper.clearActiveSlotIndicator();
  }

  async command mcu_power_t McuPowerOverride.lowestState() {
   #ifdef TKN_TSCH_DISABLE_SLEEP
    return JN516_POWER_ACTIVE;
   #else
    atomic if (!m_mcuSleepAllowed) {
      return JN516_POWER_ACTIVE;
    }
    call PhyOff.off();
    return JN516_POWER_SLEEP;
   #endif
  }

  command plain154_status_t MLME_BEACON.request (
      uint8_t BeaconType,
      uint8_t Channel,
      uint8_t ChannelPage,
      plain154_security_t *beaconSecurity,
      uint8_t DstAddrMode,
      plain154_address_t *DstAddr,
      bool BSNSuppression
    )
  {
    uint8_t ret;
    message_t* msg;

    // TODO check arguments
    // TODO check whether TSSM is running and in sync

    if (BeaconType != TKNTSCH_BEACON_TYPE_BEACON)
      return TKNTSCH_NOT_IMPLEMENTED_YET;

    atomic {
      if ((call AdvQueue.full() == TRUE) || (call AdvMsgPool.empty() == TRUE)) {
        return TKNTSCH_BUSY;
      }

      msg = call AdvMsgPool.get();
    }

    call Packet.clear(msg);

    ret = call TknTschFrames.createEnhancedBeaconFrame(
        msg,
        NULL, // the txframe_t is only needed in TssmTxP
        NULL, // don't need the payload length now
        TRUE, // include SyncIE
        TRUE, // include Timeslot Template IE
        TRUE, // include Hopping Sequence IE
        TRUE  // include Slotframe & Link IE
      );
    if (ret != TKNTSCH_SUCCESS) {
      T_LOG_ERROR("TssmP: Beacon frame creation failed!\n");
    }

    // that's it
    atomic ret = call AdvQueue.enqueue(msg);
    T_LOG_BUFFERING("ADV queue: %i/%i\n", call AdvQueue.size(), call AdvQueue.maxSize());
    if (ret == SUCCESS) {
      return TKNTSCH_SUCCESS;
    }
    else {
      return TKNTSCH_TRANSACTION_OVERFLOW;
    }
  }

  task void signalBeaconConfirm()
  {
    uint8_t status;
    atomic status = m_beaconstatus;
    signal MLME_BEACON.confirm(status);
  }

  // --- MCPS ---
  // this only requires the payload to be set via the packet interface
  command plain154_status_t MCPS_DATA.request(
      uint8_t SrcAddrMode,
      uint8_t DstAddrMode,
      uint16_t DstPANId,
      plain154_address_t *DstAddr,
      message_t* msg,
      uint8_t msduHandle,
      uint8_t AckTX,
      uint8_t SecurityLevel,
      uint8_t KeyIdMode,
      plain154_sec_keysource_t KeySource,
      uint8_t KeyIndex
    )
  {
    uint8_t ret;
    plain154_header_t* header;
    plain154_metadata_t* metadata;
    uint16_t srcpan;
    plain154_address_t SrcAddr;


    // security is not implemented
    if (SecurityLevel != 0)
      return PLAIN154_INVALID_PARAMETER;

    // TODO check msduLength

    atomic {
      if (call TxQueue.full() == TRUE)
        return TKNTSCH_BUSY;
    }

    // prepare the frame structure
    header = call Frame.getHeader(msg);
    metadata = call Metadata.getMetadata(msg);

    metadata->transmissions = 0;

    // TODO check return values

    // assemble data frame
    // TODO call the right frame creation function instead
    srcpan = call MLME_GET.macPanId();
    if (SrcAddrMode == PLAIN154_ADDR_SHORT)
      SrcAddr.shortAddress = call MLME_GET.macShortAddr();
    else
      SrcAddr.extendedAddress = call MLME_GET.macExtAddr();
    ret = call Frame.setAddressingFields(header,
        SrcAddrMode,
        DstAddrMode,
        srcpan,
        DstPANId,
        &SrcAddr,
        DstAddr,
        PLAIN154_FRAMEVERSION_2,
        FALSE
      );
    // TODO check result
    call Frame.setFrameType(header, PLAIN154_FRAMETYPE_DATA);
    call Frame.setAckRequest(header, AckTX);
    call Frame.setFramePending(header, FALSE);
    call Frame.setIEListPresent(header, FALSE); // TODO for now

    // that's it
    atomic ret = call TxQueue.enqueue(msg);
    T_LOG_BUFFERING("TX queue: %i/%i\n", call TxQueue.size(), call TxQueue.maxSize());
    if (ret == SUCCESS) {
      return TKNTSCH_SUCCESS;
    }
    else {
      return TKNTSCH_TRANSACTION_OVERFLOW;
    }

    return PLAIN154_SUCCESS;
  }

  task void signalDataConfirm()
  {
    uint8_t status;
    uint8_t handle;
    atomic {
      status = m_data.status;
      handle = m_data.handle;
    }
    signal MCPS_DATA.confirm(handle, status);
  }

  task void signalDataIndicate()
  {
    uint8_t queue_size;
    message_t *msg;
    atomic {
      queue_size = call RxDataQueue.size();
      msg = call RxDataQueue.dequeue();
    }

    if (queue_size <= 0) {
      T_LOG_WARN("task signalDataIndicate: empty queue.\n");
      return;
    }

    // TODO retrieve link quality

    // TODO retrieve security information

    signal MCPS_DATA.indication(msg, 127, 0, 0, 0, 0);
    call RxMsgPool.put(msg);

    T_LOG_BUFFERING("RX queue: %i/%i\n", call RxDataQueue.size(), call RxDataQueue.maxSize());
    atomic {
      queue_size = call RxDataQueue.size();
    }

    if (queue_size > 0) {
      post signalDataIndicate();
    }
  }

  task void signalBeaconIndicate()
  {
    uint8_t queue_size;
    message_t *msg;
    atomic {
      queue_size = call RxBeaconQueue.size();
      msg = call RxBeaconQueue.dequeue();
    }

    if (queue_size <= 0) {
      T_LOG_WARN("task signalBeaconIndicate: empty queue.\n");
      return;
    }

    // TODO retrieve link quality

    // TODO retrieve security information

    signal MLME_BEACON_NOTIFY.indication(msg);
    call RxMsgPool.put(msg);

    atomic {
      queue_size = call RxBeaconQueue.size();
    }

    if (queue_size > 0) {
      post signalBeaconIndicate();
    }
  }

  default event void MCPS_DATA.confirm(
      uint8_t msduHandle,
      plain154_status_t status
    ) {}

  default event void MCPS_DATA.indication(
      message_t* msg,
      uint8_t mpduLinkQuality,
      uint8_t SecurityLevel,
      uint8_t KeyIdMode,
      plain154_sec_keysource_t KeySource,
      uint8_t KeyIndex
/*
      uint8_t SrcAddrMode,
      uint16_t SrcPANId,
      plain154_address_t SrcAddr,
      uint8_t DstAddrMode,
      uint16_t DstPANId,
      plain154_address_t DstAddr,
      uint8_t msduLength,
      void* msdu,
      uint8_t mpduLinkQuality,
      uint8_t DSN,
      uint8_t SecurityLevel,
      uint8_t KeyIdMode,
      plain154_sec_keysource_t KeySource,
      uint8_t KeyIndex
*/
    ) {}

  default event message_t* MLME_BEACON_NOTIFY.indication(message_t* beaconFrame){
    return beaconFrame;
  }

  default async event void TknTschEvents.asn(uint32_t* asn) {}

}
