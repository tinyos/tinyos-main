#include "printf.h"

module LinkedListTestC
{
  provides {
    interface Compare<message_t*>;
  }
  uses {
    interface Boot;
    interface Queue<message_t*>;
    interface LinkedList<message_t*>;
  }
} implementation {

  //#define DTSCH_LINKED_LIST_DEBUG_PRINTF

  void run();

  command bool Compare.equal(message_t* elem1, message_t* elem2) {
    if (elem1 == elem1)
        return TRUE;
    return FALSE;
  }

  event void Boot.booted() {
    call LinkedList.init();
    run();
  }
  void run() {
    message_t msgs[] = {1,2,3,4,5,6,7,8,9,10};

    printf("\nEnqueue [0](%p)\n", &msgs[0]);
    call Queue.enqueue(&msgs[0]);

    printfflush();

    printf("\nEnqueue [1](%p)\n", &msgs[1]);
    call Queue.enqueue(&msgs[1]);

    printf("\nElement(0): %p\n", call Queue.element(0));

    printf("\nElement(1): %p\n", call Queue.element(1));

    printf("\nElement(2) not there: %p\n", call Queue.element(2));


    printf("\nRemove [0](%p)\n", &msgs[0]);
    call LinkedList.remove(&msgs[0]);



    printf("\nRemove [1](%p)\n", &msgs[1]);
    call LinkedList.remove(&msgs[1]);

    printf("\nEnqueue [1](%p)\n", &msgs[1]);
    call Queue.enqueue(&msgs[1]);


    printf("\nEnqueue [2](%p)\n", &msgs[2]);
    call Queue.enqueue(&msgs[2]);

    printf("\nDequeue %p\n", call Queue.dequeue());

    printf("\nDequeue %p\n", call Queue.dequeue());

    printf("\nEnqueue [3](%p)\n", &msgs[3]);
    call Queue.enqueue(&msgs[3]);

    printf("\nDequeue %p\n", call Queue.dequeue());

    printf("\nEnqueue [4](%p)\n", &msgs[4]);
    call Queue.enqueue(&msgs[4]);

    printf("\nEnqueue [5](%p)\n", &msgs[5]);
    call Queue.enqueue(&msgs[5]);

    printf("\nEnqueue [6](%p)\n", &msgs[6]);
    call Queue.enqueue(&msgs[6]);

    printf("\nRemove [5](%p)\n", &msgs[5]);
    call LinkedList.remove(&msgs[5]);

    printf("\nRemove [6](%p)\n", &msgs[6]);
    call LinkedList.remove(&msgs[6]);

    printf("\nEnqueue [7](%p)\n", &msgs[7]);
    call Queue.enqueue(&msgs[7]);

    printf("\nRemove [6](%p)\n", &msgs[4]);
    call LinkedList.remove(&msgs[4]);

    printfflush();
  }

}
