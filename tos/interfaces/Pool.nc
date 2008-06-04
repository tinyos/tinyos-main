/* $Id: Pool.nc,v 1.5 2008-06-04 03:00:31 regehr Exp $ */
/*
 * Copyright (c) 2006 Stanford University.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Stanford University nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL STANFORD
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 *  An allocation pool of a specific type memory objects.
 *  The Pool allows components to allocate (<code>get</code>)
 *  and deallocate (<code>put</code>) elements. The pool
 *  does not require that deallocations be items which were
 *  originally allocated. E.g., a program can create two
 *  pools of the same type and pass items between them.
 *  This allows, for example, a component to allocate a pool
 *  of message buffers and freely buffer swap them on
 *  Receive.receive events.
 *
 *  @author Philip Levis
 *  @author Kyle Jamieson
 *  @date   $Date: 2008-06-04 03:00:31 $
 */

   
interface Pool<t> {

  /**
    * Returns whether there any elements remaining in the pool.
    * If empty returns TRUE, then <code>get</code> will return
    * NULL. If empty returns FALSE, then <code>get</code> will
    * return a pointer to an object.
    *
    * @return Whether the pool is empty.
    */

  command bool empty();

  /**
    * Returns how many elements are in the pool. If size
    * returns 0, empty() will return TRUE. If size returns
    * a non-zero value, empty() will return FALSE. The
    * return value of size is always &lte; the return
    * value of maxSize().
    *
    * @return How many elements are in the pool.
    */
  command uint8_t size();
  
  /**
    * Returns the maximum number of elements in the pool
    * (the size of a full pool).
    *
    * @return Maximum size.
    */
  command uint8_t maxSize();

  /**
    * Deallocate an object, putting it back into the pool.
    *
    * @param 't* ONE newVal'
    * @return SUCCESS if the entry was put in successfully, FAIL
    * if the pool is full.
    */
  command error_t put(t* newVal);

  /**
    * Allocate an element from the pool.
    *
    * @return 't* ONE_NOK' A pointer if the pool is not empty, NULL if
    * the pool is empty.
    */
  command t* get();
}
