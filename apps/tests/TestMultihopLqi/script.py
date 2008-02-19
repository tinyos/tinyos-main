from TOSSIM import *
import sys
import time
import random

t = Tossim([])
r = t.radio()

#t.addChannel("HASH", sys.stdout)
#t.addChannel("Insert", sys.stdout)
#t.addChannel("RadioCountToLedsC", sys.stdout)
#t.addChannel("CpmModelC", sys.stdout)
#t.addChannel("Gain", sys.stdout)
#t.addChannel("AM", sys.stdout)
t.addChannel("App", sys.stdout)
t.addChannel("LQI", sys.stdout)
#t.addChannel("LQIRoute", sys.stdout)
t.addChannel("LQIDeliver", sys.stdout)
#t.addChannel("LQIRoute", sys.stdout)
#t.addChannel("PointerBug", sys.stdout)

start = time.time();
noise = open("meyer-short.txt", "r")
lines = noise.readlines()
for line in lines:
    str = line.strip()
    if (str != ""):
        val = int(str)
        for i in range(0, 7):
            t.getNode(i).addNoiseTraceReading(val)
#        print "adding ", int(str)
end = time.time();
duration = end - start;
print "time: ", duration;

f = open("topo.txt", "r")

lines = f.readlines()
for line in lines:
  s = line.split()
  if (len(s) > 0):
    if (s[0] == "gain" and int(s[1]) < 8 and int(s[2]) < 8):
      r.add(int(s[1]), int(s[2]), float(s[3]))
      

start = time.time();
for i in range(0, 7):
    t.getNode(i).createNoiseModel();
    t.getNode(i).bootAtTime(int(random.random() * 10000000 + 20000000));

duration = end - start;
print "time: ", duration;

#for i in range(0, 196607):
#    print m1.generateNoise(i)

while ((t.time() / t.ticksPerSecond()) < 3000):
    t.runNextEvent();
