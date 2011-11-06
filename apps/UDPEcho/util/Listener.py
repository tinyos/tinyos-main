
import socket
import UdpReport
import re
import sys
import time
import threading

port = 7000
stats = {}

class PrintStats(threading.Thread):
    def __init__(self):
        threading.Thread.__init__(self)
        self.daemon = True

    def run(self):
        while True:
            self.print_stats()
            time.sleep(3)

    def print_stats(self):
        global stats
        print "-" * 40
        for k, v in stats.iteritems():
            print "%s: %i/%i (%0.2f ago) (%0.2f%%)" % (k,
                                                       v[0],
                                                       v[3] - v[2] + 1,
                                                       time.time() - v[1],
                                                       100 * float(v[0]) /
                                                       (v[3] - v[2] + 1))
        print "%i total" % len(stats)
        print "-" * 40

if __name__ == '__main__':
    s = socket.socket(socket.AF_INET6, socket.SOCK_DGRAM)
    s.bind(('', port))
    ps = PrintStats()
    ps.start()

    while True:
        data, addr = s.recvfrom(1024)
        if (len(data) > 0):
            rpt = UdpReport.UdpReport(data=data, data_length=len(data))

            print addr[0]

            if not addr[0] in stats:
                stats[addr[0]] = (0, time.time(), rpt.get_seqno(), rpt.get_seqno())

            cur = stats[addr[0]]
            stats[addr[0]] = (cur[0] + 1, time.time(), cur[2], rpt.get_seqno())
