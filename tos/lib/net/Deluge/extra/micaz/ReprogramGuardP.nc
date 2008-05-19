module ReprogramGuardP
{
  provides interface ReprogramGuard;
  uses interface Read<uint16_t> as Voltage;
}

implementation
{
  enum {
    VTHRESH = 0x1CF, // 2.7V
  };

  command error_t ReprogramGuard.okToProgram()
  {
    return call Voltage.read();
  }

  event void Voltage.readDone(error_t result, uint16_t val)
  {
    signal ReprogramGuard.okToProgramDone(result == SUCCESS && val < VTHRESH);
  }
  
}
