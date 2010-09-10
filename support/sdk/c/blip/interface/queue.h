#ifndef _QUEUE_H_
#define _QUEUE_H_

#include <pthread.h>

struct queue_entry;
struct queue_entry {
  void   *q_data;
  struct queue_entry *q_next;
};

struct blocking_queue {
  pthread_mutex_t     mut;
  pthread_cond_t      cond;
  struct queue_entry *head, *tail;
};

int   queue_init(struct blocking_queue *q);
int   queue_push(struct blocking_queue *q, void *data);

/* blocks until there's something to pop */
void *queue_pop(struct blocking_queue *q);


#endif
