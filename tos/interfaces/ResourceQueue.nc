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
 *  A queue interface for managing client ids when performing resource 
 *  arbitration. A single slot in the queue is guaranteed to each resource
 *  client, with the actual queing policy determined by the implementation
 *  of the interface.
 *
 *  @author Kevin Klues <klueska@cs.wustl.edu>
 *  @date   $Date: 2009-04-15 03:01:35 $
 */
 
#include "Resource.h"
   
interface ResourceQueue {
	
  /**
   * Check to see if the queue is empty.
   *
   * @return TRUE  if the queue is empty. <br>
   *         FALSE if there is at least one entry in the queue
   */
  async command bool isEmpty();
  
  /**
   * Check to see if a given client id has already been enqueued
   * and is waiting to be processed.
   *
   * @return TRUE  if the client id is in the queue. <br>
   *         FALSE if it does not
   */
  async command bool isEnqueued(resource_client_id_t id);
  
  /**
   * Retreive the client id of the next resource in the queue. 
   * If the queue is empty, the return value is undefined.
   *
   * @return The client id at the head of the queue.
   */
  async command resource_client_id_t dequeue();

  /**
   * Enqueue a client id
   *
   * @param clientId - the client id to enqueue
   * @return SUCCESS if the client id was enqueued successfully <br>
   *         EBUSY   if it has already been enqueued.
   */
  async command error_t enqueue(resource_client_id_t id);
}
