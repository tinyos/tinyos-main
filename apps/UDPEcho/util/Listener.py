
import socket
import UdpReport
import re
import sys

port = 7000

if __name__ == '__main__':

    s = socket.socket(socket.AF_INET6, socket.SOCK_DGRAM)
    s.bind(('', port))

    while True:
        data, addr = s.recvfrom(1024)
        if (len(data) > 0):

            rpt = UdpReport.UdpReport(data=data, data_length=len(data))

            print addr
            print rpt

