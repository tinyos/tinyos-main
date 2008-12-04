FtspDataAnalyzer.m

-------------------------------------------------------------------------------
Author/Contact:
---------------
 Brano Kusy: branislav.kusy@gmail.com

-------------------------------------------------------------------------------
DESCRIPTION:
------------

FtspDataAnalyzer.m works with data logs collected by FtspDataLogger.java and
calculates the maximum and average timesync error over time.

-------------------------------------------------------------------------------
STEP BY STEP GUIDE TO RUN OUR TEST SCENARIO:
--------------------------------------------
1. program and start motes as described in ./README.txt
2. start SerialForwarder and FtspDataLogger.java as described in ./README.txt
3. 'current_time.report' file (where current_time is a number) is created in ./
   this file is updated with data in the real time
4. let the experiment run for some time
5. start matlab and enter (assuming your current_time was 1206126224593)
    FTSPDataAnalyzer('1206126224593.report')
    this will plot the mean absolute timesync error, global time, and number of
    synced motes; this can be done while experiment is running
6. Matlab also creates data.out file which contains data in the following format
    #seqNum mean_abs_error global_time num_synced_motes
    mean_abs_error is calculated as mean absolute deviation from the mean (mad)

Simulating multi-hop:
1. define TIMESYNC_DEBUG in the Makefile
2. recompile and upload TestFTSP app to n motes with special NODE_IDs:
     using 'make micaz reinstall.0xAB', nodes 0xAB and 0xCD can communicate
     iff 2D grid coordinates (A,B) and (C,D) are neighbors in a 2D grid
 
-------------------------------------------------------------------------------
EVALUATION:
--------------------------------------------
 - deployment setup: 11 nodes in a 5x3 grid using simulated multi-hop (4 points
   were vacant as we only used 11 nodes). the max number of hops was 5.
 - parameters: sync period 10sec, polling period 3 sec
 - experiment length: 100 minutes
 - results (1 jiffy is ~30.5 us)
    1.53 jiffy avg error (~50us)
    3.5 jiffy max error (~100us)