// $Id: TimeSyncMessageC.nc,v 1.3 2008-06-24 23:38:13 konradlorincz Exp $

/*
 * "Copyright (c) 2004-2005 The Regents of the University  of California.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA,
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 *
 * The Active Message layer on the shimmer platform. This is a naming wrapper
 * around the CC2420 Active Message layer that implemets timesync interface (TEP 133).
 *
 * @author Konrad Lorincz
 * @author Brano Kusy
 * @date June 19 2005
 */

configuration TimeSyncMessageC {
  provides
  {
    interface SplitControl;
    interface Receive[am_id_t id];
    interface Receive as Snoop[am_id_t id];
    interface Packet;
    interface AMPacket;

    interface PacketTimeStamp<T32khz, uint32_t> as PacketTimeStamp32khz;
    interface PacketTimeStamp<TMilli, uint32_t> as PacketTimeStampMilli;

    interface TimeSyncAMSend<T32khz, uint32_t> as TimeSyncAMSend32khz[am_id_t id];
    interface TimeSyncPacket<T32khz, uint32_t> as TimeSyncPacket32khz;

    interface TimeSyncAMSend<TMilli, uint32_t> as TimeSyncAMSendMilli[am_id_t id];
    interface TimeSyncPacket<TMilli, uint32_t> as TimeSyncPacketMilli;
  }
}
implementation {
  components CC2420TimeSyncMessageC as AM;

  SplitControl = AM;

  Receive      = AM.Receive;
  Snoop        = AM.Snoop;
  Packet       = AM;
  AMPacket     = AM;

  TimeSyncAMSend32khz       = AM;
  TimeSyncAMSendMilli       = AM;
  TimeSyncPacket32khz       = AM;
  TimeSyncPacketMilli       = AM;

  components CC2420PacketC;
  PacketTimeStamp32khz = CC2420PacketC;
  PacketTimeStampMilli = CC2420PacketC;
}

