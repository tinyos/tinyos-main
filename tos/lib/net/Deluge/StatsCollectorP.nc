/* Copyright (c) 2007 Johns Hopkins University.
*  All rights reserved.
*
*  Permission to use, copy, modify, and distribute this software and its
*  documentation for any purpose, without fee, and without written
*  agreement is hereby granted, provided that the above copyright
*  notice, the (updated) modification history and the author appear in
*  all copies of this source code.
*
*  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS `AS IS'
*  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
*  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
*  ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS
*  BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
*  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, LOSS OF USE, DATA,
*  OR PROFITS) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
*  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
*  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
*  THE POSSIBILITY OF SUCH DAMAGE.
*/

/**
 * @author Chieh-Jan Mike Liang <cliang4@cs.jhu.edu>
 * @author Razvan Musaloiu-E. <razvanm@cs.jhu.edu>
 */

module StatsCollectorP
{
  provides {
    interface StatsCollector;
  }
  uses {
    interface LocalTime<TMilli> as LocalTime;
    interface Globals;
    interface Timer<TMilli> as Timer;
    interface AMSend;
  }
}

implementation
{
  enum {
    TIMER = 0,
    FORCED_START = 1,
    FORCED_END = 2
  };
  
  enum {
    BROADCAST_REQ = 0,
    START_RECV_DATA = 1,
    END_RECV_DATA = 2
  };
  
  typedef nx_struct StatsReport {
    nx_uint8_t text[5];
    nx_uint32_t NumPubPktTrans;
    nx_uint32_t NumRecvPageTrans;
    nx_uint32_t AvgPubPktTransTime;
    nx_uint32_t AvgRecvPageTransTime;
    nx_uint32_t NumPubPktRetrans;
    nx_uint32_t NumRecvHSRetrans;
  } StatsReport;
  
  typedef nx_struct StatusReport {
    nx_uint8_t text[5];
    nx_uint8_t flag;
    nx_uint8_t channel;
  } StatusReport;
  
  typedef nx_struct VariableReport {
    nx_uint8_t text[5];
    nx_uint32_t value;
  } VariableReport;
  
  uint32_t startPubTime = 0;
  uint32_t startRecvTime = 0;
  uint32_t startCCTime = 0;   // Change channel
  message_t stats_msg;
  message_t status_msg;
  message_t variable_msg;
 
  void startTimer() {
    if(call Timer.isRunning() == FALSE || call Timer.isOneShot() == TRUE) {
      call Timer.startPeriodic(5000);
    }
  }
  
  void stopTimer() {
    if(call Timer.isRunning() == TRUE) {
      call Timer.stop();
    }
  }
  
  void sendStatsReport() {
    StatsReport *report = (StatsReport *)call AMSend.getPayload(&stats_msg);

    report->text[0] = 's';
    report->text[1] = 't';
    report->text[2] = 'a';
    report->text[3] = 't';
    report->text[4] = 's';
    report->NumPubPktTrans = call Globals.getNumPubPktTrans();
    report->NumRecvPageTrans = call Globals.getNumRecvPageTrans();
    report->AvgPubPktTransTime = call Globals.getAvgPubPktTransTime();
    report->AvgRecvPageTransTime = call Globals.getAvgRecvPageTransTime();
    report->NumPubPktRetrans = call Globals.getNumPubPktRetrans();
    report->NumRecvHSRetrans = call Globals.getNumRecvHSRetrans();
    
    call AMSend.send(AM_BROADCAST_ADDR, &stats_msg, sizeof(StatsReport));
  }
  
  void sendStatusMsg(uint8_t flag, uint8_t channel) {
    StatusReport *report = (StatusReport *)call AMSend.getPayload(&status_msg);
    
    report->text[0] = 's';
    report->text[1] = 't';
    report->text[2] = 't';
    report->text[3] = 'u';
    report->text[4] = 's';
    report->flag = flag;
    report->channel = channel;
    
    call AMSend.send(AM_BROADCAST_ADDR, &status_msg, sizeof(StatusReport));
  }
  
  command void StatsCollector.sendVariableReport(uint32_t value) {
    VariableReport *report = (VariableReport *)call AMSend.getPayload(&variable_msg);
    
    report->text[0] = 'r';
    report->text[1] = 'e';
    report->text[2] = 'p';
    report->text[3] = 'r';
    report->text[4] = 't';
    report->value = value;
    
    call AMSend.send(AM_BROADCAST_ADDR, &variable_msg, sizeof(VariableReport));
  }
  
  command void StatsCollector.msg_bcastReq() {
    sendStatusMsg(BROADCAST_REQ, CC2420_DEF_CHANNEL);
  }
  
  event void Timer.fired() {
    sendStatsReport();
  }
  
  event void AMSend.sendDone(message_t* pstats_msg, error_t error) { }
  
  command void StatsCollector.startStatsCollector()
  {
    startTimer();
  }
  
  command void StatsCollector.stopStatsCollector()
  {
    stopTimer();
    call Timer.startOneShot(500);
    //sendStatsReport();   // Just in case
  }
  
  command void StatsCollector.startPubPktTransTime()
  {
    startPubTime = call LocalTime.get();
  }
  command void StatsCollector.endPubPktTransTime()
  {
    uint32_t diff = (call LocalTime.get()) - startPubTime;
    uint32_t temp = (call Globals.getAvgPubPktTransTime()) * (call Globals.getNumPubPktTrans());
    call Globals.incNumPubPktTrans();
    call Globals.setAvgPubPktTransTime((temp + diff) / (call Globals.getNumPubPktTrans()));
  }
  command void StatsCollector.startRecvPageTransTime(uint8_t channel)
  {
    startRecvTime = call LocalTime.get();
    sendStatusMsg(START_RECV_DATA, channel);
  }
  command void StatsCollector.endRecvPageTransTime(uint8_t senderAddr)
  {
    uint32_t curTime = call LocalTime.get();
    uint32_t temp = (call Globals.getAvgRecvPageTransTime()) * (call Globals.getNumRecvPageTrans());
    call Globals.incNumRecvPageTrans();
    call Globals.setAvgRecvPageTransTime((temp + (curTime - startRecvTime)) / (call Globals.getNumRecvPageTrans()));
    sendStatusMsg(END_RECV_DATA, senderAddr);
  }
  
  command void StatsCollector.incPub_numPktRetrans()
  {
    call Globals.incNumPubPktRetrans();
  }
  
  command void StatsCollector.startCCTime() {
    startCCTime = call LocalTime.get();
  }
  
  command void StatsCollector.endCCTime() {
    uint32_t diff = (call LocalTime.get()) - startCCTime;
    call StatsCollector.sendVariableReport(diff);
  }
  
  command void StatsCollector.incNumRecvHSRetrans() {
    call Globals.incNumRecvHSRetrans();
  }
}
