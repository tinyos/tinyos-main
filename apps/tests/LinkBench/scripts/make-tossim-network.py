from TOSSIM import *
import sys
import time

t = Tossim([])
r = t.radio();

t.addChannel("Benchmark", sys.stdout)

sf = SerialForwarder(9002)
th = Throttle(t,10);
    
start = time.time();
m1 = t.getNode(1)
m2 = t.getNode(2)

# Set up a hidden terminal problem, where 1 and 3
# are closely synchronized, but cannot hear each other.
m1.bootAtTime(345321);
m2.bootAtTime(345335);

r.add(0, 1, -60.0);
r.add(1, 0, -60.0);
r.add(0, 2, -60.0);
r.add(2, 0, -60.0);
r.add(1, 2, -60.0);
r.add(2, 1, -80.0);

noise = open("meyer-short.txt", "r")
lines = noise.readlines()
for line in lines:
  str = line.strip()
  if (str != ""):
    val = int(str)
    m1.addNoiseTraceReading(val)
    m2.addNoiseTraceReading(val)

m1.createNoiseModel()
m2.createNoiseModel()

th.initialize();

while(1):
    th.checkThrottle();
    t.runNextEvent();
    sf.process();    
