// $Id: TestHPLTDA5250C.nc,v 1.1.1.1 2005-11-04 18:20:16 kristinwright Exp $

/*                                  tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA,
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 *
 **/

includes Timer;
configuration TestHPLTDA5250C {
}
implementation {
  components Main
           , TestHPLTDA5250M
           , new AlarmMilliC() as ModeTimer
           , LedsC
           , TDA5250ConfigC
           ;

  TestHPLTDA5250M -> Main.Boot;
  
  Main.SoftwareInit -> LedsC;
  Main.SoftwareInit -> TDA5250ConfigC;

  TestHPLTDA5250M.Resource -> TDA5250ConfigC.Resource;
  TestHPLTDA5250M.ModeTimer -> ModeTimer;
  TestHPLTDA5250M.Leds  -> LedsC;
  TestHPLTDA5250M.TDA5250Config -> TDA5250ConfigC;
}



