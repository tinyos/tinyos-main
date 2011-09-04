/**
  *
  * @author Zsolt Szabó <szabomeister@gmail.com>
  */

generic module InternalTempControlP() {
  provides interface Read<uint16_t>[uint8_t consumer];
  uses interface Read<uint16_t> as ActualRead;
  uses interface Resource as TempResource;
}
implementation {
  uint8_t id;

  task void TempRelease() {
    call TempResource.release();
  }

  event void TempResource.granted() {
    call Read.read[id]();
  }

  command error_t Read.read[uint8_t consumer]() {
    id = consumer;
    return call ActualRead.read();
  }

  event void ActualRead.readDone(error_t result, uint16_t val) {
    if (call TempResource.isOwner()) {
      signal Read.readDone[id](result, val);
      post TempRelease();
    }
  }

  default event void Read.readDone[uint8_t i](error_t result, uint16_t val) { };  
}
