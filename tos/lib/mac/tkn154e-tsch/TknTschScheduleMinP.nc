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
 * ========================================================================
 */

#include "TknTschConfigLog.h"
//ifndef TKN_TSCH_LOG_ENABLED_SCHEDULE_MIN
//undef TKN_TSCH_LOG_ENABLED
//endif
#include "tkntsch_log.h"

#include "tkntsch_pib.h"
#include "static_config.h" // slotframe and template

#include "plain154_values.h"

module TknTschScheduleMinP
{
  provides {
    interface TknTschSchedule as Schedule;
    interface Init;
    interface TknTschMlmeSetLink;
    interface Compare<macSlotframeEntry_t*> as SFCompare;
    interface Compare<macLinkEntry_t*> as LinkCompare;
  } uses {
    interface Queue<macSlotframeEntry_t*> as SFQueue;
    interface Queue<macLinkEntry_t*> as LinkQueue;
    interface LinkedList<macLinkEntry_t*> as LinkLinkedList;
    interface LinkedList<macSlotframeEntry_t*> as SFLinkedList;
    interface Pool<macSlotframeEntry_t> as SFPool;
    interface Pool<macLinkEntry_t> as LinkPool;
  }
}
implementation
{

  // Tasks
  task void signalSetLinkConfirmTask();
  task void printSchedule();

  // Variables
  bool m_busy = FALSE;
  tkntsch_slotframe_operation_t m_currentLinkOperationResult;
  uint16_t m_currentLinkHandle;
  uint8_t m_currentSFHandle;


  // constants

  const macSlotframeEntry_t min_6tsch_slotframe
        = TKNTSCH_SLOTFRAME_6TSCH_DEFAULT_INITIALIZER();
  uint16_t m_uniqueLinkHandle = 0;
  //const uint16_t slotframe_active_slots = TKNTSCH_SLOTFRAME_6TSCH_DEFAULT_ACTIVE_SLOTS;

/*
  static const plain154_full_address_t BROADCAST_CELL_ADDRESS = TKNTSCH_BROADCAST_CELL_ADDRESS();
  static const plain154_full_address_t EB_CELL_ADDRESS =        TKNTSCH_EB_CELL_ADDRESS();
  static const plain154_full_address_t CELL_ADDRESS1 =          TKNTSCH_CELL_ADDRESS1();
  static const plain154_full_address_t CELL_ADDRESS2 =          TKNTSCH_CELL_ADDRESS2();
  static const plain154_full_address_t CELL_ADDRESS3 =          TKNTSCH_CELL_ADDRESS3();
*/
//  static const macLinkEntry_t generic_shared_cell =     TKNTSCH_GENERIC_SHARED_CELL();
//  static const macLinkEntry_t generic_eb_cell =         TKNTSCH_GENERIC_EB_CELL();
/*
  static const macLinkEntry_t min_6tsch_links[10] //TKNTSCH_SLOTFRAME_6TSCH_DEFAULT_ACTIVE_SLOTS]
      = {// handle, link option, slotframe, addr, slot offset, channel offset
          { 0, PLAIN154E_LINK_OPTION_TX, PLAIN154E_LINK_TYPE_ADVERTISING, 0, TKNTSCH_EB_CELL_ADDRESS(), 0, 0 },
          { 1, PLAIN154E_LINK_OPTION_TX | PLAIN154E_LINK_OPTION_RX | PLAIN154E_LINK_OPTION_SHARED,
              PLAIN154E_LINK_TYPE_NORMAL, 0, TKNTSCH_BROADCAST_CELL_ADDRESS(), 1, 0 },
          { 2, PLAIN154E_LINK_OPTION_TX | PLAIN154E_LINK_OPTION_RX | PLAIN154E_LINK_OPTION_SHARED,
            PLAIN154E_LINK_TYPE_NORMAL, 0, TKNTSCH_CELL_ADDRESS1(), 2, 0 },
          { 3, PLAIN154E_LINK_OPTION_TX | PLAIN154E_LINK_OPTION_RX | PLAIN154E_LINK_OPTION_SHARED,
            PLAIN154E_LINK_TYPE_NORMAL, 0, TKNTSCH_CELL_ADDRESS2(), 3, 0 },
          { 4, PLAIN154E_LINK_OPTION_TX | PLAIN154E_LINK_OPTION_RX | PLAIN154E_LINK_OPTION_SHARED,
            PLAIN154E_LINK_TYPE_NORMAL, 0, TKNTSCH_CELL_ADDRESS3(), 4, 0 },
          { 5, PLAIN154E_LINK_OPTION_TX | PLAIN154E_LINK_OPTION_RX | PLAIN154E_LINK_OPTION_SHARED,
            PLAIN154E_LINK_TYPE_NORMAL, 0, TKNTSCH_BROADCAST_CELL_ADDRESS(), 5, 0 },
          { 0, PLAIN154E_LINK_OPTION_TX | PLAIN154E_LINK_OPTION_RX | PLAIN154E_LINK_OPTION_SHARED | PLAIN154E_LINK_OPTION_TIMEKEEPING,
            PLAIN154E_LINK_TYPE_ADVERTISING, 0, TKNTSCH_EB_CELL_ADDRESS(), 0, 0 },
          //{ 1, PLAIN154E_LINK_OPTION_RX | PLAIN154E_LINK_OPTION_TIMEKEEPING, PLAIN154E_LINK_TYPE_NORMAL, 0, TKNTSCH_CELL_BOARD1(), 1, 0 },
          { 1, PLAIN154E_LINK_OPTION_TX | PLAIN154E_LINK_OPTION_TIMEKEEPING, PLAIN154E_LINK_TYPE_NORMAL, 0, TKNTSCH_CELL_BOARD2(), 1, 0 },
        };
*/



  // Prototypes

  // Interface commands and events

  command error_t Init.init()
  {
    plain154_full_address_t addi = TKNTSCH_EB_CELL_ADDRESS();
    uint8_t result;
    m_busy = FALSE;

    // TODO: Remove this once SFPool is used and TSCH-interface in place
    call SFQueue.enqueue(&min_6tsch_slotframe);

    if (call SFQueue.size() != 1)
      T_LOG_ERROR("Schedule has incorrect length after adding one line!\n");

    result = call TknTschMlmeSetLink.request(PLAIN154E_ADD_LINK,
                            0,
                            0,
                            0,
                            0,
                            PLAIN154E_LINK_OPTION_TX | PLAIN154E_LINK_OPTION_RX | PLAIN154E_LINK_OPTION_SHARED | PLAIN154E_LINK_OPTION_TIMEKEEPING,
                            PLAIN154E_LINK_TYPE_ADVERTISING,
                            &addi
                            );
    if (result != PLAIN154_SUCCESS) {
      T_LOG_ERROR("Adding TknTschScheduleMinP slot failed (%u)\n", result);
    }
    T_LOG_INIT("Init. TknTschScheduleMinP (1)\n"); T_LOG_FLUSH;

    return SUCCESS;
  }

  async command macLinkEntry_t* Schedule.getLink(/*uint8_t slotframeHandle,*/uint16_t timeslot)
  {
    uint16_t j;
    uint8_t slotframeHandle = 0; // TODO: Remove once parameter is introduced
    macLinkEntry_t* linkPtr;
    uint8_t linkQueueSize = call LinkQueue.size();
    // TODO: Fix this static 0 SF selection here and introduce it as a parameter
    for (j=0; j<linkQueueSize; j++) {
      linkPtr = call LinkQueue.element(j);
      //printf(" -  %u %u (%p): %u==%u %u==%u\n",j, linkQueueSize,linkPtr,    linkPtr->sfHandle, slotframeHandle,    linkPtr->macTimeslot, timeslot);
      if ((linkPtr->sfHandle) == slotframeHandle)
        if ((linkPtr->macTimeslot) == timeslot)
          return linkPtr;
    }
    return (macLinkEntry_t*) NULL;
  }

  async command uint16_t Schedule.getSlotframeSize(uint8_t handle)
  {
    uint16_t i, size;
    macSlotframeEntry_t* ptr;
    size = call SFQueue.size();
    for (i=0; i<size; i++) {
      ptr = call SFQueue.element(i);
      if (handle == ptr->macSlotframeHandle)
        return ptr->macSlotframeSize;
    }
    return 0;
    //return min_6tsch_slotframe.macSlotframeSize;
  }

  command bool SFCompare.equal(macSlotframeEntry_t* elem1, macSlotframeEntry_t* elem2) {
    if (elem1 == elem1)
        return TRUE;
    return FALSE;
  }

  command bool LinkCompare.equal(macLinkEntry_t* elem1, macLinkEntry_t* elem2) {
    if (elem1 == elem1)
        return TRUE;
    return FALSE;
  }

  task void signalSetLinkConfirmTask() {
    atomic m_busy = FALSE;
    signal TknTschMlmeSetLink.confirm(m_currentLinkOperationResult, m_currentLinkHandle, m_currentSFHandle);
  }

  command plain154_status_t TknTschMlmeSetLink.request  (
                          tkntsch_slotframe_operation_t  Operation,
                          uint16_t LinkHandle,
                          uint8_t  sfHandle,
                          uint16_t Timeslot,
                          uint8_t  ChannelOffset,
                          uint8_t  LinkOptions,
                          tkntsch_link_type_t  LinkType,
                          plain154_full_address_t* NodeAddr
                        ) {
    uint8_t i;
    macSlotframeEntry_t* sfPtr;
    atomic {
      if (m_busy) {
        return PLAIN154_BUSY;
      } else {
        m_busy = TRUE;
      }
    }

    if (Operation != PLAIN154E_ADD_LINK)
      return PLAIN154_NOT_IMPLMENTED_YET;

    m_currentLinkHandle = LinkHandle;
    m_currentSFHandle = sfHandle;

    if (call Schedule.getSlotframeSize(sfHandle) == 0)
      return PLAIN154_INVALID_PARAMETER;

    if (!call LinkPool.empty()) {
      macLinkEntry_t* linkPtr;
      macLinkEntry_t* checkLinkPtr;
      uint8_t linkQueueSize;
      linkPtr = call LinkPool.get();
      linkPtr->macLinkHandle = m_uniqueLinkHandle++;
      linkPtr->macLinkOptions = LinkOptions;
      linkPtr->macLinkType = (uint8_t) LinkType;
      linkPtr->sfHandle = sfHandle;

      if (NodeAddr->mode == PLAIN154_ADDR_SHORT) {
        linkPtr->macNodeAddress.addr.shortAddress = NodeAddr->addr.shortAddress;
      } else if (NodeAddr->mode == PLAIN154_ADDR_EXTENDED) {
        memcpy((uint8_t *) &linkPtr->macNodeAddress.addr.extendedAddress, (uint8_t *)&NodeAddr->addr.extendedAddress, 8);
      } else {
        // TODO: Catch other addr mode cases
      }
      linkPtr->macNodeAddress.mode = NodeAddr->mode;
      linkPtr->macTimeslot = Timeslot;
      linkPtr->macChannelOffset = ChannelOffset;

      // Check for link collisions
      atomic linkQueueSize = call LinkQueue.size();
      for (i=0; i < linkQueueSize; i++) {
        atomic checkLinkPtr = call LinkQueue.element(i);
        if ((checkLinkPtr->sfHandle) == sfHandle)
          if ((checkLinkPtr->macTimeslot) == Timeslot)
            if ((checkLinkPtr->macChannelOffset) == ChannelOffset)
              // Collision found!
              // TODO: Check if the return value is valid or if we need a better one
              return PLAIN154_INVALID_PARAMETER;
      }
      atomic {
        if (call LinkQueue.enqueue(linkPtr) != SUCCESS) {
          call LinkPool.put(linkPtr);
          // Should not happen, if pool and queue have same size
          m_currentLinkOperationResult = TKNTSCH_MAX_LINKS_EXCEEDED;
          post signalSetLinkConfirmTask();
        }
      }
      m_currentLinkOperationResult = TKNTSCH_SUCCESS;
      post signalSetLinkConfirmTask();
    } else {
      m_currentLinkOperationResult = TKNTSCH_MAX_LINKS_EXCEEDED;
      post signalSetLinkConfirmTask();
    }

    printf("LinkQueueSize (%u)\n", call LinkQueue.size());

    return PLAIN154_SUCCESS;
  }


  task void printSchedule()
  {
#ifdef TKN_TSCH_LOG_DEBUG
    volatile uint32_t tmp;
    uint8_t* ptmp;
    uint16_t slotframe_active_slots = call Schedule.getSlotframeSize(0);
    int i = 0;
    // TODO should all data be copied?
    macLinkEntry_t* link;
    T_LOG_DEBUG("macSlotframeTable\n  handle\tsize\n  %u\t%u\n",
        min_6tsch_slotframe.macSlotframeHandle, min_6tsch_slotframe.macSlotframeSize);
    T_LOG_DEBUG("macLinkTable\n  handle\toptions\ttype\tframe\taddr\t\t\t\tslot\tchannel\n");
    for (i = 0; i < slotframe_active_slots; i++) {
      link = call Schedule.getLink(i);
      ptmp = (uint8_t*) &link->macNodeAddress.addr;
      T_LOG_DEBUG("  %u\t\t", link->macLinkHandle);
      T_LOG_DEBUG("  %x\t", link->macLinkOptions);
      T_LOG_DEBUG("  %u\t", link->macLinkType);
      T_LOG_DEBUG("  %u\t", link->sfHandle);
      T_LOG_DEBUG("  (%u): %.2x %.2x %.2x %.2x %.2x %.2x %.2x %.2x\t", link->macNodeAddress.mode,
          ptmp[0], ptmp[2], ptmp[3],
          ptmp[3], ptmp[4], ptmp[5],
          ptmp[6], ptmp[7]);
      T_LOG_DEBUG("  %u\t", link->macTimeslot);
      T_LOG_DEBUG("  %u\n", link->macChannelOffset);
      T_LOG_FLUSH;
      for (tmp = 0; tmp < 300000; tmp++) {}
    }
#endif
  }

  default event void TknTschMlmeSetLink.confirm(
                          tkntsch_status_t  Status,
                          uint16_t LinkHandle,
                          uint8_t  sfHandle
                        ) {}

  async command void Schedule.printSchedule() { post printSchedule(); }

}
