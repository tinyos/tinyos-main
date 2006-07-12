#include <tossim.h>

int main() {
  nesc_app_t na;
  na.numVariables = 1;
  na.variableNames = (char**)malloc(sizeof(char*));
  na.variableTypes = (char**)malloc(sizeof(char*));
  na.variableArray = (int*)malloc(sizeof(int));
  na.variableNames[0] = "TestSerialC.arrayTest";
  na.variableTypes[0] = "int";
  na.variableArray[0] = 1;

  Tossim* t = new Tossim(&na);
  t->init();
  //  t->addChannel("BlinkC", fdopen(1, "w"));
  //  t->addChannel("HplAtm128CompareC", fdopen(1, "w"));
  //t->addChannel("HplCounter0C", fdopen(1, "w"));
  //t->addChannel("Atm128AlarmC", fdopen(1, "w"));
  //t->addChannel("TransformAlarmCounterC", fdopen(1, "w"));
  //t->addChannel("Scheduler", fdopen(1, "w"));
  //t->addChannel("Trickle", fdopen(1, "w"));
  t->addChannel("TestTrickle", fdopen(1, "w"));
  t->addChannel("TrickleTimes", fdopen(1, "w"));
  
  for (int i = 0; i < 1; i++) {
    printf("Mote %i at %i\n", i, 500 * i + 1);
    Mote* m = t->getNode(i);
    m->bootAtTime(500 * i + 1);
  }

  for (int i = 0; i < 5000; i++) {
    t->runNextEvent();
  }

  int x = 2;

  for (int i = 0; i < 5000; i++) {
    t->runNextEvent();
  }
  
  //  Mote* m = t->getNode(2);
  //Variable* v = m->getVariable("TestSerialC.arrayTest");

  //  variable_string_t s = v->getData();

  //printf ("TestSerialC.arrayTest: %s %s\n", s.type, s.isArray? "[]":"");

}
