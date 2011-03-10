import sys
import os
import time
import struct

#tos stuff
import TestADE7753Msg
from tinyos.message import *
from tinyos.message.Message import *
from tinyos.message.SerialPacket import *
from tinyos.packet.Serial import Serial

class DataLogger:
    def __init__(self, motestring):
        self.mif = MoteIF.MoteIF()
        self.tos_source = self.mif.addSource(motestring)
        self.mif.addListener(self, TestADE7753Msg.TestADE7753Msg)

    def receive(self, src, msg):
        if msg.get_amType() == TestADE7753Msg.AM_TYPE:
            m = TestADE7753Msg.TestADE7753Msg(msg.dataGet())
            print time.time(), m

    def main_loop(self):
        while 1:
            time.sleep(1)

def main():

    if '-h' in sys.argv:
        print "Usage:", sys.argv[0], "sf@localhost:9002"
        sys.exit()

    dl = DataLogger(sys.argv[1])
    dl.main_loop()  # don't expect this to return...


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        pass

