from TOSSIM import *
import sys
import time

t = Tossim([])
r = t.radio();

t.addChannel("TestComm", sys.stdout)
t.addChannel("SNRLoss", sys.stdout)
#t.addChannel("Acks", sys.stdout)
#t.addChannel("Gain", sys.stdout)
#t.addChannel("CpmModelC", sys.stdout)
#t.addChannel("AM", sys.stdout)


start = time.time();
m1 = t.getNode(1)
m2 = t.getNode(2)
m3 = t.getNode(3)

# Set up a hidden terminal problem, where 1 and 3
# are closely synchronized, but cannot hear each other.
m1.bootAtTime(345321);
m2.bootAtTime(82123411);
m3.bootAtTime(345325);
r.add(1, 2, -50.0);
r.add(2, 1, -50.0);
r.add(2, 3, -60.0);
r.add(3, 2, -60.0);

noise = open("meyer-short.txt", "r")
lines = noise.readlines()
for line in lines:
  str = line.strip()
  if (str != ""):
    val = int(str)
    m1.addNoiseTraceReading(val)
    m2.addNoiseTraceReading(val)
    m3.addNoiseTraceReading(val)

m1.createNoiseModel()
m2.createNoiseModel()
m3.createNoiseModel()

for i in range(0, 200000):
    t.runNextEvent();

    
