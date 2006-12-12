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
 */
 
/*
 * - Revision -------------------------------------------------------------
 * $Revision: 1.4 $
 * $Date: 2006-12-12 18:23:29 $ 
 * ======================================================================== 
 */
 
/**
 * Please refer to TEP 115 for more information about this interface and its
 * intended use.<br><br>
 *
 * This interface exists to allow a Resource user to cleanup any state
 * information before a shared Resource is shutdown.  It should be provided
 * by the user of a shared Resource, and used by the
 * power managment component for that Resource.  The <code>cleanup()</code>
 * command will be called by the power manager just before powering down
 * the shared resource.
 *
 * @author Kevin Klues (klueska@cs.wustl.edu)
 */

interface PowerDownCleanup {
  /**
   * This command will be called by the power management component of
   * a shared Resource.  The implementation of this command defines
   * what must be done just before that shared Resource is shut off.
   *
   */
  async command void cleanup();
} 
