#include <sim_binary.h>

link_t* connectivity[TOSSIM_MAX_NODES];

link_t* allocate_link(int mote);
void deallocate_link(link_t* link);

link_t* sim_binary_first(int src) __attribute__ ((C, spontaneous)) {
  return connectivity[src];
}

link_t* sim_binary_next(link_t* link) __attribute__ ((C, spontaneous)) {
  return link->next;
}

void sim_binary_add(int src, int dest, double packetLoss) __attribute__ ((C, spontaneous))  {
  link_t* current;
  int temp = sim_node();
  sim_set_node(src);

  current = connectivity[src];
  while (current != NULL) {
    if (current->mote == dest) {
      sim_set_node(temp);
      break;
    }
    current = current->next;
  }

  if (current == NULL) {
    current = allocate_link(dest);
  }
  current->mote = dest;
  current->loss = packetLoss;
  current->next = connectivity[src];
  connectivity[src] = current;
  dbg("Binary", "Adding link from %i to %i with loss %llf\n", src, dest, packetLoss);
  sim_set_node(temp);
}

double sim_binary_loss(int src, int dest) __attribute__ ((C, spontaneous))  {
  link_t* current;
  int temp = sim_node();
  sim_set_node(src);
  current = connectivity[src];
  while (current != NULL) {
    if (current->mote == dest) {
      sim_set_node(temp);
      return current->loss;
    }
    current = current->next;
  }
  sim_set_node(temp);
  return 1.0;
}

bool sim_binary_connected(int src, int dest) __attribute__ ((C, spontaneous)) {
  link_t* current;
  int temp = sim_node();
  sim_set_node(src);
  current = connectivity[src];
  while (current != NULL) {
    if (current->mote == dest) {
      sim_set_node(temp);
      return TRUE;
    }
    current = current->next;
  }
  sim_set_node(temp);
  return FALSE;
}
  
void sim_binary_remove(int src, int dest) __attribute__ ((C, spontaneous))  {
  link_t* current;
  link_t* prevLink;
  int temp = sim_node();
  sim_set_node(src);
    
  current = connectivity[src];
  prevLink = NULL;
    
  while (current != NULL) {
    if (current->mote == dest) {
      if (prevLink == NULL) {
	connectivity[src] = current->next;
      }
      else {
	prevLink->next = current->next;
      }
      deallocate_link(current);
      current = prevLink->next;
    }
    else {
      prevLink = current;
      current = current->next;
    }
  }
  sim_set_node(temp);
}

 link_t* allocate_link(int mote) {
   link_t* link = (link_t*)malloc(sizeof(link_t));
   link->next = NULL;
   link->mote = mote;
   link->loss = 1.0;
   return link;
 }

 void deallocate_link(link_t* link) {
   free(link);
 }
