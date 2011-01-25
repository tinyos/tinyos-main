/*
 * Copyright (c) 2010, KTH Royal Institute of Technology
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 * 
 *  - Redistributions of source code must retain the above copyright notice, this list
 *  of conditions and the following disclaimer.
 * 
 * - Redistributions in binary form must reproduce the above copyright notice, this
 *    list of conditions and the following disclaimer in the documentation and/or other
 *  materials provided with the distribution.
 * 
 * - Neither the name of the Royal Institute of Technology nor the names of its 
 *    contributors may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
 * IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, 
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY 
 * OF SUCH DAMAGE.
 */
/** 
 * The component InactivePeriodP owns the radio token during the inactive period in
 * nodes in beacon-enabled networks. It powers the radio down and restarts it before
 * handing over the radio token to the beacon reception/transmission component.
 * Depending on the actual radio, powering it down may result in less energy 
 * consumption than idle, e.g. for the CC2420 powering down means disabling the
 * crystal oscillator, which saves a significant amount energy compard to the
 * idle state. 
 *
 * @author João Faria <jfff@kth.se>
 * @author Aitor Hernandez <aitorhh@kth.se>
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 */

#include "TKN154_MAC.h"

generic module InactivePeriodP(uint8_t sfDirection)
{
  uses {
    interface TransferableResource as RadioToken;
    interface Alarm<TSymbolIEEE802154,uint32_t> as Alarm;
    interface SplitControl as RadioControl;
    interface SuperframeStructure as SF;
    interface GetNow<bool> as IsEmbedded;
    interface RadioOff;
    interface MLME_GET;
    interface TimeCalc;
  }
}
implementation {

#ifndef IEEE154_RADIO_POWERUP_TIME  

  async event void RadioToken.transferredFrom(uint8_t fromClient) 
  {
    dbg_serial("InactivePeriodP", "Power down disabled, transferring token\n");
    if (sfDirection == OUTGOING_SUPERFRAME) {
      call RadioToken.transferTo(RADIO_CLIENT_BEACONSYNCHRONIZE);
    } else {
      call RadioToken.transferTo(RADIO_CLIENT_BEACONTRANSMIT);
    }
  }

  async event void RadioOff.offDone() { ASSERT(0);}
  event void RadioControl.stopDone(error_t result) { }
  event void RadioControl.startDone(error_t result) { }
  async event void Alarm.fired() { ASSERT(0);}
  event void RadioToken.granted() { ASSERT(0);}

#else

  task void offDoneTask();
  task void firedTask();

  void transferToken() 
  {
    dbg_serial("InactivePeriodP", "Transferring token\n");
    if (sfDirection == OUTGOING_SUPERFRAME) {
      call RadioToken.transferTo(RADIO_CLIENT_BEACONSYNCHRONIZE);
    } else {
      call RadioToken.transferTo(RADIO_CLIENT_BEACONTRANSMIT);
    }
  }

  uint32_t maxDt()
  {
    return call SF.beaconInterval() - IEEE154_RADIO_POWERUP_TIME - call SF.guardTime();
  }

  bool tooLate()
  {
    if (call IsEmbedded.getNow()) {
      // we have a situation where there is an incoming and outgoing superframe 
      // (scenario as indicated in 802.15.4-2006 Fig. 67), so the inactive period 
      // is not "inactive", we should not power down (TODO: we might power down
      // for a smaller amount of time, the time in between two superframes)
      return TRUE;
    } else
      return call TimeCalc.hasExpired(call SF.sfStartTime(), maxDt());
  }

  async event void RadioToken.transferredFrom(uint8_t fromClient) 
  {
    if (tooLate()) {
      dbg_serial("InactivePeriodP", "Got token: Not enough time to powerdown %lu, %lu.\n", (uint32_t) call SF.beaconInterval(), maxDt());
      transferToken();
    } else {
      error_t error = call RadioOff.off();
      dbg_serial("InactivePeriodP", "Got token, switching radio off: %lu (%lu)\n", (uint32_t) error, call Alarm.getNow());
      if (error == EALREADY) 
        signal RadioOff.offDone();
      else if (error != SUCCESS) 
        transferToken();
    }
  }

  async event void RadioOff.offDone() 
  {
    post offDoneTask(); 
  }

  task void offDoneTask() 
  {
    dbg_serial("InactivePeriodP", "Trying to power radio down\n");
    if (tooLate() || call RadioControl.stop() != SUCCESS) /* Disable the radio chip, voltage reg, oscillator, mm */
      transferToken();
  }

  event void RadioControl.stopDone(error_t result) 
  {
    // NOTE: RadioControl is fanning out, so we have to check if we
    // are the actual client that is owning the radio (or if someone 
    // else has called RadioControl.stop).
    if (call RadioToken.isOwner()) {
      dbg_serial("InactivePeriodP", "Radio powered down: %lu\n", (uint32_t) result);
      call Alarm.startAt(call SF.sfStartTime(), maxDt());
    }
  }

  async event void Alarm.fired() 
  { 
    post firedTask(); 
  }

  task void firedTask() {
    dbg_serial("InactivePeriodP", "Powering radio up again (%lu)\n", call Alarm.getNow());
    call RadioControl.start();
  }

  event void RadioControl.startDone(error_t error) {
    // comment at RadioControl.stopDone() applies here as well
    if (call RadioToken.isOwner()) {
      dbg_serial("InactivePeriodP", "Done: radio powered up (%lu)\n", call Alarm.getNow());
      transferToken();
    }
  }

  event void RadioToken.granted() { ASSERT(0);}
#endif
}
