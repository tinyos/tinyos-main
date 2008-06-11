// $Id: NetProg.nc,v 1.3 2008-06-11 00:46:24 razvanm Exp $

/*
 *
 *
 * "Copyright (c) 2000-2004 The Regents of the University  of California.  
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
 */

/**
 * Top level interface for network programming integration with
 * applications.
 *
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 */

interface NetProg
{

  /**
   * Reboot the node.
   *
   * @return  Does not return.
   */
  command error_t reboot();

  /**
   * Reboot into the image specified by <code>imageAddr</code>. This
   * assumes that an image is present into the external flash
   * at the <code>imageAddr</code> address.
   *
   * @param imageAddr  Address in external flash
   * @return        <code>FAIL</code> if the reboot command fails to 
   *                complete, does not return, otherwise.
   */
  command error_t programImageAndReboot(uint32_t imageAddr);

}
