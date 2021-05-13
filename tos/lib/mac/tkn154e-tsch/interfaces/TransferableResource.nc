/*
 * Copyright (c) 2005 Washington University in St. Louis.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holders nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */
 
/*
 * Copyright (c) 2004, Technische Universitat Berlin
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
 * - Neither the name of the Technische Universitat Berlin nor the names
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
 */

  /** 
   * This interface is the same as the standard <tt>Resource</tt> 
   * interface, except that it has one new command <tt>transferTo()</tt> 
   * and one new event <tt>transferred()</tt>, which allow to pass 
   * the resource from one component to another.
   *
   * @author Jan Hauer <hauer@tkn.tu-berlin.de>
   */

interface TransferableResource
{
  /**
   * Request access to a shared resource. You must call release()
   * when you are done with it.
   *
   * @return SUCCESS When a request has been accepted. The granted()
   *                 event will be signaled once you have control of the
   *                 resource.<br>
   *         EBUSY You have already requested this resource and a
   *               granted event is pending
   */
  async command error_t request();

  /**
  * Request immediate access to a shared resource. You must call release()
  * when you are done with it.
  *
  * @return SUCCESS When a request has been accepted. <br>
  *            FAIL The request cannot be fulfilled
  */
  async command error_t immediateRequest();

  /**
   * You are now in control of the resource.
   */
  event void granted();

  /** 
   * Transfers ownership of a resource to another client, which will in turn
   * be signalled the <tt>transferred()</tt> event. This command may override 
   * the default queueing policy.
   *
   * @param dstClient The identifier of the client to transfer the resource to.
   *
   * @return SUCCESS If ownership has been transferred; FAIL if ownership has
   * not been transferred, because the caller is not owner of the resource or
   * a client with the identifer <tt>dstClient</tt> is not present.
   */   
  async command error_t transferTo(uint8_t dstClient); 

  /** 
   * Another client transferred ownership of the resource to you by calling
   * the <tt>transfer()</tt> command, i.e. you are now in control of the resource.
   *
   * @param srcClient The identifier of the client that transferred the resource to you.
   */
  async event void transferredFrom(uint8_t srcClient); 

  /**
  * Release a shared resource you previously acquired.  
  *
  * @return SUCCESS The resource has been released <br>
  *         FAIL You tried to release but you are not the
  *              owner of the resource 
  *
  * @note This command should never be called between putting in a request 	  
  *       and waiting for a granted event.  Doing so will result in a
  *       potential race condition.  There are ways to guarantee that no
  *       race will occur, but they are clumsy and overly complicated.
  *       Since it doesn't logically make since to be calling
  *       <code>release</code> before receiving a <code>granted</code> event, 
  *       we have opted to keep thing simple and warn you about the potential 
  *       race.
  */
  async command error_t release();

  /**
   *  Check if the user of this interface is the current
   *  owner of the Resource
   *  @return TRUE  It is the owner <br>
   *             FALSE It is not the owner
   */
  async command bool isOwner();
}
