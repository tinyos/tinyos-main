/**
 * Test reading and writing to a log with lots of syncs. See README.txt for
 * more details.
 *
 * @author Mayur Maheshwari (mayur.maheshwari@gmail.com)
 * @author David Gay
 */

module SyncLogC
{
  uses {
    interface Leds;
    interface Boot;
    interface SplitControl as AMControl;
    interface LogWrite;
    interface LogRead;
    interface Timer<TMilli> as Timer0;
    interface Timer<TMilli> as Timer1;
    interface AMSend;
  }
}
implementation {

  uint16_t data = 0;
  uint16_t readings = 0;
  message_t pkt;
  bool busy = FALSE;
  bool logBusy = FALSE;

  task void sendTask();

  storage_cookie_t readCookie;
  storage_cookie_t writeCookie;

#define SAMPLING_FREQUENCY 2333
#define TIMER_PERIOD_MILLI 5120

  event void Boot.booted() {
    call AMControl.start();
  }

  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS)
      call LogWrite.erase();
    else
      call AMControl.start();
  }

  event void LogWrite.eraseDone(error_t result) {
    call Timer1.startPeriodic(SAMPLING_FREQUENCY);
    call Timer0.startPeriodic(TIMER_PERIOD_MILLI);
  }
  
  event void Timer1.fired()
  {
    readings++;
    if (!logBusy)
      {
	logBusy = TRUE;
	call LogWrite.append(&readings, sizeof(readings));
      }
  }

  event void LogWrite.appendDone(void *buf, storage_len_t len, bool recordsLost, error_t result) {
    if (result == SUCCESS)
      call LogWrite.sync();
  }

  event void LogWrite.syncDone(error_t result) {
    logBusy = FALSE;
    call Leds.led2Toggle();
  }

  event void Timer0.fired() {
    call Timer1.stop();
    if (!logBusy)
      {
	call Leds.led0Toggle();
	logBusy = TRUE;
	call LogRead.read(&data, sizeof data);
      }
  }

  event void LogRead.readDone(void* buf, storage_len_t len, error_t error) {
    if (error == SUCCESS)
      if (len == sizeof data)
	post sendTask();
      else
	{
	  logBusy = FALSE;
	  call Timer1.startPeriodic(SAMPLING_FREQUENCY);
	}
  }

  typedef nx_struct {
    nx_uint16_t nodeid;
    nx_uint16_t payloadData;
  } SenseStoreRadioMsg;

  task void sendTask() {
    if (!busy)
      {
	SenseStoreRadioMsg* ssrpkt =
	  (SenseStoreRadioMsg*)(call AMSend.getPayload(&pkt, sizeof(SenseStoreRadioMsg)));
	ssrpkt->nodeid = TOS_NODE_ID;
	ssrpkt->payloadData = data;
	if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(SenseStoreRadioMsg)) == SUCCESS)
	  busy = TRUE;
      }
  }

  event void AMSend.sendDone(message_t* msg, error_t err) {
    if (&pkt == msg)
      {
	busy = FALSE;
	call LogRead.read(&data, sizeof data);
      }
  }

  event void LogRead.seekDone(error_t error) { }
  event void AMControl.stopDone(error_t err) { }
}
