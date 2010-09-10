
#include <stdlib.h>
#include <pthread.h>

#include "queue.h"

int queue_init(struct blocking_queue *q) {
  pthread_mutex_init(&q->mut, NULL);
  pthread_cond_init(&q->cond, NULL);
  q->head = NULL;
}

int queue_push(struct blocking_queue *q, void *data) {
  struct queue_entry *new = (struct queue_entry *)malloc(sizeof(struct queue_entry));

  if (!new) return -1;

  pthread_mutex_lock(&q->mut);

  new->q_data = data;

  if (!q->tail) {
    q->head = q->tail = new;
    new->q_next = NULL;
  } else {
    new->q_next = NULL;
    q->tail->q_next = new;
    q->tail = new;
  }

  pthread_cond_broadcast(&q->cond);
  pthread_mutex_unlock(&q->mut);
  return 0;
}

/* blocks until there's something to pop */
void *queue_pop(struct blocking_queue *q) {
  void *rv;
  struct queue_entry *extra;

  pthread_mutex_lock(&q->mut);
  while (q->head == NULL) {
    pthread_cond_wait(&q->cond, &q->mut);
  }

  extra = q->head;
  q->head = extra->q_next;
  if (!q->head) q->tail = NULL;
  rv = extra->q_data;
  free(extra);
  pthread_mutex_unlock(&q->mut);
  return rv;
}
