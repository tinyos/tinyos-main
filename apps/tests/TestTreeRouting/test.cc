#include <tossim.h>
#include <iostream>
#include <string>


int main() {
  Tossim* t = new Tossim(NULL);
  t->init();

  t->addChannel("TreeRouting", stdout);
  t->addChannel("TreeRoutingCtl", stdout);
  t->addChannel("AM", stdout);


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

  while (t->time()/t->ticksPerSecond()  < 600) {
    t->runNextEvent();
  }
	
}
