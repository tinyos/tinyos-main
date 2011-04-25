TestPacketTimeSync

Description:

The TestPacketTimeSync application is used to test/benchmark the packet-level 
time synchronization capability (as described in TEP133) of the radio stack.

Usage:

The test setup consists of a pinger node (programmed with node id 1), one or 
more ponger nodes, and a base station. The test application operates as follows: 
The pinger node periodically sends out ping messages using the TimeSyncAMSend 
interface. All ping messages have event times attached: these are timestamps 
taken short before the message was sent. Also, a ping message contains the 
transmission timestamp of the preceding ping message. Ponger nodes respond to 
the ping messages by sending pong messages, which contain the received event 
time and the reception timestamp of the ping message. The java application 
TestPacketTimeSync is used to collects all this information on the PC.

1. Build the TestPacketTimeSync application (e.g. make telosb cc2420x)

2. Install pinger node with node id 1 (e.g. make telosb reinstall,1 bsl,10)

3. Install ponger node(s) (with node id other than 1)

4. Set up a node as base station (use ../BaseStation)

5. Start the java application (change the communications port to match
   local setup):

   java TestPacketTimeSync -comm serial@telosb:com15

   In order to store the data in a log file, redirect the output to a file: e.g.
   
   java TestPacketTimeSync -comm serial@telosb:com15 > tep133.log

   To load the data in excel, preprocess it first with grep:

   cat tep133.log | grep -v pinger | grep -v "^$" > tep133_log_for_excel.txt
   
The recorded data (after sorting) will look as follows:

#pinger	counter	Te_tx	Ttx_vld	Ttx	ponger	Trx_vld	Te_vld	Trx		Te_rx		Trx-Ttx		Te_rx-Te_tx
1       1       855200  1       860421  2       1       1       20632897        20627676        19772476        19772476
1       2       1117344 1       1119109 2       1       1       20891589        20889824        19772480        19772480
1       3       1379520 1       1384005 2       1       1       21156488        21152003        19772483        19772483
1       4       1641664 1       1649253 2       1       1       21421754        21414165        19772501        19772501
1       5       1903808 1       1913797 2       1       1       21686285        21676296        19772488        19772488
1       6       2165920 1       2174149 2       1       1       21946630        21938401        19772481        19772481
1       7       2428096 1       2437061 2       1       1       22209575        22200610        19772514        19772514
1       8       2690240 1       2696773 2       1       1       22469271        22462738        19772498        19772498
1       9       2952352 1       2958117 2       1       1       22730612        22724847        19772495        19772495
1       10      3214496 1       3218053 2       1       1       22990568        22987011        19772515        19772515
1       11      3476640 1       3480645 2       1       1       23253145        23249140        19772500        19772500
1       12      3738784 1       3741253 2       1       1       23513760        23511291        19772507        19772507
1       13      4000960 1       4011877 2       1       1       23784386        23773469        19772509        19772509
1       14      4263104 1       4271877 2       1       1       24044393        24035620        19772516        19772516
1       15      4525248 1       4530309 2       1       1       24302792        24297731        19772483        19772483   

Ideally, Trx-Ttx values (the clock offset between the transmitter and the 
receiver) should be constant for the same ponger node (with some clock drift). 
Also, the difference between the pinger's and a given ponger's event times 
(Te_rx-Te_tx) should be constant over (with some clock drift).
