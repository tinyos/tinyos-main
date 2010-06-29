// $Id: DisseminationValue.nc,v 1.6 2010-06-29 22:07:47 scipio Exp $
/*
 * Copyright (c) 2006 Stanford University. All rights reserved.
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
 * - Neither the name of the copyright holder nor the names of
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

/**
 * Read a network shared (disseminated) variable and be notified
 * of updates.
 *
 * @author Philip Levis
 * @author Gilman Tolle
 *
 * @date   Jan 7 2006
 */ 


interface DisseminationValue<t> {

  /**
   * Obtain a pointer to the variable. The provider of this
   * interface only will change the memory the pointer references
   * in tasks. Therefore the memory region does not change during
   * the execution of any other task. A user of this interface
   * must not in any circumstance write to this memory location.
   *
   * @return A const pointer to the variable.
   */
  command const t* get();

  /**
   * Set the variable to a new value. The provider of this interface
   * will copy the value from the pointer. NOTE: This command does
   * not cause the new value to begin disseminating. It is intended to
   * be used for setting default values.
   */

  command void set( const t* );

  /**
   * Signalled whenever variable may have changed.
   */
  event void changed();
}



