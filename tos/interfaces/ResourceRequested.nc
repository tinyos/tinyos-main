/*
 * "Copyright (c) 2006 Washington University in St. Louis.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL WASHINGTON UNIVERSITY IN ST. LOUIS BE LIABLE TO ANY PARTY 
 * FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING 
 * OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF WASHINGTON 
 * UNIVERSITY IN ST. LOUIS HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * WASHINGTON UNIVERSITY IN ST. LOUIS SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND WASHINGTON UNIVERSITY IN ST. LOUIS HAS NO 
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
 * MODIFICATIONS."
 */
 
/**
 * Please refer to TEP 108 for more information about this interface and its
 * intended use.<br><br>
 *
 * The ResourceRequested interface can be used in conjunction with the 
 * Resource interface in order to receive events based on other users
 * requests.
 * 
 * @author Kevin Klues (klueska@cs.wustl.edu)
 * @version $Revision: 1.4 $
 * @date $Date: 2006-12-12 18:23:15 $
 */

interface ResourceRequested {
  /**
   * This event is signalled whenever the user of this interface
   * currently has control of the resource, and another user requests
   * it through the Resource.request() command. You may want to
   * consider releasing a resource based on this event
  */
  async event void requested();

  /**
  * This event is signalled whenever the user of this interface
  * currently has control of the resource, and another user requests
  * it through the Resource.immediateRequest() command. You may
  * want to consider releasing a resource based on this event
  */
  async event void immediateRequested();
}
