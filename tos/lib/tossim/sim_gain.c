#include <sim_gain.h>

typedef struct sim_gain_noise {
  double mean;
  double range;
} sim_gain_noise_t;


gain_entry_t* connectivity[TOSSIM_MAX_NODES + 1];
sim_gain_noise_t localNoise[TOSSIM_MAX_NODES + 1];
double sensitivity = 4.0;

gain_entry_t* sim_gain_allocate_link(int mote);
void sim_gain_deallocate_link(gain_entry_t* linkToDelete);

gain_entry_t* sim_gain_first(int src) __attribute__ ((C, spontaneous)) {
  if (src > TOSSIM_MAX_NODES) {
    return connectivity[TOSSIM_MAX_NODES];
  } 
  return connectivity[src];
}

gain_entry_t* sim_gain_next(gain_entry_t* currentLink) __attribute__ ((C, spontaneous)) {
  return currentLink->next;
}

void sim_gain_add(int src, int dest, double gain) __attribute__ ((C, spontaneous))  {
  gain_entry_t* current;
  int temp = sim_node();
  if (src > TOSSIM_MAX_NODES) {
    src = TOSSIM_MAX_NODES;
  }
  sim_set_node(src);

  current = sim_gain_first(src);
  while (current != NULL) {
    if (current->mote == dest) {
      sim_set_node(temp);
      break;
    }
    current = current->next;
  }

  if (current == NULL) {
    current = sim_gain_allocate_link(dest);
    current->next = connectivity[src];
    connectivity[src] = current;
  }
  current->mote = dest;
  current->gain = gain;
  dbg("Gain", "Adding link from %i to %i with gain %f\n", src, dest, gain);
  sim_set_node(temp);
}

double sim_gain_value(int src, int dest) __attribute__ ((C, spontaneous))  {
  gain_entry_t* current;
  int temp = sim_node();
  sim_set_node(src);
  current = sim_gain_first(src);
  while (current != NULL) {
    if (current->mote == dest) {
      sim_set_node(temp);
      dbg("Gain", "Getting link from %i to %i with gain %f\n", src, dest, current->gain);
      return current->gain;
    }
    current = current->next;
  }
  sim_set_node(temp);
  dbg("Gain", "Getting default link from %i to %i with gain %f\n", src, dest, 1.0);
  return 1.0;
}

bool sim_gain_connected(int src, int dest) __attribute__ ((C, spontaneous)) {
  gain_entry_t* current;
  int temp = sim_node();
  sim_set_node(src);
  current = sim_gain_first(src);
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
  
void sim_gain_remove(int src, int dest) __attribute__ ((C, spontaneous))  {
  gain_entry_t* current;
  gain_entry_t* prevLink;
  int temp = sim_node();
  
  if (src > TOSSIM_MAX_NODES) {
    src = TOSSIM_MAX_NODES;
  }

  sim_set_node(src);
    
  current = sim_gain_first(src);
  prevLink = NULL;
    
  while (current != NULL) {
    if (current->mote == dest) {
      if (prevLink == NULL) {
	connectivity[src] = current->next;
      }
      else {
	prevLink->next = current->next;
      }
      sim_gain_deallocate_link(current);
      current = prevLink->next;
    }
    else {
      prevLink = current;
      current = current->next;
    }
  }
  sim_set_node(temp);
}

void sim_gain_set_noise_floor(int node, double mean, double range) __attribute__ ((C, spontaneous))  {
  if (node > TOSSIM_MAX_NODES) {
    node = TOSSIM_MAX_NODES;
  }
  localNoise[node].mean = mean;
  localNoise[node].range = range;
}

double sim_gain_noise_mean(int node) {
  if (node > TOSSIM_MAX_NODES) {
    node = TOSSIM_MAX_NODES;
  }
  return localNoise[node].mean;
}

double sim_gain_noise_range(int node) {
  if (node > TOSSIM_MAX_NODES) {
    node = TOSSIM_MAX_NODES;
  }
  return localNoise[node].range;
}

// Pick a number a number from the uniform distribution of
// [mean-range, mean+range].
double sim_gain_sample_noise(int node)  __attribute__ ((C, spontaneous)) {
  double val, adjust;
  if (node > TOSSIM_MAX_NODES) {
    node = TOSSIM_MAX_NODES;
  } 
  val = localNoise[node].mean;
  adjust = (sim_random() % 2000000);
  adjust /= 1000000.0;
  adjust -= 1.0;
  adjust *= localNoise[node].range;
  return val + adjust;
}

gain_entry_t* sim_gain_allocate_link(int mote) {
  gain_entry_t* newLink = (gain_entry_t*)malloc(sizeof(gain_entry_t));
  newLink->next = NULL;
  newLink->mote = mote;
  newLink->gain = -10000000.0;
  return newLink;
}

void sim_gain_deallocate_link(gain_entry_t* linkToDelete) __attribute__ ((C, spontaneous)) {
  free(linkToDelete);
}

void sim_gain_set_sensitivity(double s) __attribute__ ((C, spontaneous)) {
  sensitivity = s;
}

double sim_gain_sensitivity() __attribute__ ((C, spontaneous)) {
  return sensitivity;
}
