/*
 * Copyright (c) 2008 Stanford University.
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
 * @author Kevin Klues (klueska@cs.stanford.edu)
 * Implementation borrowed from the msp430-libc implementation
 */
 
/*
 * MALLOC_HEAP_SIZE MUST be defined as a power of 2
 */
#ifndef MALLOC_HEAP_SIZE
#define MALLOC_HEAP_SIZE 1024
#endif
 
module TosMallocC {
  provides interface Malloc;
}
implementation {
  #define XSIZE(x) ((*x)>>1)
  #define FREE_P(x) (!((*x)&1))
  #define MARK_BUSY(x) ((*x)|=1)
  #define MARK_FREE(x) ((*x)&=0xfffe)

  size_t malloc_heap[MALLOC_HEAP_SIZE];

  void *tos_malloc (size_t size) @C() AT_SPONTANEOUS
  {
    static char once = 0;
    size_t * heap_bottom = &(malloc_heap[MALLOC_HEAP_SIZE]);
    size_t * heap_top = malloc_heap;
    char f = 0;

    atomic if (!once)
    {
        once = 1;
        *heap_top = 0xFFFE;
    }
    size = (size+1) >> 1;	/* round to 2 */
    do
    {
        size_t xsize = XSIZE (heap_top);
        size_t * heap_next = &heap_top[xsize + 1];
        if ((xsize<<1)+2 == 0)
        {
            f = 1;
        }
        if (FREE_P (heap_top))
        {
            if (f)
            {
                xsize = heap_bottom - heap_top - 1;
            }
            else if (FREE_P(heap_next))
            {
                *heap_top = ( (XSIZE(heap_next)<<1) + 2 == 0
                              ? 0xfffe
                              : (xsize + XSIZE(heap_next) + 1)<<1);
                continue;
            }
            if (xsize >= size)
            {
                if (f)
                    heap_top[size + 1] = 0xfffe;
                else if (xsize != size)
                    heap_top[size + 1] = (xsize - size - 1) << 1;
                *heap_top = size << 1;
                MARK_BUSY (heap_top);
                return heap_top+1;
            }
        }
        heap_top += xsize + 1;
    }
    while (!f);
    return NULL;
  }

  void tos_free (void *p) @C() AT_SPONTANEOUS
  {
    size_t *t = (size_t*)p - 1;
    MARK_FREE (t);
  }
  
  async command void* Malloc.malloc(size_t size) {
    return tos_malloc(size);
  }
  
  async command void Malloc.free(void* p) {
    tos_free(p);
  }
}
