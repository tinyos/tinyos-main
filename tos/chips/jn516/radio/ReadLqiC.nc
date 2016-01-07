/*
 * Wiring to the blip/platform component which reads the LQI and RSSI values
 * from messages on JN516 platforms.
 *
 * @author Tim Bormann <code@tkn.tu-berlin.de>
 */

configuration ReadLqiC {
  provides interface ReadLqi;
} implementation {

  // jn516 platforms
  components Jn516ReadLqiC, Jn516PacketC;
  ReadLqi = Jn516ReadLqiC;
}

