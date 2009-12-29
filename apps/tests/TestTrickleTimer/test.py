from TOSSIM import *
import sys

t = Tossim([]);
t.init()
t.addChannel("Trickle", sys.stdout);

for i in range(0, 1):
    m = t.getNode(i)
    m.bootAtTime(i * 5023211 + 10002322)

for i in range(0, 1000000):
    t.runNextEvent()

    
