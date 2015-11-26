#include "printf.h"

module LinkedListTestC
{
  uses {
    interface Boot;
    interface Queue<uint8_t*>;
    interface LinkedList<uint8_t*>;
  }
} implementation {

  void run();

  event void Boot.booted() {
    call LinkedList.init();
    run();
  }

  void run() {
    uint8_t vals[] = {1,2,3,4,5,6,7,8,9,10};

    call Queue.enqueue(&vals[0]);
    call Queue.enqueue(&vals[1]);
    call Queue.enqueue(&vals[2]);
    printf("dequeued %u\n\n", *call Queue.dequeue());
    printf("dequeued %u\n\n", *call Queue.dequeue());
    call Queue.enqueue(&vals[3]);
    printf("dequeued %u\n\n", *call Queue.dequeue());
    call Queue.enqueue(&vals[4]);
    call Queue.enqueue(&vals[5]);
    call Queue.enqueue(&vals[6]);
    call LinkedList.remove(&vals[5]);
    call LinkedList.remove(&vals[6]);
    call Queue.enqueue(&vals[7]);
    call LinkedList.remove(&vals[4]);
    printfflush();
  }

}
