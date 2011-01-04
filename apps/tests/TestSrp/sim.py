import TOSSIM
import sys

t = TOSSIM.Tossim([])
m = t.mac()
r = t.radio()
t.init()

t.addChannel("TestSrpP", sys.stdout)
#t.addChannel("SourceRouteEngineP", sys.stdout)
#t.addChannel("SRPDebug", sys.stdout)
#t.addChannel("SRPInfo", sys.stdout)
t.addChannel("SRPError", sys.stdout)

f = open("topo.txt", "r")
lines = f.readlines()

edges = {}

for [src, dest, gain] in [line.split()[1:] for line in lines if line.startswith("gain")]:
    src = int(src)
    dest = int(dest)
    r.add(src, dest, float(gain))
    edges[src] = edges.get(src, [])+[dest]

for nodeId in edges:
    n = t.getNode(nodeId)
    for i in range(100):
        n.addNoiseTraceReading(-105)
    n.createNoiseModel()
    n.bootAtTime(t.ticksPerSecond()/4 * nodeId )

while t.time() / t.ticksPerSecond() < 300:
    t.runNextEvent()
