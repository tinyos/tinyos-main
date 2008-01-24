#!/usr/bin/python

import sys
import re
import os
import random

print "Usage: python gentest.py [numitems] [newitems]"

items = sys.argv[1]
newitems = sys.argv[2]

print "Generating Configurations"

fin = open("TestDIPC-Master.nc", "r")
fout = open("TestDIPC.nc", "w")
lines = fin.readlines()
for line in lines:
    if(line.find("... DISSEMINATORS") != -1):
        for i in range(1, int(items)+1):
            fout.write("  components new DisseminatorC(uint16_t, ")
            fout.write(str(i))
            fout.write(") as Dissem" + str(i) + ";\n")
            fout.write("  TestDIPP.DisseminationUpdate" + str(i))
            fout.write(" -> Dissem" + str(i) + ";\n")
            fout.write("  TestDIPP.DisseminationValue" + str(i))
            fout.write(" -> Dissem" + str(i) + ";\n\n")
    else:
        fout.write(line)

fin.close()
fout.close()

print "Generating Modules"

fin = open("TestDIPP-Master.nc", "r")
fout = open("TestDIPP.nc", "w")
lines = fin.readlines()
for line in lines:
    if(line.find("... INTERFACES") != -1):
        for i in range(1, int(items)+1):
            fout.write("  uses interface DisseminationUpdate<uint16_t> as DisseminationUpdate")
            fout.write(str(i) + ";\n")
            fout.write("  uses interface DisseminationValue<uint16_t> as DisseminationValue")
            fout.write(str(i) + ";\n\n")
    elif(line.find("... NEWCOUNT") != -1):
        fout.write("  uint8_t newcount = " + str(newitems) + ";\n")
    elif(line.find("... CHANGES") != -1):
        for i in random.sample(range(1, int(items)+1), int(newitems)):
            fout.write("      call DisseminationUpdate" + str(i) + ".change(&data);\n")
    elif(line.find("... EVENTS") != -1):
        for i in range(1, int(items)+1):
            fout.write("  event void DisseminationValue" + str(i))
            fout.write(".changed() {\n")
            fout.write("    uint16_t val = *(uint16_t*) call DisseminationValue" + str(i) + ".get();\n")
            fout.write("    if(val != 0xBEEF) { return; }\n")
            fout.write("    bookkeep();\n")
            fout.write("  }\n\n")
    else:
        fout.write(line)

