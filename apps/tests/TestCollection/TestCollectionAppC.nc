/**
 * TestCollectionAppC exercises collection.
 *
 * 
 * @author Kyle Jamieson
 * @version $Id: TestCollectionAppC.nc,v 1.4 2006-12-12 18:22:49 vlahan Exp $
 * @see Net2-WG
 */

configuration TestCollectionAppC {}
implementation {
  components TestCollectionC, MainC, LedsC;

  TestCollectionC.Boot -> MainC;
  TestCollectionC.Leds -> LedsC;

  components new CollectionSenderC(0xDE);

  components new TimerMilliC();
  TestCollectionC.Timer -> TimerMilliC;
}
