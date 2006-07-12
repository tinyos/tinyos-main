#include <tossim.h>

int main() {
  Tossim* t = new Tossim(NULL);
  t->init();
  //t->addChannel("Scheduler", fdopen(1, "w"));
  //t->addChannel("TossimPacketModelC", fdopen(1, "w"));
  t->addChannel("LedsC", fdopen(1, "w"));
  t->addChannel("AM", fdopen(1, "w"));

  Radio* r = t->radio();
    
  for (int i = 0; i < 2; i++) {
    printf("Mote %i at %i\n", i, 15000000 * i + 1);
    Mote* m = t->getNode(i);
    m->bootAtTime(15000000 * i + 1);
    r->setNoise(i, -77.0, 3);
    for (int j = 0; j < 2; j++) {
      if (i != j) {
        r->add(i, j, -50.0);
      }
    }
  }

  for (int i = 0; i < 60; i++) {
    t->runNextEvent();
  }
}
