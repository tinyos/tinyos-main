/*
 * "Copyright (c) 2005 Washington University in St. Louis.
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
 *
 
/*
 * - Revision -------------------------------------------------------------
 * $Revision: 1.4 $
 * $Date: 2006-12-12 18:23:15 $ 
 * ======================================================================== 
 *
 */
 
 /**
 * Please refer to TEP 108 for more information about this interface and its
 * intended use.<br><br>
 * 
 * This interface is provided by a Resource arbiter in order to allow
 * users of a shared resource to configure that resource just before being
 * granted access to it.  It will always be parameterized along side 
 * a parameterized Resource interface, with the ids from one mapping directly
 * onto the ids of the other.
 *
 * @author Kevin Klues (klueska@cs.wustl.edu)
 */

interface ResourceConfigure {
  /**
   * Used to configure a resource just before being granted access to it.
   * Must always be used in conjuntion with the Resource interface.
   */
  async command void configure();

  /**
   * Used to unconfigure a resource just before releasing it.
   * Must always be used in conjuntion with the Resource interface.
   */
  async command void unconfigure();
} 
