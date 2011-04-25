import java.util.*;
import java.io.*;

public class Ping {
  int pinger;
  long ping_counter;
  short ping_tx_timestamp_is_valid;
  long ping_tx_timestamp;
  long ping_event_time;
  PingMsg pingMsg;
  Set pongs = new TreeSet();

  public Ping(PingMsg m) {
    setPingMsg(m);
  }

  public Ping(int pinger, long ping_counter) {
    this.pinger = pinger;
    this.ping_counter = ping_counter;
  }

  public int get_pinger() {
    if(pingMsg == null)
      return pinger;
    else
      return pingMsg.get_pinger();
  }

  public long get_ping_counter() {
    if(pingMsg == null)
      return ping_counter;
    else
      return pingMsg.get_ping_counter();
  }

  public long get_ping_event_time() {
    if(pingMsg == null)
      return ping_event_time;
    else
      return pingMsg.get_ping_event_time();
  }

  public void set_ping_event_time(long l) {
    ping_event_time = l;
  }

  public short get_ping_tx_timestamp_is_valid() {
    return ping_tx_timestamp_is_valid;
  }

  public void set_ping_tx_timestamp_is_valid(short s) {
    ping_tx_timestamp_is_valid = s;
  }

  public long get_ping_tx_timestamp() {
    return ping_tx_timestamp;
  }

  public void set_ping_tx_timestamp(long l) {
    ping_tx_timestamp = l;
  }

  public void setPingMsg(PingMsg m) {
    this.pingMsg = m;
  }

  public PingMsg getPingMsg() {
    return this.pingMsg;
  }

  public void addPong(Pong p) {
    pongs.add(p);
  }

  public void printHeader(PrintStream out) {
      out.print("#pinger\t");
      out.print("counter\t");
      out.print("Te_tx\t");
      out.print("Ttx_vld\t");
      out.print("Ttx\t");

      out.print("ponger\t");
      out.print("Trx_vld\t");
      out.print("Te_vld\t");
      out.print("Trx\t");
      out.print("Te_rx\t");

      out.print("Trx-Ttx\t");
      out.print("Te_rx-Te_tx\n");
  }

  public void print(PrintStream out) {
    Iterator it = pongs.iterator();
    while(it.hasNext()) {
      printHeader(out);

      Pong pong = (Pong)it.next();

      out.print(get_pinger()+"\t");
      out.print(get_ping_counter()+"\t");
      out.print(get_ping_event_time()+"\t");
      out.print(get_ping_tx_timestamp_is_valid()+"\t");
      out.print(get_ping_tx_timestamp()+"\t");

      out.print(pong.getPongMsg().get_ponger()+"\t");
      out.print(pong.getPongMsg().get_ping_rx_timestamp_is_valid()+"\t");
      out.print(pong.getPongMsg().get_ping_event_time_is_valid()+"\t");
      out.print(pong.getPongMsg().get_ping_rx_timestamp()+"\t");
      out.print(pong.getPongMsg().get_ping_event_time()+"\t");


      long tTxOffset = pong.getPongMsg().get_ping_rx_timestamp()-get_ping_tx_timestamp();
      // for 16-bit timestamping
      //if(tTxOffset<0) tTxOffset+=Math.pow(2,16);
      // for 32-bit timestamping
      if(tTxOffset<0) tTxOffset+=Math.pow(2,32);

      out.print(tTxOffset+"\t");

      long tEvtOffset = pong.getPongMsg().get_ping_event_time()-get_ping_event_time();
      // for 16-bit timestamping
      //if(tEvtOffset<0) tEvtOffset+=Math.pow(2,16);
      // for 32-bit timestamping
      if(tEvtOffset<0) tEvtOffset+=Math.pow(2,32);

      out.print(tEvtOffset+"\n");
    }
    out.print("\n");
  }
}
