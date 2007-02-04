/*
 * Copyright (c) 2005, Technische Universitaet Berlin
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
 * Please refer to TEP 108 for more information about this interface and its
 * intended use.<br><br>
 *
 * @author Kevin Klues (klues@tkn.tu-berlin.edu)
 * @version $ $
 * @date $Date: 2007-02-04 20:06:42 $ 
 */

interface ResourceDefaultOwner {
  /**
   * Event sent to the resource controller giving it control whenever a resource
   * goes idle. That is to say, whenever no one currently owns the resource,
   * and there are no more pending requests
  */
  async event void granted();

  /**
  * Release control of the resource
  *
  * @return SUCCESS The resource has been released and pending requests
  *                 can resume. <br>
  *             FAIL You tried to release but you are not the
  *                  owner of the resource
  */
  async command error_t release();

  /**
   *  Check if the user of this interface is the current
   *  owner of the Resource
   * 
   *  @return TRUE  It is the owner <br>
   *          FALSE It is not the owner
   */
  async command bool isOwner();

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
