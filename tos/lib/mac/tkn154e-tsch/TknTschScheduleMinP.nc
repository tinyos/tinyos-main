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

#ifdef NEW_PRINTF_SEMANTICS
#include "printf.h"
#else
#define printf(...)
#define printfflush()
#endif

#include "tkntsch_pib.h"
#include "static_config.h" // slotframe and template

#include "plain154_values.h"

module TknTschScheduleMinP
{
  provides {
    interface TknTschSchedule as Schedule;
    interface Init;
  }
}
implementation
{
  // Variables
  const macSlotframeEntry_t min_6tsch_slotframe
        = TKNTSCH_SLOTFRAME_6TSCH_DEFAULT_INITIALIZER();
  const uint16_t slotframe_active_slots = TKNTSCH_SLOTFRAME_6TSCH_DEFAULT_ACTIVE_SLOTS;

/*
  static const plain154_full_address_t BROADCAST_CELL_ADDRESS = TKNTSCH_BROADCAST_CELL_ADDRESS();
  static const plain154_full_address_t EB_CELL_ADDRESS =        TKNTSCH_EB_CELL_ADDRESS();
  static const plain154_full_address_t CELL_ADDRESS1 =          TKNTSCH_CELL_ADDRESS1();
  static const plain154_full_address_t CELL_ADDRESS2 =          TKNTSCH_CELL_ADDRESS2();
  static const plain154_full_address_t CELL_ADDRESS3 =          TKNTSCH_CELL_ADDRESS3();
*/
//  static const macLinkEntry_t generic_shared_cell =     TKNTSCH_GENERIC_SHARED_CELL();
//  static const macLinkEntry_t generic_eb_cell =         TKNTSCH_GENERIC_EB_CELL();
  static const macLinkEntry_t min_6tsch_links[] //TKNTSCH_SLOTFRAME_6TSCH_DEFAULT_ACTIVE_SLOTS]
      = {// handle, link option, slotframe, addr, slot offset, channel offset
/*
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
*/
          { 0, PLAIN154E_LINK_OPTION_TX | PLAIN154E_LINK_OPTION_RX | PLAIN154E_LINK_OPTION_SHARED | PLAIN154E_LINK_OPTION_TIMEKEEPING,
            PLAIN154E_LINK_TYPE_ADVERTISING, 0, TKNTSCH_EB_CELL_ADDRESS(), 0, 0 },
          { 1, PLAIN154E_LINK_OPTION_TX | PLAIN154E_LINK_OPTION_RX | PLAIN154E_LINK_OPTION_SHARED | PLAIN154E_LINK_OPTION_TIMEKEEPING,
            PLAIN154E_LINK_TYPE_ADVERTISING, 0, TKNTSCH_EB_CELL_ADDRESS(), 1, 0 },
        };

  // constants

  // Prototypes

  // Interface commands and events
  command error_t Init.init()
  {
    printf("Initializing TknTschScheduleMinP\n"); printfflush();
    return SUCCESS;
  }

  async command macLinkEntry_t* Schedule.getLink(uint16_t timeslot)
  {
    uint16_t slot_index = 0;
    while (slot_index < slotframe_active_slots) {
      if (min_6tsch_links[slot_index].macTimeslot < timeslot) {
        slot_index++;
      } else if (min_6tsch_links[slot_index].macTimeslot == timeslot) {
        return (macLinkEntry_t*) &min_6tsch_links[slot_index];
      } else {
        break;
      }
    }
    return (macLinkEntry_t*) NULL;
  }

  async command uint16_t Schedule.getSlotframeSize(uint8_t handle)
  {
    return min_6tsch_slotframe.macSlotframeSize;
  }

  task void printSchedule()
  {
#ifdef NEW_PRINTF_SEMANTICS
    volatile uint32_t tmp;
    uint8_t* ptmp;
    int i = 0;
    // TODO should all data be copied?
    macLinkEntry_t* link;
    printf("macSlotframeTable\n  handle\tsize\n  %u\t%u\n",
        min_6tsch_slotframe.macSlotframeHandle, min_6tsch_slotframe.macSlotframeSize);
    printf("macLinkTable\n  handle\toptions\ttype\tframe\taddr\t\t\t\tslot\tchannel\n");
    for (i = 0; i < slotframe_active_slots; i++) {
      link = call Schedule.getLink(i);
      ptmp = (uint8_t*) &link->macNodeAddress.addr;
      printf("  %u\t\t", link->macLinkHandle);
      printf("  %x\t", link->macLinkOptions);
      printf("  %u\t", link->macLinkType);
      printf("  %u\t", link->sfHandle);
      printf("  (%u): %.2x %.2x %.2x %.2x %.2x %.2x %.2x %.2x\t", link->macNodeAddress.mode,
          ptmp[0], ptmp[2], ptmp[3],
          ptmp[3], ptmp[4], ptmp[5],
          ptmp[6], ptmp[7]);
      printf("  %u\t", link->macTimeslot);
      printf("  %u\n", link->macChannelOffset);
      printfflush();
      for (tmp = 0; tmp < 300000; tmp++) {}
    }
#endif
  }

  async command void Schedule.printSchedule() { post printSchedule(); }

}
