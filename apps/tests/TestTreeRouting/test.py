# This script is a simple TOSSIM test of tree building
# It builds a 15x15 grid of nodes and just lets the
# tree form. There's currently no routing going on.

import TOSSIM
import sys

t = TOSSIM.Tossim([])
m = t.mac();
r = t.radio();
t.init()

#t.addChannel("LedsC", sys.stdout);
t.addChannel("AM", sys.stdout);
t.addChannel("TreeRouting", sys.stdout);
t.addChannel("TreeRoutingCtl", sys.stdout);
t.addChannel("LI", sys.stdout);
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
    elif (s[0] == "noise"):
      r.setNoise(int(s[1]), float(s[2]), float(s[3]))

for i in range(0, 225):
  m = t.getNode(i);
  if (i == 173):
    m.bootAtTime(t.ticksPerSecond() * 100) 
  else:
    m.bootAtTime((t.ticksPerSecond() / 50) * i + 43);
 
while (t.time() / t.ticksPerSecond() < 1600):
  if (t.time() == t.ticksPerSecond() * 100):
    print "---------"
  t.runNextEvent()
  
