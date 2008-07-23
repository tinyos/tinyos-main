TestFtsp

-------------------------------------------------------------------------------
Author/Contact:
---------------
 Brano Kusy: branislav.kusy@gmail.com
 Janos Sallai: janos.sallai@vanderbilt.edu
 Miklos Maroti: mmaroti@gmail.com

-------------------------------------------------------------------------------
DESCRIPTION:
------------
 The TestFtsp application tests the Flooding Time Synchronization Protocol
 (FTSP) implementation. A network of motes programmed with TestFtsp run the
 FTSP protocol to time synchronize, and sends to the base station the global
 reception timestamps of messages broadcast by a dedicated beacon mote
 programmed with RadioCountToLeds. Ideally, the global reception timestamps of
 the same RadioCountToLeds message should agree for all TestFtsp motes (with a
 small synchronization error).

-------------------------------------------------------------------------------
SUPPORTED PLATFORMS:
--------------------------------------------
 The supported platforms are micaz, telosb and iris.

-------------------------------------------------------------------------------
STEP BY STEP GUIDE TO RUN OUR TEST SCENARIO:
--------------------------------------------
 - program one mote with apps/RadioCountToLeds
 - program multiple motes with TestFtsp
 - program a mote with apps/BaseStation, leave it on the programming board
 - turn on all the motes
 - start the FtspDataLogger java application (type "java FtspDataLogger")

-------------------------------------------------------------------------------
REPORTED DATA:
--------------
 The most important reported data is the global time of arrival of the beacons.
 The beacon msg arrives to all clients at the same time instant, thus reported
 global times should be the same for all clients for the same sequence number.

 Each message contains:
 - the time of message reception by the java app [JAVA_TIME]
 - the node ID of the mote that is sending this report [NODE_ID]
 - the  sequence number of the RadioCountToLeds message that is increased
   for each new polling msg [SEQ_NUM]
 - the global time when the polling message arrived [GLOB_TIME]
 - a result_t value indicating if the timestamp is valid [IS_TIME_VALID]
   (a result_t of 0 denotes a valid timestamp)

If the application is running correctly, then the output should show
reports from the different FTSP nodes with valid timestamps and similar
global time values. For example, this is a trace with two FTSP nodes,
with IDs 1 and 5:

1214516486569 1 10916 433709 0
1214516486569 5 10916 433709 0
1214516486809 5 10917 433964 0
1214516486809 1 10917 433963 0
1214516487045 5 10918 434210 0
1214516487053 1 10918 434210 0
1214516487285 1 10919 434454 0
1214516487293 5 10919 434455 0

One way to test if FTSP is operating correctly is to turn off one of
the FTSP nodes. For a short time, that node's global times will differ
significantly and its valid flag will not be 0. For example, this
is what it looks like when node 1 in the earlier trace is reset:

1214516490953 5 10934 438208 0
1214516491201 5 10935 438460 0
1214516491441 5 10936 438712 0
1214516491685 5 10937 438964 0
1214516492169 5 10939 439455 0
1214516492417 1 10940 243 1
1214516492421 5 10940 439706 0
1214516492665 5 10941 439960 0
1214516492669 1 10941 497 1
1214516492905 5 10942 440213 0
...
1214516497541 1 10961 5495 1
1214516497549 5 10961 444958 0
1214516497793 1 10962 5747 1
1214516498025 1 10963 445456 0
1214516498033 5 10963 445455 0
1214516498277 5 10964 445705 0
1214516498285 1 10964 445707 0
1214516498521 1 10965 445964 0

This output is also saved in a file named 'current_timestamp.report'.
'.report' files can be used with the FtspDataAnalyzer.m Matlab
application. Mean absolute timesync error, global time, and % of
synced motes will be plotted.
