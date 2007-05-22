generic module PhotoTempControlP()
{
  provides {
    interface SplitControl;
    interface Read<uint16_t>[uint8_t client];
  }
  uses {
    interface Resource as PhotoTempResource;
    interface Timer<TMilli>;
    interface GeneralIO as Power;
    interface Read<uint16_t> as ActualRead;
  }
}
implementation
{
  command error_t SplitControl.start() {
    call PhotoTempResource.request();
    return SUCCESS;
  }

  event void PhotoTempResource.granted() {
    call Power.makeOutput();
    call Power.set();
    call Timer.startOneShot(10);
  }

  event void Timer.fired() {
    if (call PhotoTempResource.isOwner())
      signal SplitControl.startDone(SUCCESS);
  }

  task void stopDone() {
    call PhotoTempResource.release();
    signal SplitControl.stopDone(SUCCESS);
  }

  command error_t SplitControl.stop() {
    call Power.clr();
    call Power.makeInput();
    post stopDone();
    return SUCCESS;
  }

  uint8_t id;

  command error_t Read.read[uint8_t client]() {
    id = client;
    return call ActualRead.read();
  }

  event void ActualRead.readDone(error_t result, uint16_t val) {
    if (call PhotoTempResource.isOwner())
      signal Read.readDone[id](result, val);
  }

  default event void Read.readDone[uint8_t x](error_t result, uint16_t val) { }
}
