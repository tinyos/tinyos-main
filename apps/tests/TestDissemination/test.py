# This script is a simple TOSSIM test of dissemination.
# It builds a 15x15 grid of nodes and has nodes start
# disseminating two values (based on the TinyOS app).
# It prints out when nodes receive new values, including
# the dissemination key and sequence number. You should
# be able to see how the implementation can resolve
# multiple concurrent changes within the network as
# well as more than one value being updated at a time.

import TOSSIM
import sys

t = TOSSIM.Tossim([])
m = t.mac();
r = t.radio();
t.init()

#t.addChannel("LedsC", sys.stdout);
#t.addChannel("AM", sys.stdout);
#t.addChannel("TestDisseminationC", sys.stdout);
t.addChannel("Dissemination", sys.stdout)
t.addChannel("TestDisseminationC", sys.stdout)
#t.addChannel("Gain", sys.stdout);
#t.addChannel("TossimPacketModelC", sys.stdout);

print (dir(TOSSIM.Tossim))

f = open("topo.txt", "r")
lines = f.readlines()
for line in lines:
  s = line.split()
  if (len(s) > 0):
    if (s[0] == "gain"):
      r.add(int(s[1]), int(s[2]), float(s[3]))

for i in range(0, 225):
  m = t.getNode(i);
  for j in range (0, 100):
    m.addNoiseTraceReading(-105)
  m.createNoiseModel()
  m.bootAtTime((t.ticksPerSecond() / 50) * i + 43);
 
while (t.time() / t.ticksPerSecond() < 600):
  t.runNextEvent()
