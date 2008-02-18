from TOSSIM import *
import sys
import time

t = Tossim([])
r = t.radio()
f = open("topo.txt", "r")
n = 0

lines = f.readlines()
for line in lines:
  s = line.split()
  if (len(s) > 0):
#    print " ", s[0], " ", s[1], " ", s[2]
    r.add(int(s[0]), int(s[1]), float(s[2]))


t.addChannel("messages", sys.stdout)
#t.addChannel("fwe", sys.stdout)
#t.addChannel("mhe", sys.stdout)
#t.addChannel("de", sys.stdout)
t.addChannel("dt", sys.stdout)

noise = open("meyer-light.txt", "r")
lines = noise.readlines()
for line in lines:
  str = line.strip()
  if (str != ""):
    val = int(str)
    for i in range(1, 4):
      t.getNode(i).addNoiseTraceReading(val)

for i in range(1, 4):
#  print "Creating noise model for ",i
  t.getNode(i).createNoiseModel()

t.getNode(1).bootAtTime(100001);
t.getNode(2).bootAtTime(200022);
t.getNode(3).bootAtTime(300033);

t.runNextEvent();
time = t.time()
while (time + 700000000000 > t.time()):
  print t.time()
  t.runNextEvent()

sys.stderr.write("Finished!\n")
