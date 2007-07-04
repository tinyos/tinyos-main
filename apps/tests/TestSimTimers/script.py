from TOSSIM import *
import sys
import time

t = Tossim([])

t.addChannel("TestTimer", sys.stdout)
#t.addChannel("Timer", sys.stdout)
#t.addChannel("HplAtm128Timer0AsyncP", sys.stdout)
#t.addChannel("Atm128AlarmAsyncP", sys.stdout)

start = time.time();
m1 = t.getNode(0)

m1.bootAtTime(345321);

for i in range(0, 10000):
    t.runNextEvent();

    
