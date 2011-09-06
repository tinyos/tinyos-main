/** Copyright (c) 2010, University of Szeged
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions
* are met:
*
* - Redistributions of source code must retain the above copyright
* notice, this list of conditions and the following disclaimer.
* - Redistributions in binary form must reproduce the above
* copyright notice, this list of conditions and the following
* disclaimer in the documentation and/or other materials provided
* with the distribution.
* - Neither the name of University of Szeged nor the names of its
* contributors may be used to endorse or promote products derived
* from this software without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
* "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
* FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
* COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
* INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
* (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
* SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
* HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
* STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
* OF THE POSSIBILITY OF SUCH DAMAGE.
*
* Author: Krisztian Veress
*         veresskrisztian@gmail.com
*/

package benchmark.common;

import java.util.concurrent.locks.*;
import java.util.concurrent.TimeUnit;
import net.tinyos.message.*;

/**
 * The class that is able to communicate with the LinkBenchmark
 * TinyOS application.
 *
 * This class is responsible for sending and receiving control/data messages
 * to/from the motes via a BaseStation mote.
 *
 * It is designed to be minimal and full, so everything is functional yet user-
 * friendlyness must be implemented elsewhere.
 */
public class BenchmarkController implements MessageListener {
	
	private MoteIF  mif;

  // Needed for proper downloading
  final Lock                  lock        = new ReentrantLock();
  final Condition             answered    = lock.newCondition();
  private boolean             handshake;
  private static int          currentMote = 1;
  private static short        currentData = 0;

  // Public to be able to set it easily
  public static final short   MAXPROBES   = 6;
  public static final short   MAXTIMEOUT  = 2000;

  private BenchmarkResult     results;
  
  // These values are updated during the synchronization phase
  private int                 maxMoteId   = 2;
  private int                 edgecount   = 0;

  public class MessageSendException extends Exception {};
  public class CommunicationException extends Exception {
    public CommunicationException(String message) {
      super(message);
    }    
  };

  /**
   * Contruct a controller.
   * 
   * @param motecount How many motes are used?
   */
  public BenchmarkController()
	{
    mif = new MoteIF();
    mif.registerListener(new SyncMsgT(),this);
    mif.registerListener(new DataMsgT(),this);

    maxMoteId = 2;
    results = new BenchmarkResult();
	}

  /**
   * Set the maximal mote id in the network.
   * 
   * @param maxMoteId The new value
   */
  public void updateMoteCount(final int maxMoteId) {
    this.maxMoteId = maxMoteId;
    this.edgecount = 0;
  }

  /**
   * Get the results
   * @return an object containing the current results
   */
  public BenchmarkResult getResults() {
    return this.results;
  }

  /**
   * Send a RESET control message to the network.
   * It is a broadcast message, so every mote should receive it.
   *
   * @param use_bcast Whether send one broadcast message or iterate through the motes
   * @throws MessageSendException if an error occured (message is failed to send)
   */
  public boolean reset(final boolean use_bcast) throws MessageSendException
  {
    CtrlMsgT cmsg = new CtrlMsgT();
    cmsg.set_type(BenchmarkStatic.CTRL_RESET);
		try {
      if (use_bcast ){
        mif.send(MoteIF.TOS_BCAST_ADDR,cmsg);
      } else {
        currentMote = 1;
        while ( currentMote <= maxMoteId ) {
          mif.send(currentMote++,cmsg);
        }
      }
      Thread.sleep((int)(500));
		} catch(Exception e) {
      throw new MessageSendException();
    }
    return true;
	}
	
  /**
   * Send a RESET control message to only one mote.
   *
   * @param moteId The mote to be resetted
   * @param use_bcast Whether send one broadcast message or iterate through the motes
   * @throws MessageSendException if an error occured (message is failed to send)
   */
  public boolean resetMote(final int moteId) throws MessageSendException
  {
    CtrlMsgT cmsg = new CtrlMsgT();
    cmsg.set_type(BenchmarkStatic.CTRL_RESET);
    try {
        mif.send(moteId,cmsg);
        Thread.sleep((int)(500));
	} catch(Exception e) {
      throw new MessageSendException();
    }
    return true;
  }	
  
