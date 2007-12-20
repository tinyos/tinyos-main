/*
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
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
 * Copyright (c) 2007 Johns Hopkins University.
 * All rights reserved.
 *
 */

/**
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 * @author Chieh-Jan Mike Liang <cliang4@cs.jhu.edu>
 * @author Razvan Musaloiu-E. <razvanm@cs.jhu.edu>
 */

includes NetProg;
includes TOSBoot;

configuration NetProgC {
  provides {
    interface NetProg;
  }
}

implementation {

  components MainC, InternalFlashC as IFlash, CrcP, 
    DelugeStorageC, NetProgM;

  NetProg = NetProgM;

  MainC.SoftwareInit -> NetProgM.Init;
  NetProgM.DelugeStorage[VOLUME_GOLDENIMAGE] -> DelugeStorageC.DelugeStorage[VOLUME_GOLDENIMAGE];
  NetProgM.DelugeStorage[VOLUME_DELUGE1] -> DelugeStorageC.DelugeStorage[VOLUME_DELUGE1];
  NetProgM.DelugeStorage[VOLUME_DELUGE2] -> DelugeStorageC.DelugeStorage[VOLUME_DELUGE2];
  NetProgM.DelugeStorage[VOLUME_DELUGE3] -> DelugeStorageC.DelugeStorage[VOLUME_DELUGE3];
  NetProgM.DelugeMetadata -> DelugeStorageC;
  NetProgM.IFlash -> IFlash;
  NetProgM.Crc -> CrcP;
  
  components LedsC;
  NetProgM.Leds -> LedsC;
  
  components CC2420ControlP, ActiveMessageAddressC;
  NetProgM.CC2420Config -> CC2420ControlP;
  NetProgM.setAmAddress -> ActiveMessageAddressC;
}
