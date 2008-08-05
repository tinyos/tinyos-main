from TOSSIM import *
from tinyos.tossim.TossimApp import *
from random import *
import sys

#n = NescApp("TestNetwork", "app.xml")
#t = Tossim(n.variables.variables())
t = Tossim([])
r = t.radio()

f = open("sparse-grid.txt", "r")
lines = f.readlines()
for line in lines:
  s = line.split()
  if (len(s) > 0):
    if s[0] == "gain":
      r.add(int(s[1]), int(s[2]), float(s[3]))

noise = open("meyer-short.txt", "r")
lines = noise.readlines()
for line in lines:
  str = line.strip()
  if (str != ""):
    val = int(str)
    for i in range(0, 10):
      m = t.getNode(i);
      m.addNoiseTraceReading(val)



for i in range(0, 10):
  m = t.getNode(i);
  m.createNoiseModel();
  time = randint(t.ticksPerSecond(), 10 * t.ticksPerSecond())
  m.bootAtTime(time)
  print "Booting ", i, " at time ", time

print "Starting simulation."

#t.addChannel("AM", sys.stdout)
#t.addChannel("TreeRouting", sys.stdout)
#t.addChannel("TestNetworkC", sys.stdout)
#t.addChannel("Route", sys.stdout)
#t.addChannel("PointerBug", sys.stdout)
#t.addChannel("QueueC", sys.stdout)
#t.addChannel("Gain", sys.stdout)
t.addChannel("Forwarder", sys.stdout)
t.addChannel("TestNetworkC", sys.stdout)
#t.addChannel("App", sys.stdout)
#t.addChannel("Traffic", sys.stdout)
#t.addChannel("Acks", sys.stdout)

while (t.time() < 1000 * t.ticksPerSecond()):
  t.runNextEvent()

print "Completed simulation."