  /**
   * Send a SETUP control message to the network.
   * It is a broadcast message, so every mote should receive it.
   *
   * @param config The benchmark configurationT
   * @throws MessageSendException if an error occured (message is failed to send)
   */
  
  /**
   * Send a SETUP control message to the network.
   * It is a broadcast message, so every mote should receive it.
   * 
   * @param config The benchmark configurationT
   * @param use_bcast Whether use one broadcast message or iterate through the motes
   * @throws MessageSendException if an error occured (message is failed to send)
   */
  public void setup(final SetupT config, final boolean use_bcast) throws MessageSendException {
    this.results.setConfig(config);

    // Create an appropriate setup message
    SetupMsgT smsg = new SetupMsgT();

    smsg.set_config_problem_idx(config.get_problem_idx());
    smsg.set_config_pre_run_msec(config.get_pre_run_msec());
    smsg.set_config_runtime_msec(config.get_runtime_msec());
    smsg.set_config_post_run_msec(config.get_post_run_msec());
    smsg.set_config_flags(config.get_flags());

    smsg.set_config_timers_isoneshot(config.get_timers_isoneshot());
    smsg.set_config_timers_delay(config.get_timers_delay());
    smsg.set_config_timers_period_msec(config.get_timers_period_msec());

    smsg.set_config_mac_setup(config.get_mac_setup());
    smsg.set_type(BenchmarkStatic.SETUP_BASE);

   	try {
      if (use_bcast ){
        mif.send(MoteIF.TOS_BCAST_ADDR,smsg);
      } else {
        currentMote = 1;
        while ( currentMote <= maxMoteId )
          mif.send(currentMote++,smsg);
      }
      Thread.sleep((int)(500));
		} catch(Exception e) {
		  throw new MessageSendException();
    }
  }

  /**
   * Synchronize all motes in the network having mote id from 1 to
   * the 'motecount' value specified either in the constructor or set by the
   * setMoteCount setter method.
   *
   * By synchronizing, we can detect failed motes (not answering), improperly
   * configured motes (wrong answers), and get the real motecount based on the
   * active benchmark configured in the network.
   *
   * @throws CommunicationException if synchronization error happens
   */
  public void syncAll() throws CommunicationException {
    currentMote = 1;
    while ( currentMote <= maxMoteId ) {
      if ( !sync(currentMote) ) {
        throw new CommunicationException(
                "Synchronization Error with Mote ID: " + currentMote + "." +
                " -- Possible reasons: Bad benchmark ID, Mote not operational, not configured (Only LED 1 On), or badly configured (No LEDS On)"
                );
      }
      else
        ++currentMote;
    }
  }

  /**
   * Send a SETUP_SYN control message to the specified mote.
   * It is a direct addressing message, so only the specified mote should
   * receive, and answer it.
   *
   * The handshake is probed MAXPROBES times using MAXTIMEOUT waiting for each.
   *
   * @param moteId The mote's id whom to send the synchronization request.
   * @return TRUE if the mote answered to our sync request, FALSE otherwise
   */
  public boolean sync(final int moteId) {

    // Create a SYNC-request control message
    CtrlMsgT cmsg = new CtrlMsgT();
    cmsg.set_type(BenchmarkStatic.CTRL_SETUP_SYN);

    lock.lock();
    handshake = false;
    for( short probe = 0; !handshake && probe < MAXPROBES; ++probe ) {
      try {
 	  	  mif.send(moteId,cmsg);
 	  	  answered.await(MAXTIMEOUT,TimeUnit.MILLISECONDS);
 	    } catch(Exception e) {
        break;
      }
    }
    lock.unlock();
    return handshake;
  }

  /**
   * Send a START control message to the network.
   * It is a broadcast message, so every mote should receive it.
   *
   * @param use_bcast Whether use one broadcast message or iterate through the motes
   * @throws MessageSendException if an error occured (message is failed to send)
   */
  public void run(final boolean use_bcast) throws MessageSendException {

    // Create a START control message
    CtrlMsgT cmsg = new CtrlMsgT();
    cmsg.set_type(BenchmarkStatic.CTRL_START);

    try {
      if (use_bcast ){
        mif.send(MoteIF.TOS_BCAST_ADDR,cmsg);
      } else {
        currentMote = 1;
        while ( currentMote <= maxMoteId )
          mif.send(currentMote++,cmsg);
      }
      // Wait for test completion + 100 msecs
      Thread.sleep(
              (int)(BenchmarkCommons.getRuntime(this.results.getConfig()) + 100)
              );
		} catch(Exception e) {
      throw new MessageSendException();
    }
  }

