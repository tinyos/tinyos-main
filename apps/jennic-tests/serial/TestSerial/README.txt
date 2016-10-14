TestSerial

Description:

Tests the serial AM-based communication the node to the PC. Sends AM packets with a increasing counter.

The serial-am-listener.py can be used to print the packets. It can also be used to print the AM packets from TestPrintf.

Expected Result:

destination: 65535 source: 0 length: 2 group: 0 type: 137 data: [0, 3]

destination: 65535 source: 0 length: 2 group: 0 type: 137 data: [0, 4]

destination: 65535 source: 0 length: 2 group: 0 type: 137 data: [0, 5]

...
