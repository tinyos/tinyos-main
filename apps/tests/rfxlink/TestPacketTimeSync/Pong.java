public class Pong implements Comparable {
  PongMsg pongMsg;

  public Pong(PongMsg m) {
    setPongMsg(m);
  }

  public void setPongMsg(PongMsg m) {
    this.pongMsg = m;
  }

  public PongMsg getPongMsg() {
    return this.pongMsg;
  }

  public int compareTo(Object o) {
    if(o instanceof Pong) {
      Pong p = (Pong)o;
      return new Integer(this.getPongMsg().get_ponger()).compareTo(new Integer(p.getPongMsg().get_ponger()));
    } else {
      return 0;
    }
  }
}
