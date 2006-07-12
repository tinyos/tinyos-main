#include <stdio.h>
#include <tossim.h>
#include <radio.h>
#include <math.h>

int main() {
 Tossim* t = new Tossim(NULL);
 t-> init();

 for (int i = 0; i < 10; i++) {
   Mote* m = t->getNode(i * 5);
   m->bootAtTime(rand() % t->ticksPerSecond());
 }


 t->addChannel("TestNetworkC", stdout);
 t->addChannel("Forwarder", stdout);
// t->addChannel("PointerBug", stdout);
// t->addChannel("QueueC", stdout);
// t->addChannel("PoolP", stdout);
 //t->addChannel("LITest", stdout);
 //t->addChannel("AM", stdout);
// t->addChannel("Route", stdout);

 Radio* r = t->radio();
 for (int i = 0; i < 10; i++) {
    r->setNoise(i * 5, -105.0, 1.0);
   for (int j = 0; j < 10; j++) {
      r->add(i * 5, j * 5, -96.0 - (double)abs(i - j));
      r->add(j * 5, i * 5, -96.0 - (double)abs(i - j));
   }
 }

 while(t->time() < 600 * t->ticksPerSecond()) {
   t->runNextEvent();
 }
}