  /**
   * Download the statistics from the motes.
   *
   * @throws CommunicationException
   */
  public void download_stat() throws CommunicationException
	{
    for ( currentMote = 1; currentMote <= maxMoteId ; ++currentMote ) {
      for ( currentData = 0; currentData < edgecount; ++currentData ) {
        if ( !requestData(currentMote,currentData,BenchmarkStatic.CTRL_STAT_REQ) ) {
          throw new CommunicationException(
                "Download Error with Mote ID: " + currentMote +
                ", stat index: " + currentData + "."
                );

        }
      }
    }
	}

  /**
   * Download the profile information from the motes.
   *
   * @throws CommunicationException
   */
  public void download_profile() throws CommunicationException
	{
    for (currentMote = 1; currentMote <= maxMoteId; ++currentMote) {
      if (!requestData(currentMote, currentData, BenchmarkStatic.CTRL_PROFILE_REQ)) {
        throw new CommunicationException(
                "Download Debug Error with Mote ID: " + currentMote + ".");
      }
    }

	}

  /**
   * Send a data requesting control message to a specific mote with a specified
   * data index. Data can be either the statistics on a specific edge, or the debug
   * information on the mote.
   *
   * @param moteId The mote we are targeting
   * @param dataidx The index of the data (only used when statistics are downloaded)
   * @param type BenchmarkStatic.CTRL_STAT_REQ or BenchmarkStatic.CTRL_DBG_REQ
   * @return TRUE if data has been received, FALSE otherwise
   */
  private boolean requestData(final int moteId, final short dataidx, final short type) {

    // Create a download request control message
    CtrlMsgT cmsg = new CtrlMsgT();
    cmsg.set_type(type);
    cmsg.set_data_req_idx(dataidx);
    
    lock.lock();
    handshake = false;
    for( short probe = 0; !handshake && probe < MAXPROBES; ++probe ) {
      try {
 	  	  mif.send(moteId,cmsg);
 	  	  answered.await(MAXTIMEOUT,TimeUnit.MILLISECONDS);
 	    } catch(Exception e) {
        break;
      }
    }
    lock.unlock();
    return handshake;    
  }

  /**
   * The event which is triggered on message reception. We can receive messages
   * in two situations:
   *  - either in the synchronization phase (sync acknowledgements)
   *  - or in the downloading phases (stats or debug info)
   *
   * @param dest_addr The source mote id of the message
   * @param msg The message received
   */
  public void messageReceived(int dest_addr,Message msg)
	{
	  lock.lock();
    // Received a SyncMsgT
    if ( msg instanceof SyncMsgT ) {
      SyncMsgT smsg = (SyncMsgT)msg;
      if ( smsg.get_type() == BenchmarkStatic.SYNC_SETUP_ACK ) {
        handshake = true;
        edgecount = smsg.get_edgecnt();
        if ( smsg.get_maxmoteid() > maxMoteId )
          maxMoteId = smsg.get_maxmoteid();

        // update the results structure
        this.results.cleanResize(maxMoteId, edgecount);
        answered.signal();

      }
    // Received a DataMsgT
    } else if ( msg instanceof DataMsgT ) {
    
      DataMsgT rmsg = (DataMsgT) msg;
      switch (rmsg.get_type()) {
        case BenchmarkStatic.DATA_STAT_OK:
          // Process the message only if this message is the answer for our query
          // This prevents us from makeing corrupt statistics.
          if (currentData == rmsg.get_data_idx()) {
            this.results.appendStatFromMessage(currentData, rmsg);
          }
          break;
        case BenchmarkStatic.DATA_PROFILE_OK:
          this.results.appendProfileFromMessage(currentMote, rmsg);
          break;
      }
      handshake = true;
      answered.signal();
    }
    lock.unlock();
	}
}
