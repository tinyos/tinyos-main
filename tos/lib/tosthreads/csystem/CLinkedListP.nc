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
 * @author Kevin Klues <klueska@cs.stanford.edu>
 */
 

module CLinkedListP { 
  uses interface LinkedList;
}
implementation { 
  void linked_list_init(linked_list_t* l) @C() AT_SPONTANEOUS {  
    call LinkedList.init(l);
  }
  void linked_list_clear(linked_list_t* l) @C() AT_SPONTANEOUS { 
    call LinkedList.clear(l);
  }
  uint8_t linked_list_size(linked_list_t* l) @C() AT_SPONTANEOUS { 
    return call LinkedList.size(l);
  }
  error_t linked_list_addFirst(linked_list_t* l, list_element_t* e) @C() AT_SPONTANEOUS { 
    return call LinkedList.addFirst(l, e);
  }
  list_element_t* linked_list_getFirst(linked_list_t* l) @C() AT_SPONTANEOUS { 
    return call LinkedList.getFirst(l);
  }
  list_element_t* linked_list_removeFirst(linked_list_t* l) @C() AT_SPONTANEOUS { 
    return call LinkedList.removeFirst(l);
  }
  error_t linked_list_addLast(linked_list_t* l, list_element_t* e) @C() AT_SPONTANEOUS { 
    return call LinkedList.addLast(l, e);
  }
  list_element_t* linked_list_getLast(linked_list_t* l) @C() AT_SPONTANEOUS { 
    return call LinkedList.getLast(l);
  }
  list_element_t* linked_list_removeLast(linked_list_t* l) @C() AT_SPONTANEOUS { 
    return call LinkedList.removeLast(l);
  }
  error_t linked_list_addAt(linked_list_t* l, list_element_t* e, uint8_t i) @C() AT_SPONTANEOUS { 
    return call LinkedList.addAt(l, e, i);
  }
  list_element_t* linked_list_getAt(linked_list_t* l, uint8_t i) @C() AT_SPONTANEOUS { 
    return call LinkedList.getAt(l, i);
  }
  list_element_t* linked_list_removeAt(linked_list_t* l, uint8_t i) @C() AT_SPONTANEOUS { 
    return call LinkedList.removeAt(l, i);
  }  
  error_t linked_list_addAfter(linked_list_t* l, list_element_t* first, list_element_t* second) @C() AT_SPONTANEOUS { 
    return call LinkedList.addAfter(l, first, second);
  }
  error_t linked_list_addBefore(linked_list_t* l, list_element_t* first, list_element_t* e) @C() AT_SPONTANEOUS { 
    return call LinkedList.addBefore(l, first, e);
  }
  list_element_t* linked_list_getAfter(linked_list_t* l, list_element_t* e) @C() AT_SPONTANEOUS { 
    return call LinkedList.getAfter(l, e);
  }  
  list_element_t* linked_list_getBefore(linked_list_t* l, list_element_t* e) @C() AT_SPONTANEOUS { 
    return call LinkedList.getBefore(l, e);
  }
  list_element_t* linked_list_remove(linked_list_t* l, list_element_t* e) @C() AT_SPONTANEOUS { 
    return call LinkedList.remove(l, e);
  }  
  list_element_t* linked_list_removeBefore(linked_list_t* l, list_element_t* e) @C() AT_SPONTANEOUS { 
    return call LinkedList.removeBefore(l, e);
  }  
  list_element_t* linked_list_removeAfter(linked_list_t* l, list_element_t* e) @C() AT_SPONTANEOUS { 
    return call LinkedList.removeAfter(l, e);
  }  
  uint8_t linked_list_indexOf(linked_list_t* l, list_element_t* e) @C() AT_SPONTANEOUS { 
    return call LinkedList.indexOf(l, e);
  }
}
