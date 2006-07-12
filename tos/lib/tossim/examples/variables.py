# This is an example script from the TOSSIM tutorials.
# It can be used with any TinyOS application.

from tinyos.tossim.TossimApp import *
from TOSSIM import *

n = NescApp()
t = Tossim(n.variables.variables())
m = t.getNode(0)

for i in range(0, 1):
  m = t.getNode(i);
  time = ((79 + t.ticksPerSecond() / 100) * i + 1)
  m.bootAtTime(time);
  print "Mote " + str(i) + " set to boot at " + str(time);

for i in range(0, 500):
  t.runNextEvent();

v = m.getVariable("SimMoteP.startTime")
v2 = m.getVariable("SimSchedulerBasicP.m_head");

print "start time: <", v.getData(), ">\nnext task: <", v2.getData(), ">"

for i in range(0, 500):
  t.runNextEvent();

print "start time: <", v.getData(), ">\nnext task: <", v2.getData(), ">"


